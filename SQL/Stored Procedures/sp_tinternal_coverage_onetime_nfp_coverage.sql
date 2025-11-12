-- =============================================================================================================
------------------------------------------------------------------------------------------------------------
-- Change date |Author						    |	Change Description
------------------------------------------------------------------------------------------------------------
-- 11/12/25	    Dinesh Bobbili          		1. Created this procedure 
-- ============================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tinternal_coverage_onetime_nfp_coverage]

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

        DROP TABLE IF EXISTS edw_temp.tinternal_coverage_onetime_nfp_coverage_temp1  
		
        select internal_coverage_cd,product_cd,internal_coverage_desc,aslob_cd,internal_coverage_category_nm,primary_coverage_cd
        into edw_temp.tinternal_coverage_onetime_nfp_coverage_temp1
        from
            (
           select 'Employment Practices Liability' as internal_coverage_cd,'GRPEL' as product_cd,'Employment Practices Liability' as internal_coverage_desc,171 as aslob_cd,'Premium' as internal_coverage_category_nm,'EPL Coverage' as primary_coverage_cd
        union
        select 'UM/UIM Motorist Liability' as  internal_coverage_cd,'GRPEL' as product_cd,'UM/UIM Motorist Liability' as internal_coverage_desc,171 as aslob_cd,'Premium' as internal_coverage_category_nm,'UM Motorist' as primary_coverage_cd
        union
        select 'Excess Liability' as internal_coverage_cd,'GRPEL' as product_cd,'Excess Liability' as internal_coverage_desc,171 as aslob_cd,'Premium' as internal_coverage_category_nm,'Excess Liability' as primary_coverage_cd
        union
        select 'Surplus Lines Tax' as internal_coverage_cd,'GRPEL' as product_cd,'Surplus Lines Tax' as internal_coverage_desc,171 as aslob_cd,'State Tax' as internal_coverage_category_nm,'State Tax' as primary_coverage_cd
        union
        select 'Program Administrator Fees' as  internal_coverage_cd,'GRPEL' as product_cd,'Program Administrator Fees' as internal_coverage_desc,171 as aslob_cd,'Fee' as internal_coverage_category_nm,'Fee' as primary_coverage_cd
      ) as t
            WHERE
            not exists
            (
                    select 1 from edw_core.tinternal_coverage c
                    where c.internal_coverage_cd = t.internal_coverage_cd
                    and c.product_cd = t.product_cd
            )

        insert into edw_core.tinternal_coverage
        (
        internal_coverage_cd,product_cd,internal_coverage_desc,aslob_cd,internal_coverage_category_nm,create_ts,update_ts,primary_coverage_cd
        )
		select internal_coverage_cd,product_cd,internal_coverage_desc,aslob_cd,internal_coverage_category_nm,
        GETDATE() as create_ts, GETDATE() as update_ts,primary_coverage_cd
        from edw_temp.tinternal_coverage_onetime_nfp_coverage_temp1 t    

		SET @rows_affected=@@ROWCOUNT;
		
        DROP TABLE IF EXISTS edw_temp.[tinternal_coverage_onetime_nfp_coverage_temp1]
	
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END