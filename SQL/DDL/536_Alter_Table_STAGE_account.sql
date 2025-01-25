
IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'IsPolicyChangeRelatedToInspection'
) BEGIN alter table edw_stage.account add IsPolicyChangeRelatedToInspection bit  null end;


IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'PartnerDomain'
) BEGIN alter table edw_stage.account add PartnerDomain nvarchar(250) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'ExternalSubmitDateTime'
) BEGIN alter table edw_stage.account add ExternalSubmitDateTime datetime2(7) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'FirstBindRequestDateTime'
) BEGIN alter table edw_stage.account add FirstBindRequestDateTime datetime2(7) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'FirstExternalSubmitUserId'
) BEGIN alter table edw_stage.account add FirstExternalSubmitUserId uniqueidentifier null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'FirstOfferedDateTime'
) BEGIN alter table edw_stage.account add FirstOfferedDateTime datetime2(7) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'FirstResponseDateTime'
) BEGIN alter table edw_stage.account add FirstResponseDateTime datetime2(7) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'NumberOfRevisions'
) BEGIN alter table edw_stage.account add NumberOfRevisions int  null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'IsInspectionCompleted'
) BEGIN alter table edw_stage.account add IsInspectionCompleted bit  null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'LatestInspectionDateTime'
) BEGIN alter table edw_stage.account add LatestInspectionDateTime datetime2(7) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'CurrentOrBoundGrossPremium'
) BEGIN alter table edw_stage.account add CurrentOrBoundGrossPremium decimal(16,4) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'CurrentOrBoundTotalPremium'
) BEGIN alter table edw_stage.account add CurrentOrBoundTotalPremium decimal(16,4) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'RenewalChangeNote'
) BEGIN alter table edw_stage.account add RenewalChangeNote nvarchar(3800) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'PlainTextRenewalChangeNote'
) BEGIN alter table edw_stage.account add PlainTextRenewalChangeNote nvarchar(3000) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'InsuranceRateScore'
) BEGIN alter table edw_stage.account add InsuranceRateScore  decimal(18,7) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'IsPremiumSelectedByUser'
) BEGIN alter table edw_stage.account add IsPremiumSelectedByUser bit  null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'MustReviewBindRequest'
) BEGIN alter table edw_stage.account add MustReviewBindRequest bit  null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'MustReviewQuote'
) BEGIN alter table edw_stage.account add MustReviewQuote bit  null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'ShowPremium'
) BEGIN alter table edw_stage.account add ShowPremium bit  null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'UseProgram'
) BEGIN alter table edw_stage.account add UseProgram nvarchar(2000) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'SubmissionCloseReasonCarrier'
) BEGIN alter table edw_stage.account add SubmissionCloseReasonCarrier nvarchar(500) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'SubmissionCloseReasonCategory'
) BEGIN alter table edw_stage.account add SubmissionCloseReasonCategory nvarchar(200) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'SubmissionCloseReasonDetailOther'
) BEGIN alter table edw_stage.account add SubmissionCloseReasonDetailOther nvarchar(3000) null end;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'account'
    AND     COLUMN_NAME = 'SubmissionCloseReasonDetails'
) BEGIN alter table edw_stage.account add SubmissionCloseReasonDetails nvarchar(3000) null end; 