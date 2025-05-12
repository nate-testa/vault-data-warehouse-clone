# Vault Data Warehouse Documentation

## Overview
This document provides an overview of the Vault Insurance Data Warehouse architecture, components, and processes. It serves as a reference for developers, analysts, and stakeholders working with the data warehouse environment.

## Table of Contents
- [Architecture](#architecture)
- [Data Flow](#data-flow)
- [Key Components](#key-components)
- [ETL Processes](#etl-processes)
- [Database Structure](#database-structure)
- [Integration Points](#integration-points)
- [Tools and Technologies](#tools-and-technologies)
- [Data Marts and Reporting](#data-marts-and-reporting)
- [Operational Procedures](#operational-procedures)

## Architecture
The Vault Data Warehouse architecture follows a modern, cloud-based approach with Azure SQL Database as the primary data store. The architecture consists of:

1. **Source Systems Layer**: External systems providing source data (Ebao, Metal, Snapsheet, etc.)
2. **Staging Layer**: Temporary storage for raw data (edw_stage schema)
3. **Integration Layer**: Processing data from various sources (edw_integration schema)
4. **Core Layer**: Business-oriented, transformed data (edw_core schema)
5. **Data Marts**: Subject-oriented views and tables for reporting

## Data Flow
Data flows through the warehouse in the following general pattern:

1. **Extraction**: Data is extracted from source systems using Azure Data Factory pipelines
2. **Staging**: Raw data is loaded into staging tables (edw_stage schema)
3. **Transformation**: Data is validated, cleansed, and transformed
4. **Loading**: Processed data is loaded into core tables (edw_core schema)
5. **Reconciliation**: Data is validated for completeness and accuracy
6. **Reporting**: Final data is made available for reporting and analytics

## Key Components

### Azure Data Factory (ADF)
- **Purpose**: Orchestrates data movement and transformation
- **Key Pipelines**:
  - MetadataDrivenCopy_MetalDB_to_Edw_stage
  - MetadataDrivenCopy_eBao_to_Edw_stage
  - LS_AWS_DMS_dmsDocument
  - LS_AWS_VSP_int_claims_payments_audit

### Apache Airflow
- **Purpose**: Schedules and manages ETL workflows
- **Key DAGs**:
  - vault_edw_data_load: Master DAG for daily data loading
  - ebao_onetime_edw_data_load: One-time data load from Ebao
  - vault_edw_data_load_snapsheet: Snapsheet data integration
  - vault_edw_data_load_quotes: Quotes data integration
  - vault_edw_data_load_hubspot: Hubspot data integration
  - vault_CLUE_auto_daily_feed, vault_CLUE_property_daily_feed: CLUE data integration

### Azure Blob Storage
- **Purpose**: Storage for intermediate files and staging
- **Key Containers**:
  - inbound-inspection-manual
  - inbound-nfp

### SQL Database
- **Purpose**: Primary data storage and processing
- **Key Schemas**:
  - edw_stage: Landing zone for raw data
  - edw_temp: Temporary objects for transformation
  - edw_integration: Integration layer
  - edw_core: Core business data
  - edw_stage_snapsheet: Snapsheet-specific staging

## ETL Processes

### Data Acquisition
1. **Azure Data Factory Pipelines**:
   - Extract data from source systems
   - Load into staging tables

2. **File-Based Acquisition**:
   - Process files from Azure Blob Storage
   - Examples: LC360_file_processing.py, majesco_billing_files_processing.py, NFP_File_Load

### Data Integration
1. **Stored Procedures**:
   - Transform and load data into integration tables
   - Handle data validation and reconciliation
   - Key procedures: sp_migration_create_claim_api, sp_claim_financial_transaction_action_snapsheet_api

2. **External Data Integration**:
   - API-based integration with external systems
   - Examples: snapsheet_api_post.py, hubspot_integration_api_call.py, ivans_api.py

### Data Transformation
1. **Core Layer Procedures**:
   - Transform data into business entities
   - Maintain dimension and fact tables
   - Examples: sp_ttask_workflow, sp_ttask_workflow_step, sp_tclaim_snapsheet

2. **Reconciliation**:
   - Validate data completeness
   - Check for discrepancies between source and target
   - Examples: check_treconciliation_and_send_email function in vault_edw_data_load.py

## Database Structure

### Schema Design
- **edw_stage**: Contains raw data from source systems
- **edw_temp**: Temporary tables for transformation processes
- **edw_integration**: Integration layer for cross-system data
- **edw_core**: Core business entities with proper relationships
- **edw_stage_snapsheet**: Snapsheet-specific staging area

### Key Tables
- **Task Management**: ttask, ttask_workflow, ttask_workflow_step
- **Policy Management**: tpolicy, tquote, tquote_history
- **Claims Management**: tclaim, tclaim_feature, tclaim_payment
- **Customer Data**: tcustomer, tbroker
- **Integration**: Multiple integration tables for different source systems

### Indexing Strategy
- Foreign key indexes on all relationship fields
- Composite indexes for frequent query patterns
- Indexes on frequently used filtering columns (date fields, IDs)

## Integration Points

### External Systems
1. **Snapsheet**:
   - Claims management integration
   - API-based data exchange
   - Financial transaction processing

2. **Hubspot**:
   - Customer and broker data integration
   - Notes and relationship management

3. **CLUE/LexisNexis**:
   - Insurance claims history
   - File-based data exchange with encryption

4. **LiveVox**:
   - Call center integration
   - CSV file generation and SFTP transfer

5. **Ebao/Metal**:
   - Core insurance systems
   - Database-level integration via ADF

6. **NFP**:
   - Partner data integration
   - Excel file processing

7. **LC360**:
   - Inspection data integration
   - Excel file processing

## Tools and Technologies

### ETL Tools
- **Azure Data Factory**: Cloud-based data integration service
- **Apache Airflow**: Workflow orchestration
- **Python**: Custom ETL scripts and data processing
- **SQL Server Stored Procedures**: Data transformation

### Storage Technologies
- **Azure SQL Database**: Primary data storage
- **Azure Blob Storage**: File storage and staging
- **SFTP**: Secure file transfer for partner integration

### Development Tools
- **SQL Server Management Studio**: Database development
- **Visual Studio Code**: Python development
- **Azure Portal**: ADF development and monitoring

## Data Marts and Reporting

### Subject Areas
- Policy Administration
- Claims Management
- Customer Relationships
- Broker Management
- Financial Transactions

### Reporting Tables
- Fact tables for transactional data
- Dimension tables for attributes and hierarchies
- Views for simplified reporting access

## Operational Procedures

### ETL Monitoring
- Automated email notifications on failure
- Reconciliation checks after data loads
- Logging and error tracking

### Data Quality Management
- Validation rules in transformation processes
- Reconciliation against source systems
- Data quality metrics tracking

### Release Management
- Release notes maintained in dedicated tables
- Version control for database objects
- Deployment procedures for schema changes

### Disaster Recovery
- Database backups
- Pipeline retry mechanisms
- Error handling and notification