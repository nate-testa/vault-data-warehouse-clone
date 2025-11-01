"""
Insights UI Data Schemas Module

This module contains data structures for handling query results, caching,
and UI-specific data transformations for the Insights interface.
"""

from typing import List, Dict, Any, Optional, Union
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
import json


class DataType(str, Enum):
    """Detected data types for columns"""
    STRING = "string"
    INTEGER = "integer"
    FLOAT = "float"
    DATE = "date"
    DATETIME = "datetime"
    BOOLEAN = "boolean"
    NULL = "null"


class ChartType(str, Enum):
    """Recommended chart types based on data characteristics"""
    LINE = "line"
    BAR = "bar"
    COLUMN = "column"
    PIE = "pie"
    SCATTER = "scatter"
    TABLE = "table"


@dataclass
class ColumnInfo:
    """Information about a data column"""
    name: str
    data_type: DataType
    sample_values: List[Any] = field(default_factory=list)
    null_count: int = 0
    unique_count: Optional[int] = None
    min_value: Optional[Any] = None
    max_value: Optional[Any] = None
    is_numeric: bool = False
    is_temporal: bool = False
    is_categorical: bool = False
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        return {
            'name': self.name,
            'data_type': self.data_type.value,
            'sample_values': self.sample_values[:5],  # Limit sample size
            'null_count': self.null_count,
            'unique_count': self.unique_count,
            'min_value': str(self.min_value) if self.min_value is not None else None,
            'max_value': str(self.max_value) if self.max_value is not None else None,
            'is_numeric': self.is_numeric,
            'is_temporal': self.is_temporal,
            'is_categorical': self.is_categorical
        }


