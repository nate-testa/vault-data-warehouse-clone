-- exec sp_help 'edw_stage.AccountTransactionVersion';
-- exec sp_help 'edw_stage.Account';

select *
from edw_stage.ControlLoadTable
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionVersion'
;

select *
from edw_stage.ControlLoadTable
where JSON_value(SourceObjectSettings,'$.table') = 'Account'
;

/*
TRUNCATE TABLE edw_stage.Account;
update edw_stage.ControlLoadTable
set 
LastExecution = '{              "LastExecutionDate": "1900-01-01T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }'
,DataLoadingBehaviorSettings = '{   "dataLoadingBehavior": "DeltaLoad",   "watermarkColumnName": "CreatedDate",   "watermarkColumnType": "DateTime",   "watermarkColumnNameUpdate": "UpdatedDate",   "watermarkColumnNameUpdatType": "DateTime",   "watermarkColumnStartValue": "1900-01-01T00:00:00.0000000"  }'
where JSON_value(SourceObjectSettings,'$.table') = 'Account'
;

TRUNCATE TABLE edw_stage.AccountTransactionVersionObject;
update edw_stage.ControlLoadTable
set 
LastExecution = '{              "LastExecutionDate": "1900-01-01T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }'
,DataLoadingBehaviorSettings = '{   "dataLoadingBehavior": "DeltaLoad",   "watermarkColumnName": "CreatedDate",   "watermarkColumnType": "DateTime",   "watermarkColumnNameUpdate": "UpdatedDate",   "watermarkColumnNameUpdatType": "DateTime",   "watermarkColumnStartValue": "1900-01-01T00:00:00.0000000"  }'
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionVersionObject'
;

TRUNCATE TABLE edw_stage.UserRole;
update edw_stage.ControlLoadTable
set 
LastExecution = '{              "LastExecutionDate": "1900-01-01T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }'
,DataLoadingBehaviorSettings = '{   "dataLoadingBehavior": "DeltaLoad",   "watermarkColumnName": "CreatedDate",   "watermarkColumnType": "DateTime",   "watermarkColumnNameUpdate": "UpdatedDate",   "watermarkColumnNameUpdatType": "DateTime",   "watermarkColumnStartValue": "1900-01-01T00:00:00.0000000"  }'
where JSON_value(SourceObjectSettings,'$.table') = 'UserRole'
;
*/