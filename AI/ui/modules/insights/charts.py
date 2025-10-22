"""
Simplified Plotly chart generation for the Insights module.

Refactored chart generation with dedicated functions per chart type and dynamic parameters.
Each chart type has specific parameters that match Plotly's API requirements.

Features:
- Automatic currency/numeric value cleaning (removes $, €, £, ¥, commas, parentheses)
- Handles formatted values like: $14,864,518.60, €1.234,56, (1,234.00)
- Automatic type conversion for chart compatibility
"""

import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
import plotly.io as pio
from typing import Dict, List, Any, Union, Tuple, Optional
import json
from utils.logging import logger


# ============================================================================
# CHART PARAMETERS CONFIGURATION
# ============================================================================
# Defines parameters, labels, and validation rules for each chart type

CHART_PARAMS_CONFIG = {
    'bar': {
        'required': ['x', 'y'],
        'optional': ['color'],
        'ui_labels': {
            'x': 'Category Column',
            'y': 'Value Column',
            'color': 'Group By (Optional)'
        },
        'column_types': {
            'x': ['categorical', 'text'],
            'y': ['numeric'],
            'color': ['categorical', 'text']
        },
        'description': 'Compare values across categories with vertical bars',
        'plotly_method': 'px.bar'
    },
    'line': {
        'required': ['x', 'y'],
        'optional': ['color'],
        'ui_labels': {
            'x': 'X-Axis Column (Time/Sequence)',
            'y': 'Y-Axis Column (Metric)',
            'color': 'Multiple Lines (Optional)'
        },
        'column_types': {
            'x': ['datetime', 'numeric', 'text'],
            'y': ['numeric'],
            'color': ['categorical', 'text']
        },
        'description': 'Show trends over time or sequences',
        'plotly_method': 'px.line'
    },
    'pie': {
        'required': ['names', 'values'],
        'optional': [],
        'ui_labels': {
            'names': 'Labels Column',
            'values': 'Values Column'
        },
        'column_types': {
            'names': ['categorical', 'text'],
            'values': ['numeric']
        },
        'description': 'Show proportions of a whole',
        'plotly_method': 'px.pie'
    },
    'multi_line': {
        'required': ['x', 'y', 'color'],
        'optional': [],
        'ui_labels': {
            'x': 'X-Axis Column (Time/Sequence)',
            'y': 'Y-Axis Column (Metric)',
            'color': 'Multiple Lines (Required)'
        },
        'column_types': {
            'x': ['datetime', 'numeric', 'text'],
            'y': ['numeric'],
            'color': ['categorical', 'text']
        },
        'description': 'Compare multiple trends over time or sequences',
        'plotly_method': 'px.line'
    }
}


def get_chart_config(chart_type: str) -> Optional[Dict[str, Any]]:
    """
    Retrieve configuration for a specific chart type.
    
    Args:
        chart_type: Type of chart ('bar', 'line', 'pie', 'multi_line')
    
    Returns:
        Configuration dictionary or None if chart type not found
    """
    config = CHART_PARAMS_CONFIG.get(chart_type)
    if not config:
        logger.warning(f"Chart type '{chart_type}' not found in configuration")
    return config