@dataclass
class ResultData:
    """Complete SQL result data with metadata and analysis"""
    # Core data
    columns: List[str]
    data: List[List[Any]]
    
    # Metadata
    execution_id: str
    conversation_id: Optional[str] = None
    row_count: int = 0
    column_count: int = 0
    execution_time_ms: Optional[int] = None
    query_hash: Optional[str] = None
    
    # Analysis
    column_info: List[ColumnInfo] = field(default_factory=list)
    recommended_chart_types: List[ChartType] = field(default_factory=list)
    data_summary: Dict[str, Any] = field(default_factory=dict)
    
    # Caching info
    cached_at: Optional[datetime] = None
    cache_key: Optional[str] = None
    
    def __post_init__(self):
        """Analyze data after initialization"""
        if not self.row_count:
            self.row_count = len(self.data)
        if not self.column_count:
            self.column_count = len(self.columns)
        
        # Generate column info if not provided
        if not self.column_info and self.data and self.columns:
            self.column_info = self._analyze_columns()
        
        # Generate chart recommendations
        if not self.recommended_chart_types and self.column_info:
            self.recommended_chart_types = self._recommend_chart_types()
    
    def _analyze_columns(self) -> List[ColumnInfo]:
        """Analyze column data types and characteristics"""
        column_info = []
        
        for i, column_name in enumerate(self.columns):
            # Extract column data
            column_data = [row[i] if i < len(row) else None for row in self.data]
            column_data = [val for val in column_data if val is not None]
            
            # Analyze data type and characteristics
            info = ColumnInfo(
                name=column_name,
                data_type=self._detect_data_type(column_data),
                sample_values=column_data[:10],  # First 10 non-null values
                null_count=len([val for val in [row[i] if i < len(row) else None for row in self.data] if val is None]),
                unique_count=len(set(column_data)) if column_data else 0
            )
            
            if column_data:
                try:
                    if info.data_type in [DataType.INTEGER, DataType.FLOAT]:
                        numeric_data = [float(val) for val in column_data if val is not None]
                        info.min_value = min(numeric_data) if numeric_data else None
                        info.max_value = max(numeric_data) if numeric_data else None
                        info.is_numeric = True
                    elif info.data_type in [DataType.DATE, DataType.DATETIME]:
                        info.is_temporal = True
                    elif info.data_type == DataType.STRING:
                        info.is_categorical = info.unique_count < self.row_count * 0.5  # Less than 50% unique
                except (ValueError, TypeError):
                    pass
            
            column_info.append(info)
        
        return column_info
    
    def _detect_data_type(self, values: List[Any]) -> DataType:
        """Detect the data type of a column based on sample values"""
        if not values:
            return DataType.NULL
        
        # Take a sample to avoid processing too much data
        sample = values[:100]
        
        # Check for integers
        int_count = 0
        float_count = 0
        date_count = 0
        bool_count = 0
        
        for val in sample:
            if val is None:
                continue
            
            val_str = str(val).strip()
            
            # Check boolean
            if val_str.lower() in ('true', 'false', '1', '0', 'yes', 'no'):
                bool_count += 1
                continue
            
            # Check integer
            try:
                int(val_str)
                int_count += 1
                continue
            except (ValueError, TypeError):
                pass
            
            # Check float
            try:
                float(val_str)
                float_count += 1
                continue
            except (ValueError, TypeError):
                pass
            
            # Check date patterns
            if self._is_date_like(val_str):
                date_count += 1
                continue
        
        total_typed = int_count + float_count + date_count + bool_count
        threshold = len(sample) * 0.8  # 80% confidence threshold
        
        if bool_count >= threshold:
            return DataType.BOOLEAN
        elif int_count >= threshold:
            return DataType.INTEGER
        elif (int_count + float_count) >= threshold:
            return DataType.FLOAT
        elif date_count >= threshold:
            return DataType.DATE
        else:
            return DataType.STRING
    
    def _is_date_like(self, value: str) -> bool:
        """Check if a string value looks like a date"""
        date_patterns = [
            '%Y-%m-%d', '%Y-%m-%d %H:%M:%S', '%m/%d/%Y', '%d/%m/%Y',
            '%Y%m%d', '%d-%m-%Y', '%m-%d-%Y'
        ]
        
        for pattern in date_patterns:
            try:
                datetime.strptime(value, pattern)
                return True
            except (ValueError, TypeError):
                continue
        
        return False
    
    def _recommend_chart_types(self) -> List[ChartType]:
        """Recommend chart types based on data characteristics"""
        recommendations = []
        
        if not self.column_info or self.row_count == 0:
            return [ChartType.TABLE]
        
        numeric_columns = [col for col in self.column_info if col.is_numeric]
        temporal_columns = [col for col in self.column_info if col.is_temporal]
        categorical_columns = [col for col in self.column_info if col.is_categorical]
        
        # Time series data
        if len(temporal_columns) >= 1 and len(numeric_columns) >= 1:
            recommendations.append(ChartType.LINE)
        
        # Categorical data with numeric values
        if len(categorical_columns) >= 1 and len(numeric_columns) >= 1:
            recommendations.extend([ChartType.BAR, ChartType.COLUMN])
            
            # Pie chart for simple proportions
            if len(categorical_columns) == 1 and len(numeric_columns) == 1 and self.row_count <= 10:
                recommendations.append(ChartType.PIE)
        
        # Two numeric columns (scatter plot)
        if len(numeric_columns) >= 2:
            recommendations.append(ChartType.SCATTER)
        
        # Always include table as fallback
        if ChartType.TABLE not in recommendations:
            recommendations.append(ChartType.TABLE)
        
        return recommendations[:3]  # Limit to top 3 recommendations
    
    def get_summary_stats(self) -> Dict[str, Any]:
        """Get summary statistics for the dataset"""
        if self.data_summary:
            return self.data_summary
        
        summary = {
            'total_rows': self.row_count,
            'total_columns': self.column_count,
            'numeric_columns': len([col for col in self.column_info if col.is_numeric]),
            'temporal_columns': len([col for col in self.column_info if col.is_temporal]),
            'categorical_columns': len([col for col in self.column_info if col.is_categorical]),
            'has_nulls': any(col.null_count > 0 for col in self.column_info),
            'recommended_charts': [chart.value for chart in self.recommended_chart_types]
        }
        
        self.data_summary = summary
        return summary
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        return {
            'columns': self.columns,
            'data': self.data,
            'execution_id': self.execution_id,
            'conversation_id': self.conversation_id,
            'row_count': self.row_count,
            'column_count': self.column_count,
            'execution_time_ms': self.execution_time_ms,
            'query_hash': self.query_hash,
            'column_info': [col.to_dict() for col in self.column_info],
            'recommended_chart_types': [chart.value for chart in self.recommended_chart_types],
            'data_summary': self.get_summary_stats(),
            'cached_at': self.cached_at.isoformat() if self.cached_at else None,
            'cache_key': self.cache_key
        }
    
    @classmethod
    def from_api_response(cls, api_response: Dict[str, Any]) -> 'ResultData':
        """Create ResultData from API response"""
        return cls(
            columns=api_response.get('columns', []),
            data=api_response.get('data', []),
            execution_id=api_response.get('execution_id', ''),
            conversation_id=api_response.get('conversation_id'),
            row_count=api_response.get('row_count', 0),
            column_count=len(api_response.get('columns', [])),
            execution_time_ms=api_response.get('execution_time_ms'),
            query_hash=api_response.get('query_hash')
        )


