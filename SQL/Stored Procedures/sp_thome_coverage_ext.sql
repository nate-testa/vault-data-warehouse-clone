SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 

-- =====================================================================================================================
-- Description: This stored procedure loads to thome_coverage_ext.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 08/30/24		        Architha Gudimalla			    1. Created this procedure   
-- ===================================================================================================================== 

CREATE OR ALTER PROCEDURE edw_core.sp_thome_coverage_ext 
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
        
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		--************Start************

        /*DROP TABLE IF EXISTS edw_temp.thome_coverage_ext_temp0;

        SELECT distinct  pdo.ObjectType
        into edw_temp.thome_coverage_ext_temp0
        FROM edw_stage.Product pd
		INNER JOIN edw_stage.ProductObject pdo on pd.Id=pdo.ProductId
		INNER JOIN edw_stage.ProductObjectField pdof on pdo.Id=pdof.ProductObjectId  
		WHERE pd.Name in ('Homeowners','Condo','Inspection')  
		--AND pdo.ObjectType not in ('Form1655','LossHistory','Manuscript','Mortgagee','AdditionalInterest','AdditionalInsured','Insured','Condo','Homeowner','Collection','CollectionClass','CollectionClassScheduleItem')  
		AND pdo.ObjectType  in ('AnimalRelatedLiabilityExclusion','CanineLiabilityExclusion','ChangeInTermsSummary','CoverageBDetails',
										'ExtendedLiabilityLocation','Inspection','SpecificNamedStructuresPropertyAndLiabilityExclusion')  
		order by 1;
        */


		DROP TABLE IF EXISTS edw_temp.thome_coverage_ext_temp1;

		         SELECT
                    acct.IssuedDate, acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt,  
                     acct.PolicyChangeNumber as transaction_seq_no, 
                    acctvo.ObjectType as label, acctvof.Field, acctvof.Value 
                
                INTO edw_temp.thome_coverage_ext_temp1

                FROM edw_stage.AccountTransaction acct
                INNER JOIN edw_stage.Product AS p on p.Id = acct.ProductId
                INNER JOIN edw_stage.AccountTransactionVersion AS acctv ON acctv.AccountTransactionId = acct.Id
                INNER JOIN edw_stage.AccountTransactionVersionObject AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                INNER JOIN edw_stage.AccountTransactionVersionObjectField AS acctvof ON acctvof.VersionObjectId = acctvo.id 
                WHERE acct.State = 'ISSUED'
                    and acct.IssuedDate > @last_source_extract_ts
                    and p.name in ('Condo','Homeowners') 
                    AND p.ProductLine = 'PersonalLines'
                    AND acctvo.ObjectType  in ( 'AnimalRelatedLiabilityExclusion',
                                                'CanineLiabilityExclusion',
                                                'ChangeInTermsSummary',
                                                'CoverageBDetails',
                                                'ExtendedLiabilityLocation',
                                                'SpecificNamedStructuresPropertyAndLiabilityExclusion'
                                            ) ;
        
		
		-- Start Insert process
		INSERT INTO edw_stage.thome_coverage_ext
        (
            policy_no,
            effective_dt, 
            transaction_seq_no, 
            label,
            field,
            [value],             
            create_ts,
            update_ts,
            etl_audit_sk 
		)
        SELECT 
            t1.policy_no,
            t1.effective_dt, 
            t1.transaction_seq_no, 
            t1.label,
            t1.field,
            t1.value,  
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk 
        FROM 
            edw_temp.thome_coverage_ext_temp1 AS t1
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.thome_coverage_ext_temp1),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
        
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.thome_coverage_ext_temp1;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						    ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	
    END CATCH
END