def validate_chart_params(chart_type: str, params: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
    """
    Validate that required parameters are present for a chart type.
    
    Args:
        chart_type: Type of chart
        params: Dictionary of parameters (e.g., {'x': 'COLUMN1', 'y': 'COLUMN2'})
    
    Returns:
        Tuple of (is_valid, error_message)
    """
    config = get_chart_config(chart_type)
    if not config:
        return False, f"Unknown chart type: {chart_type}"
    
    # Check required parameters
    required_params = config.get('required', [])
    missing_params = [p for p in required_params if not params.get(p)]
    
    if missing_params:
        return False, f"Missing required parameters for {chart_type} chart: {', '.join(missing_params)}"
    
    return True, None


def normalize_chart_params(chart_type: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Normalize parameters to match the expected format for each chart type.
    This handles legacy formats (x_col/y_col) and ensures correct parameter names.
    
    Each chart type has its own parameter mapping logic:
    - bar, line: x, y, color (standard)
    - pie: names, values (special)
    - multi_line: x, y, color (all required)
    
    Args:
        chart_type: Type of chart ('bar', 'line', 'pie', 'multi_line')
        params: Input parameters (may use legacy names like x_col/y_col)
    
    Returns:
        Normalized parameters dictionary with correct keys for the chart type
    
    Examples:
        >>> normalize_chart_params('pie', {'x': 'Category', 'y': 'Amount'})
        {'names': 'Category', 'values': 'Amount'}
        
        >>> normalize_chart_params('bar', {'x_col': 'Month', 'y_col': 'Sales'})
        {'x': 'Month', 'y': 'Sales'}
        
        >>> normalize_chart_params('multi_line', {'x': 'Date', 'y': 'Revenue', 'color': 'Region'})
        {'x': 'Date', 'y': 'Revenue', 'color': 'Region'}
    """
    if not params:
        return {}
    
    normalized = {}
    
    # Legacy parameter name conversion (x_col -> x, y_col -> y)
    if 'x_col' in params and 'x' not in params:
        params['x'] = params['x_col']
    if 'y_col' in params and 'y' not in params:
        params['y'] = params['y_col']
    if 'color_col' in params and 'color' not in params:
        params['color'] = params['color_col']
    
    # Chart-specific parameter mapping
    if chart_type == 'pie':
        # Pie chart uses 'names' and 'values' instead of 'x' and 'y'
        normalized['names'] = params.get('names') or params.get('x')
        normalized['values'] = params.get('values') or params.get('y')
        logger.debug(f"Normalized pie chart params: {normalized}")
        
    elif chart_type in ['bar', 'line']:
        # Bar and line charts use standard x, y, color
        if 'x' in params:
            normalized['x'] = params['x']
        if 'y' in params:
            normalized['y'] = params['y']
        if 'color' in params:
            normalized['color'] = params['color']
        logger.debug(f"Normalized {chart_type} chart params: {normalized}")
        
    elif chart_type == 'multi_line':
        # Multi-line chart requires x, y, and color (all mandatory)
        if 'x' in params:
            normalized['x'] = params['x']
        if 'y' in params:
            normalized['y'] = params['y']
        if 'color' in params:
            normalized['color'] = params['color']
        logger.debug(f"Normalized multi_line chart params: {normalized}")
        
    else:
        # Unknown chart type - pass through as-is
        logger.warning(f"Unknown chart type '{chart_type}' in normalize_chart_params, passing params as-is")
        normalized = params.copy()
    
    return normalized


def auto_detect_chart_params(df: pd.DataFrame, chart_type: str) -> Dict[str, str]:
    """
    Auto-detect parameters for a chart type based on DataFrame columns.
    
    Args:
        df: DataFrame with data
        chart_type: Type of chart
    
    Returns:
        Dictionary of auto-detected parameters
    """
    params = {}
    
    logger.info(f"Auto-detection for {chart_type}: DataFrame shape={df.shape}, columns={list(df.columns)}")
    
    if df.empty or len(df.columns) < 2:
        logger.warning(f"Cannot auto-detect parameters: DataFrame empty or less than 2 columns")
        return params
    
    # Identify numeric and categorical columns
    numeric_cols = df.select_dtypes(include=['int64', 'float64', 'int32', 'float32']).columns.tolist()
    categorical_cols = df.select_dtypes(include=['object', 'string', 'category']).columns.tolist()
    datetime_cols = df.select_dtypes(include=['datetime64']).columns.tolist()
    
    logger.info(f"Column analysis: numeric={numeric_cols}, categorical={categorical_cols}, datetime={datetime_cols}")
    
    if chart_type == 'pie':
        # For pie chart: first categorical/text column for names, first numeric for values
        if len(categorical_cols) > 0 and len(numeric_cols) > 0:
            params['names'] = categorical_cols[0]
            params['values'] = numeric_cols[0]
            logger.info(f"✅ Auto-detected pie chart params: names={params['names']}, values={params['values']}")
        else:
            logger.warning(f"Cannot auto-detect pie params: need at least 1 categorical and 1 numeric column")
        
    elif chart_type == 'bar':
        # For bar chart: first categorical for x, first numeric for y
        if len(categorical_cols) > 0 and len(numeric_cols) > 0:
            params['x'] = categorical_cols[0]
            params['y'] = numeric_cols[0]
            logger.info(f"Auto-detected bar chart params: x={params['x']}, y={params['y']}")
    
    elif chart_type == 'line':
        # For line chart: prefer datetime/numeric for x, numeric for y
        if len(datetime_cols) > 0 and len(numeric_cols) > 0:
            params['x'] = datetime_cols[0]
            params['y'] = numeric_cols[0]
        elif len(numeric_cols) >= 2:
            params['x'] = numeric_cols[0]
            params['y'] = numeric_cols[1]
        elif len(df.columns) >= 2:
            params['x'] = df.columns[0]
            params['y'] = df.columns[1]
        if params:
            logger.info(f"Auto-detected line chart params: x={params.get('x')}, y={params.get('y')}")
    
    elif chart_type == 'multi_line':
        # For multi-line chart: prefer datetime/numeric for x, numeric for y, categorical for color
        if len(datetime_cols) > 0 and len(numeric_cols) > 0 and len(categorical_cols) > 0:
            params['x'] = datetime_cols[0]
            params['y'] = numeric_cols[0]
            params['color'] = categorical_cols[0]
        elif len(numeric_cols) >= 2 and len(categorical_cols) > 0:
            params['x'] = numeric_cols[0]
            params['y'] = numeric_cols[1]
            params['color'] = categorical_cols[0]
        elif len(df.columns) >= 3:
            # Fallback: use first 3 columns
            params['x'] = df.columns[0]
            params['y'] = df.columns[1]
            params['color'] = df.columns[2]
        if params:
            logger.info(f"Auto-detected multi-line chart params: x={params.get('x')}, y={params.get('y')}, color={params.get('color')}")
    
    return params


class ChartGenerator:
    """Simplified Plotly chart generation class."""
    
    def __init__(self):
        """Initialize chart generator with default configuration."""
        self.config = {
            'displayModeBar': True,
            'displaylogo': False,
            'modeBarButtonsToRemove': [
                'pan2d', 'lasso2d', 'select2d', 
                'toggleSpikelines', 'hoverClosestCartesian', 'hoverCompareCartesian'
            ],
            'responsive': True
        }
        pio.templates.default = "plotly_white"
        
    def generate_chart(self, data: Union[List[Dict], pd.DataFrame], 
                      chart_type: str, 
                      title: str = "Data Visualization",
                      params: Dict[str, str] = None,
                      columns: List[str] = None,
                      **kwargs) -> Dict[str, Any]:
        """
        Generate interactive Plotly chart using chart-specific functions.
        
        Args:
            data: DataFrame or list of dictionaries with data
            chart_type: Type of chart ('bar', 'line', 'pie', 'multi_line')
            title: Chart title
            params: Dictionary of parameters (e.g., {'x': 'COLUMN1', 'y': 'COLUMN2', 'color': 'COLUMN3'})
            columns: Column names if data is list of lists
            **kwargs: Additional chart-specific parameters
        
        Returns:
            Dictionary with chart data and metadata
        """
        try:
            # Convert data to DataFrame
            df = self._to_dataframe(data, columns)
            
            if df.empty:
                return self._empty_response()
            
            # Validate chart type
            if not chart_type:
                return {
                    'type': 'error',
                    'title': title,
                    'success': False,
                    'error': 'Chart type is required. Please select a chart type.'
                }
            
            # STEP 1: Normalize parameters for this chart type
            # This handles legacy formats (x_col/y_col) and ensures correct parameter names
            if params:
                params = normalize_chart_params(chart_type, params)
                logger.info(f"Normalized parameters for {chart_type}: {params}")
            
            # STEP 2: Auto-detect parameters if not provided or still empty after normalization
            needs_autodetect = False
            if not params or len(params) == 0:
                needs_autodetect = True
                logger.info(f"No parameters provided for {chart_type}, attempting auto-detection...")
            
            if needs_autodetect:
                params = auto_detect_chart_params(df, chart_type)
                logger.info(f"Auto-detected parameters: {params}")
            
            # STEP 3: Validate parameters
            is_valid, error_msg = validate_chart_params(chart_type, params)
            if not is_valid:
                logger.error(f"Parameter validation failed: {error_msg}")
                return {
                    'type': 'error',
                    'title': title,
                    'success': False,
                    'error': error_msg
                }
            
            logger.info(f"Generating {chart_type} chart with params: {params}")
            
            # Call chart-specific function based on type
            if chart_type == 'bar':
                fig = self.create_bar_chart(
                    df, 
                    x=params.get('x'), 
                    y=params.get('y'), 
                    color=params.get('color'),
                    title=title
                )
            elif chart_type == 'line':
                fig = self.create_line_chart(
                    df,
                    x=params.get('x'),
                    y=params.get('y'),
                    color=params.get('color'),
                    title=title
                )
            elif chart_type == 'pie':
                fig = self.create_pie_chart(
                    df,
                    names=params.get('names'),
                    values=params.get('values'),
                    title=title
                )
            elif chart_type == 'multi_line':
                fig = self.create_multi_line_chart(
                    df,
                    x=params.get('x'),
                    y=params.get('y'),
                    color=params.get('color'),
                    title=title
                )
            else:
                # For now, return error for unsupported chart types
                return {
                    'type': 'error',
                    'title': title,
                    'success': False,
                    'error': f"Chart type '{chart_type}' is not yet implemented"
                }
            
            # Convert figure to JSON-serializable format
            fig_dict = self._serialize_figure(fig)
            
            # Get column metadata
            column_types = self._get_column_types(df)
            
            # Return chart data
            return {
                'chart_id': f"chart-{chart_type}-{hash(str(title)) % 10000}",
                'data': fig_dict['data'],
                'layout': fig_dict['layout'],
                'config': self.config,
                'type': chart_type,
                'title': title,
                'columns': list(df.columns),
                'column_types': column_types,
                'params': params,
                'rows': len(df),
                'success': True
            }
            
        except Exception as e:
            logger.error(f"Error generating chart: {e}", exc_info=True)
            return {
                'type': 'error',
                'title': title,
                'success': False,
                'error': str(e)
            }
    
    # ========================================================================
    # CHART-SPECIFIC FUNCTIONS
    # ========================================================================
    
    def create_bar_chart(self, df: pd.DataFrame, x: str, y: str, 
                        color: Optional[str] = None, 
                        title: str = 'Bar Chart') -> go.Figure:
        """
        Create a vertical bar chart.
        
        Args:
            df: DataFrame with data
            x: Column name for x-axis (categories)
            y: Column name for y-axis (values)
            color: Optional column name for grouping/coloring bars
            title: Chart title
        
        Returns:
            Plotly Figure object
        
        Raises:
            ValueError: If required columns are missing or invalid types
        """
        # Validate columns exist
        if x not in df.columns:
            raise ValueError(f"X-axis column '{x}' not found in data. Please select a valid category column.")
        if y not in df.columns:
            raise ValueError(f"Y-axis column '{y}' not found in data. Please select a valid value column.")
        if color and color not in df.columns:
            raise ValueError(f"Color grouping column '{color}' not found in data. Please select a valid column.")
        
        # Validate y column is numeric (Y-axis must be numeric for bar charts)
        if df[y].dtype not in ['int64', 'float64', 'int32', 'float32']:
            actual_type = 'date/time' if pd.api.types.is_datetime64_any_dtype(df[y]) else 'text/categorical'
            raise ValueError(
                f"❌ Y-axis (Value Column) must be numeric.\n"
                f"Column '{y}' is {actual_type}, but bar charts require numeric values on the Y-axis.\n"
                f"💡 Tip: Select a numeric column (counts, amounts, percentages) for the Y-axis (Value Column)."
            )
        
        # Sort by y value (descending) for better visualization
        df_sorted = df.sort_values(by=y, ascending=False).copy()
        
        # Store column names for styling
        self._current_x_col = x
        self._current_y_col = y
        
        # Create bar chart
        if color:
            # Grouped/colored bar chart
            fig = px.bar(
                df_sorted, 
                x=x, 
                y=y, 
                color=color,
                title=title,
                barmode='group'
            )
            logger.info(f"Created grouped bar chart: x={x}, y={y}, color={color}")
        else:
            # Simple bar chart
            fig = px.bar(
                df_sorted, 
                x=x, 
                y=y, 
                title=title
            )
            logger.info(f"Created simple bar chart: x={x}, y={y}")
        
        # Apply styling
        self._style_chart(fig, 'bar')
        
        return fig
    
    def create_line_chart(self, df: pd.DataFrame, x: str, y: str,
                         color: Optional[str] = None,
                         title: str = 'Line Chart') -> go.Figure:
        """
        Create a line chart to show trends over time or sequences.
        
        Args:
            df: DataFrame with data
            x: Column name for x-axis (time/sequence)
            y: Column name for y-axis (metric)
            color: Optional column name for creating multiple lines
            title: Chart title
        
        Returns:
            Plotly Figure object
        
        Raises:
            ValueError: If required columns are missing or invalid types
        """
        # Validate columns exist
        if x not in df.columns:
            raise ValueError(f"X-axis column '{x}' not found in data. Please select a valid time/sequence column.")
        if y not in df.columns:
            raise ValueError(f"Y-axis column '{y}' not found in data. Please select a valid metric column.")
        if color and color not in df.columns:
            raise ValueError(f"Line grouping column '{color}' not found in data. Please select a valid column.")
        
        # Validate y column is numeric (Y-axis must be numeric for line charts)
        if df[y].dtype not in ['int64', 'float64', 'int32', 'float32']:
            actual_type = 'date/time' if pd.api.types.is_datetime64_any_dtype(df[y]) else 'text/categorical'
            raise ValueError(
                f"❌ Y-axis (Metric Column) must be numeric.\n"
                f"Column '{y}' is {actual_type}, but line charts require numeric values on the Y-axis.\n"
                f"💡 Tip: Select a numeric column (sales, counts, percentages) for the Y-axis (Metric Column)."
            )
        
        # Sort by x value for proper line continuity
        df_sorted = df.sort_values(by=x).copy()
        
        # Store column names for styling
        self._current_x_col = x
        self._current_y_col = y
        
        # Create line chart
        if color:
            # Multi-line chart with color grouping
            fig = px.line(
                df_sorted,
                x=x,
                y=y,
                color=color,
                title=title,
                markers=True  # Add markers to make data points visible
            )
            logger.info(f"Created multi-line chart: x={x}, y={y}, color={color}")
        else:
            # Simple line chart
            fig = px.line(
                df_sorted,
                x=x,
                y=y,
                title=title,
                markers=True  # Add markers to make data points visible
            )
            logger.info(f"Created simple line chart: x={x}, y={y}")
        
        # Apply styling
        self._style_chart(fig, 'line')
        
        return fig
    
    def create_multi_line_chart(self, df: pd.DataFrame, x: str, y: str, color: str,
                                title: str = 'Multi-Line Chart') -> go.Figure:
        """
        Create a multi-line chart to compare multiple trends over time or sequences.
        This chart type requires a color parameter to create distinct lines for different groups.
        
        Args:
            df: DataFrame with data
            x: Column name for X-axis (time/sequence)
            y: Column name for Y-axis (metric)
            color: Column name for line grouping (REQUIRED - creates multiple lines)
            title: Chart title
        
        Returns:
            Plotly Figure object
        
        Raises:
            ValueError: If required columns are missing or invalid types
        """
        # Validate columns exist
        if x not in df.columns:
            raise ValueError(f"X-axis column '{x}' not found in data. Please select a valid time/sequence column.")
        if y not in df.columns:
            raise ValueError(f"Y-axis column '{y}' not found in data. Please select a valid metric column.")
        if not color or color not in df.columns:
            raise ValueError(f"Line grouping column '{color}' is required for multi-line charts. Please select a valid column.")
        
        # Validate y column is numeric
        if df[y].dtype not in ['int64', 'float64', 'int32', 'float32']:
            actual_type = 'date/time' if pd.api.types.is_datetime64_any_dtype(df[y]) else 'text/categorical'
            raise ValueError(
                f"❌ Y-axis (Metric Column) must be numeric.\n"
                f"Column '{y}' is {actual_type}, but multi-line charts require numeric values on the Y-axis.\n"
                f"💡 Tip: Select a numeric column (sales, counts, percentages) for the Y-axis (Metric Column)."
            )
        
        # Sort by x value for proper line continuity
        df_sorted = df.sort_values(by=x).copy()
        
        # Store column names for styling
        self._current_x_col = x
        self._current_y_col = y
        
        # Create multi-line chart with color grouping
        fig = px.line(
            df_sorted,
            x=x,
            y=y,
            color=color,
            title=title,
            markers=True  # Add markers to make data points visible
        )
        
        logger.info(f"Created multi-line chart: x={x}, y={y}, color={color}, unique lines={df[color].nunique()}")
        
        # Apply styling
        self._style_chart(fig, 'multi_line')
        
        return fig
    
    def create_pie_chart(self, df: pd.DataFrame, names: str, values: str,
                        title: str = 'Pie Chart') -> go.Figure:
        """
        Create a pie chart to show proportions of a whole.
        
        Args:
            df: DataFrame with data
            names: Column name for pie slice labels
            values: Column name for pie slice values
            title: Chart title
        
        Returns:
            Plotly Figure object
        
        Raises:
            ValueError: If required columns are missing or invalid types
        """
        # Validate columns exist
        if names not in df.columns:
            raise ValueError(f"Names column '{names}' not found in data. Please select a valid labels column.")
        if values not in df.columns:
            raise ValueError(f"Values column '{values}' not found in data. Please select a valid values column.")
        
        # Validate values column is numeric (values must be numeric for pie charts)
        if df[values].dtype not in ['int64', 'float64', 'int32', 'float32']:
            actual_type = 'date/time' if pd.api.types.is_datetime64_any_dtype(df[values]) else 'text/categorical'
            raise ValueError(
                f"❌ Values Column must be numeric.\n"
                f"Column '{values}' is {actual_type}, but pie charts require numeric values.\n"
                f"💡 Tip: Select a numeric column (counts, amounts, percentages) for the Values Column."
            )
        
        # Clean and prepare data
        df_clean = df.dropna(subset=[names, values]).copy()
        
        logger.info(f"Pie chart data - Original rows: {len(df)}, Names col: {names}, Values col: {values}")
        logger.info(f"Values column dtype: {df[values].dtype}, Sample values: {df[values].head().tolist()}")
        
        # Aggregate by names if there are duplicates
        if df_clean[names].duplicated().any():
            df_aggregated = df_clean.groupby(names)[values].sum().reset_index()
            logger.info(f"Aggregated duplicate labels in pie chart: {names} by {values}")
            logger.info(f"After aggregation - Rows: {len(df_aggregated)}, Values sum: {df_aggregated[values].sum()}")
        else:
            df_aggregated = df_clean
            logger.info(f"No duplicates found - using original data")
        
        # Sort by values (descending) for better visualization
        df_sorted = df_aggregated.sort_values(by=values, ascending=False).copy()
        
        # Log the actual data being sent to plotly
        logger.info(f"Data for pie chart (sorted):")
        for idx, row in df_sorted.head(10).iterrows():
            logger.info(f"  {row[names]}: {row[values]}")
        
        # Store column names for styling
        self._current_names_col = names
        self._current_values_col = values
        
        # Create pie chart
        logger.info(f"Creating px.pie with names={names}, values={values}, shape={df_sorted.shape}")
        fig = px.pie(
            df_sorted,
            names=names,
            values=values,
            title=title
        )
        logger.info(f"Pie chart created successfully with {len(fig.data[0].labels)} slices")
        
        # Enhance pie chart styling
        fig.update_traces(
            textposition='outside',  # Labels outside the pie slices
            textinfo='label+percent',  # Show label and percentage
            hovertemplate='<b>%{label}</b><br>' +
                         'Value: %{value:,.0f}<br>' +
                         'Percentage: %{percent}<br>' +
                         '<extra></extra>',
            pull=[0.05 if i == 0 else 0 for i in range(len(df_sorted))]  # Slightly pull out the largest slice
        )
        
        logger.info(f"Created pie chart: names={names}, values={values}")
        
        # Apply styling
        self._style_chart(fig, 'pie')
        
        return fig
    
    def _clean_currency_value(self, value: Any) -> Any:
        """
        Clean currency/numeric values by removing formatting characters.
        
        Handles values like: $14,864,518.60, €1.234,56, (1,234.00)
        
        Args:
            value: Value to clean
            
        Returns:
            Cleaned numeric value or original value if not currency-like
        """
        if pd.isna(value) or not isinstance(value, str):
            return value
        
        original_value = value
        value = value.strip()
        
        # Check if value looks like a formatted number (contains currency symbols or thousands separators)
        if not any(char in value for char in ['$', '€', '£', '¥', ',', '(', ')']):
            return original_value
        
        try:
            # Handle negative values in parentheses: (1,234.00) -> -1234.00
            is_negative = value.startswith('(') and value.endswith(')')
            
            # Remove currency symbols, spaces, and thousand separators
            cleaned = value.replace('$', '').replace('€', '').replace('£', '').replace('¥', '')
            cleaned = cleaned.replace(',', '').replace(' ', '').replace('(', '').replace(')', '')
            
            # Convert to float
            numeric_value = float(cleaned)
            
            # Apply negative sign if value was in parentheses
            if is_negative:
                numeric_value = -numeric_value
            
            logger.debug(f"Cleaned currency value: '{original_value}' -> {numeric_value}")
            return numeric_value
            
        except (ValueError, AttributeError):
            # If conversion fails, return original value
            return original_value
    
    def _to_dataframe(self, data: Union[List[Dict], pd.DataFrame], columns: List[str] = None) -> pd.DataFrame:
        """Convert input data to DataFrame with automatic type conversion and currency cleaning."""
        if isinstance(data, pd.DataFrame):
            df = data.copy()
        elif isinstance(data, list) and data:
            # Check if data is list of dicts or list of lists
            if isinstance(data[0], dict):
                # List of dictionaries - column names are in the dicts
                df = pd.DataFrame(data)
            elif columns:
                # List of lists with column names provided
                df = pd.DataFrame(data, columns=columns)
            else:
                # List of lists without column names - will use numeric indices
                df = pd.DataFrame(data)
        else:
            return pd.DataFrame()
        
        # Auto-convert string numbers and clean currency values
        for col in df.columns:
            # First, try to clean currency-formatted values
            df[col] = df[col].apply(self._clean_currency_value)
            
            # Then try to convert to numeric
            try:
                df[col] = pd.to_numeric(df[col])
                logger.debug(f"Column '{col}' converted to numeric type")
            except (ValueError, TypeError):
                # Keep as original type if conversion fails
                pass
        
        return df
    
    def _detect_chart_type(self, df: pd.DataFrame) -> str:
        """Auto-detect best chart type based on data."""
        # Get column types
        datetime_cols = [col for col in df.columns 
                        if df[col].dtype in ['datetime64[ns]', 'datetime64', 'date']]
        numerical_cols = [col for col in df.columns 
                         if df[col].dtype in ['int64', 'float64', 'int32', 'float32']]
        categorical_cols = [col for col in df.columns 
                           if col not in datetime_cols and col not in numerical_cols]
        
        # Time series
        if datetime_cols:
            return 'line'
        
        # Categorical with numerical - prefer column charts for better readability
        if categorical_cols and numerical_cols:
            return 'column'
        
        # Two or more numerical columns
        if len(numerical_cols) >= 2:
            return 'scatter'
        
        return 'column'  # Default to column chart
    
    def _get_column_types(self, df: pd.DataFrame) -> Dict[str, str]:
        """Get data types for each column."""
        column_types = {}
        for col in df.columns:
            if df[col].dtype in ['datetime64[ns]', 'datetime64', 'date']:
                column_types[col] = 'datetime'
            elif df[col].dtype in ['int64', 'float64', 'int32', 'float32']:
                column_types[col] = 'numeric'
            else:
                column_types[col] = 'categorical'
        return column_types
    
    def _normalize_column_name(self, df: pd.DataFrame, col_name: str) -> str:
        """Normalize column name to match DataFrame columns (case-insensitive)."""
        if col_name is None:
            return None
        
        # Handle integer column indices
        if isinstance(col_name, int):
            cols = df.columns.tolist()
            if 0 <= col_name < len(cols):
                return cols[col_name]
            else:
                logger.warning(f"Column index {col_name} out of range. Available columns: {list(df.columns)}")
                return None
        
        # Convert to string if not already
        col_name = str(col_name)
        
        # If exact match exists, return it
        if col_name in df.columns:
            return col_name
        
        # Try case-insensitive match
        col_name_lower = col_name.lower()
        for col in df.columns:
            if str(col).lower() == col_name_lower:
                return col
        
        # If no match found, return original (will cause KeyError with better message)
        logger.warning(f"Column '{col_name}' not found in DataFrame. Available columns: {list(df.columns)}")
        return col_name
    
    def _get_columns(self, df: pd.DataFrame, chart_type: str, 
                    x_col: str = None, y_col: str = None) -> Tuple[str, str]:
        """Get appropriate x and y columns."""
        # Normalize column names if provided
        if x_col is not None:
            x_col = self._normalize_column_name(df, x_col)
        if y_col is not None:
            y_col = self._normalize_column_name(df, y_col)
        
        # If both columns are provided and valid, return them
        if x_col and y_col:
            return str(x_col), str(y_col)
        
        cols = df.columns.tolist()
        
        # For bar and column charts: categorical for x, numerical for y
        if chart_type in ['bar', 'column']:
            categorical_col = None
            numerical_col = None
            
            # Find categorical column (string/object type)
            for col in cols:
                if df[col].dtype == 'object':
                    categorical_col = str(col)
                    break
            
            # Find numerical column (numeric type)
            for col in cols:
                if df[col].dtype in ['int64', 'float64', 'int32', 'float32']:
                    numerical_col = str(col)
                    break
            
            # Use provided columns or auto-detected ones
            if not x_col:
                x_col = categorical_col or str(cols[0])
            if not y_col:
                y_col = numerical_col or (str(cols[1]) if len(cols) > 1 else str(cols[0]))
            
            return str(x_col), str(y_col)
        
        # For line and scatter charts
        elif chart_type in ['line', 'scatter'] and len(cols) >= 2:
            if not x_col:
                x_col = str(cols[0])
            if not y_col:
                y_col = str(cols[1])
            return str(x_col), str(y_col)
        
        # Default: first two columns
        if not x_col:
            x_col = str(cols[0])
        if not y_col:
            y_col = str(cols[1]) if len(cols) > 1 else str(cols[0])
        return str(x_col), str(y_col)
    
    def _create_chart(self, df: pd.DataFrame, chart_type: str, title: str,
                     x_col: str, y_col: str, **kwargs) -> go.Figure:
        """Create chart based on type."""
        
        # Sort data by numeric column for better visualization
        if chart_type in ['bar', 'column']:
            df = df.sort_values(by=y_col, ascending=False)
        
        # Store column names for axis labels
        self._current_x_col = x_col
        self._current_y_col = y_col
        self._current_chart_type = chart_type
        
        chart_methods = {
            'line': lambda: px.line(df, x=x_col, y=y_col, title=title, markers=True),
            'bar': lambda: px.bar(df, x=y_col, y=x_col, title=title, orientation='h'),
            'column': lambda: px.bar(df, x=x_col, y=y_col, title=title),
            'pie': lambda: px.pie(df, names=x_col, values=y_col, title=title),
            'scatter': lambda: px.scatter(df, x=x_col, y=y_col, title=title)
        }
        
        method = chart_methods.get(chart_type, chart_methods['bar'])
        return method()
    
    def _style_chart(self, fig: go.Figure, chart_type: str):
        """Apply consistent styling with proper axis labels."""
        
        # Create axis labels with column names
        x_axis_label = None
        y_axis_label = None
        
        if chart_type not in ['pie'] and hasattr(self, '_current_x_col') and hasattr(self, '_current_y_col'):
            # For bar charts (vertical orientation)
            if chart_type == 'bar':
                x_axis_label = self._current_x_col
                y_axis_label = self._current_y_col
            # For line charts and others
            else:
                x_axis_label = self._current_x_col
                y_axis_label = self._current_y_col
        
        fig.update_layout(
            font=dict(family="Inter, sans-serif", size=12),
            plot_bgcolor='rgba(0,0,0,0)',
            paper_bgcolor='rgba(0,0,0,0)',
            margin=dict(l=50, r=50, t=80, b=50),
            showlegend=chart_type not in ['pie'],
            hovermode='closest',
            xaxis_title=x_axis_label,
            yaxis_title=y_axis_label
        )
        
        if chart_type not in ['pie']:
            fig.update_xaxes(
                gridcolor='rgba(0,0,0,0.1)', 
                showgrid=True, 
                title_standoff=10,
                title_font=dict(size=13, color='#374151')
            )
            fig.update_yaxes(
                gridcolor='rgba(0,0,0,0.1)', 
                showgrid=True, 
                title_standoff=10,
                title_font=dict(size=13, color='#374151')
            )
    
    def _serialize_figure(self, fig: go.Figure) -> Dict[str, Any]:
        """Convert Plotly figure to JSON-serializable format."""
        try:
            # Get the figure dict and force array format
            fig_dict = fig.to_dict()
            
            # Convert any binary data to regular arrays
            if 'data' in fig_dict:
                for trace_idx, trace in enumerate(fig_dict['data']):
                    # Handle x, y, z for regular charts
                    for key in ['x', 'y', 'z', 'labels', 'values']:  # Added 'labels' and 'values' for pie charts
                        if key in trace:
                            value = trace[key]
                            # Check if it's binary format and convert to list
                            if isinstance(value, dict) and 'bdata' in value:
                                # Extract the actual array from the trace object
                                if hasattr(fig, 'data') and len(fig.data) > trace_idx:
                                    trace_obj = fig.data[trace_idx]
                                    if hasattr(trace_obj, key):
                                        trace[key] = list(getattr(trace_obj, key))
                                        logger.debug(f"Converted binary data for {key} in trace {trace_idx} to list")
            
            # Preserve axis labels from layout
            converted = self._convert_numpy_to_lists(fig_dict)
            
            # Ensure axis titles are preserved
            if 'layout' in converted:
                # Initialize xaxis and yaxis if they don't exist
                if 'xaxis' not in converted['layout']:
                    converted['layout']['xaxis'] = {}
                if 'yaxis' not in converted['layout']:
                    converted['layout']['yaxis'] = {}
                
                # Get titles from original figure
                if hasattr(fig.layout, 'xaxis') and hasattr(fig.layout.xaxis, 'title') and fig.layout.xaxis.title.text:
                    converted['layout']['xaxis']['title'] = {'text': str(fig.layout.xaxis.title.text)}
                
                if hasattr(fig.layout, 'yaxis') and hasattr(fig.layout.yaxis, 'title') and fig.layout.yaxis.title.text:
                    converted['layout']['yaxis']['title'] = {'text': str(fig.layout.yaxis.title.text)}
            
            return converted
        except Exception as e:
            # Fallback: use basic to_json
            return json.loads(fig.to_json())
    
    def _convert_numpy_to_lists(self, obj):
        """Recursively convert numpy arrays to lists for JSON serialization."""
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        elif isinstance(obj, dict):
            return {key: self._convert_numpy_to_lists(value) for key, value in obj.items()}
        elif isinstance(obj, list):
            return [self._convert_numpy_to_lists(item) for item in obj]
        elif isinstance(obj, tuple):
            return tuple(self._convert_numpy_to_lists(item) for item in obj)
        elif isinstance(obj, (np.integer, np.floating)):
            return obj.item()
        else:
            return obj
    
    def _empty_response(self) -> Dict[str, Any]:
        """Generate response for empty data."""
        return {
            'type': 'empty',
            'title': 'No Data',
            'success': False,
            'error': 'No data provided'
        }


# Global instance
chart_generator = ChartGenerator()


def generate_chart_from_query_result(query_result: Dict[str, Any], 
                                   chart_type: str = None,
                                   title: str = None) -> Dict[str, Any]:
    """Generate chart from SQL query result data."""
    try:
        if not query_result or 'data' not in query_result:
            return chart_generator._empty_response()
        
        data = query_result['data']
        if not data:
            return chart_generator._empty_response()
        
        title = title or query_result.get('description', 'Data Analysis')
        
        return chart_generator.generate_chart(
            data=data,
            chart_type=chart_type,
            title=title
        )
        
    except Exception as e:
        logger.error(f"Error generating chart from query result: {e}")
        return {
            'type': 'error',
            'success': False,
            'error': str(e)
        }


def get_chart_recommendations(data: Union[List[Dict], pd.DataFrame]) -> List[Dict[str, str]]:
    """Get recommended chart types for given data."""
    try:
        df = chart_generator._to_dataframe(data)
        
        if df.empty:
            return []
        
        # Basic recommendations based on data structure
        recommendations = [
            {'type': 'table', 'name': 'Data Table', 'description': 'Tabular view of all data'}
        ]
        
        detected_type = chart_generator._detect_chart_type(df)
        
        # Add appropriate recommendations
        type_info = {
            'line': {'name': 'Line Chart', 'description': 'Show trends over time'},
            'bar': {'name': 'Bar Chart', 'description': 'Compare categories horizontally'},
            'column': {'name': 'Column Chart', 'description': 'Compare categories vertically'},
            'pie': {'name': 'Pie Chart', 'description': 'Show proportions'},
            'scatter': {'name': 'Scatter Plot', 'description': 'Show correlation'}
        }
        
        if detected_type in type_info:
            info = type_info[detected_type]
            recommendations.append({
                'type': detected_type,
                'name': info['name'],
                'description': info['description']
            })
        
        # Add alternative chart types
        if detected_type == 'bar':
            recommendations.append({
                'type': 'column',
                'name': 'Column Chart',
                'description': 'Compare categories vertically'
            })
        elif detected_type == 'column':
            recommendations.append({
                'type': 'bar',
                'name': 'Bar Chart', 
                'description': 'Compare categories horizontally'
            })
        
        return recommendations
        
    except Exception as e:
        logger.error(f"Error getting chart recommendations: {e}")
        return []