@dataclass
class CachedResult:
    """Cached query result with metadata"""
    result_data: ResultData
    query_sql: str
    domain: str
    semantic_view: str
    created_at: datetime
    access_count: int = 0
    last_accessed: Optional[datetime] = None
    
    def touch(self):
        """Update access information"""
        self.access_count += 1
        self.last_accessed = datetime.now()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for storage"""
        return {
            'result_data': self.result_data.to_dict(),
            'query_sql': self.query_sql,
            'domain': self.domain,
            'semantic_view': self.semantic_view,
            'created_at': self.created_at.isoformat(),
            'access_count': self.access_count,
            'last_accessed': self.last_accessed.isoformat() if self.last_accessed else None
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'CachedResult':
        """Create from dictionary"""
        result_data = ResultData(
            columns=data['result_data']['columns'],
            data=data['result_data']['data'],
            execution_id=data['result_data']['execution_id']
        )
        
        return cls(
            result_data=result_data,
            query_sql=data['query_sql'],
            domain=data['domain'],
            semantic_view=data['semantic_view'],
            created_at=datetime.fromisoformat(data['created_at']),
            access_count=data.get('access_count', 0),
            last_accessed=datetime.fromisoformat(data['last_accessed']) if data.get('last_accessed') else None
        )


# Helper functions for data type detection and formatting

def format_value_for_display(value: Any, data_type: DataType) -> str:
    """Format a value for UI display based on its data type"""
    if value is None:
        return "NULL"
    
    if data_type == DataType.FLOAT:
        try:
            float_val = float(value)
            if float_val.is_integer():
                return str(int(float_val))
            else:
                return f"{float_val:.2f}"
        except (ValueError, TypeError):
            return str(value)
    
    elif data_type == DataType.INTEGER:
        try:
            return f"{int(value):,}"  # Add comma separators
        except (ValueError, TypeError):
            return str(value)
    
    elif data_type in [DataType.DATE, DataType.DATETIME]:
        try:
            if isinstance(value, str):
                # Try to parse and reformat
                dt = datetime.fromisoformat(value.replace('Z', '+00:00'))
                return dt.strftime('%Y-%m-%d %H:%M:%S') if data_type == DataType.DATETIME else dt.strftime('%Y-%m-%d')
        except (ValueError, TypeError):
            pass
        return str(value)
    
    else:
        return str(value)


def generate_cache_key(query_sql: str, domain: str, semantic_view: str) -> str:
    """Generate a cache key for a query result"""
    import hashlib
    content = f"{query_sql}|{domain}|{semantic_view}"
    return hashlib.md5(content.encode()).hexdigest()


def detect_chart_compatibility(column_info: List[ColumnInfo]) -> Dict[ChartType, bool]:
    """Detect which chart types are compatible with the data"""
    compatibility = {}
    
    numeric_cols = [col for col in column_info if col.is_numeric]
    temporal_cols = [col for col in column_info if col.is_temporal]
    categorical_cols = [col for col in column_info if col.is_categorical]
    
    # Line chart: needs temporal + numeric
    compatibility[ChartType.LINE] = len(temporal_cols) >= 1 and len(numeric_cols) >= 1
    
    # Bar/Column chart: needs categorical + numeric
    compatibility[ChartType.BAR] = len(categorical_cols) >= 1 and len(numeric_cols) >= 1
    compatibility[ChartType.COLUMN] = compatibility[ChartType.BAR]
    
    # Pie chart: needs 1 categorical + 1 numeric, limited rows
    compatibility[ChartType.PIE] = (len(categorical_cols) == 1 and 
                                   len(numeric_cols) == 1)
    
    # Scatter plot: needs 2+ numeric columns
    compatibility[ChartType.SCATTER] = len(numeric_cols) >= 2
    
    # Table: always compatible
    compatibility[ChartType.TABLE] = True
    
    return compatibility