-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the daily policy holders data feed to Honk
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 08/07/25					Dinesh Bobbili			    1. Created this procedure
-- 08/08/25					Dinesh Bobbili			    2. Added logic to populate customer_nm as last_name for Entity
-- 08/08/25					Dinesh Bobbili			    3. Added logic to get data from tpolicy_insured
-- 08/14/25					Dinesh Bobbili			    4. Updated last_name logic
-- 10/09/25					Dinesh Bobbili			    5. Added logic to replace single and double quotes
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_honk_policyholder_feed]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.policy_honk_policyholder_feed_temp1;
		select policy_number	
			,first_name	
			,last_name	
			,address	
			,city	
			,state	
			,postal_code
		into edw_temp.policy_honk_policyholder_feed_temp1
		from (select distinct pol.policy_no as policy_number,
					REPLACE(REPLACE(pins.first_nm, '''', ''), '"', '')  as first_name,
					case when pins.insured_type = 'Entity' then isnull(REPLACE(REPLACE(pins.insured_nm, '''', ''), '"', ''), 'Unknown') 
					else isnull(REPLACE(REPLACE(pins.last_nm, '''', ''), '"', ''), isnull(REPLACE(REPLACE(pins.insured_nm, '''', ''), '"', ''), 'Unknown')) end as last_name,
					REPLACE(REPLACE(pins.mailing_address_line_1, '''', ''), '"', '') as address,
					REPLACE(REPLACE(pins.mailing_address_city_nm, '''', ''), '"', '') as city,
					REPLACE(REPLACE(pins.mailing_address_state_cd, '''', ''), '"', '') as state,
					pins.mailing_address_zip_cd as postal_code,
					row_number() over(partition by pins.policy_no,pins.effective_dt order by pins.transaction_seq_no desc) as rn
				from edw_core.tdaily_inforce_policy dip 
				inner join edw_core.tproduct pr 
					on dip.product_sk = pr.product_sk
					and pr.product_cd = 'AU'
				inner join edw_core.tpolicy pol 
					on dip.policy_sk = pol.policy_sk
				inner join edw_core.tpolicy_insured pins
					on pol.policy_no = pins.policy_no
					and pol.effective_dt = pins.effective_dt
				where dip.inforce_dt_sk = (select max(date_sk) from edw_core.tdate where actual_dt < cast(getdate() as date))
				and primary_insured_in = 'Yes'
		) a 
		where rn = 1;

		TRUNCATE TABLE edw_integration.policy_honk_policyholder_feed;
		-- Start Insert process
		INSERT INTO edw_integration.policy_honk_policyholder_feed (
			policy_number
			,first_name
			,last_name
			,address
			,city
			,state
			,postal_code
			,create_ts
			,update_ts
			,etl_audit_sk
		)
		SELECT 
			policy_number
			,first_name
			,last_name
			,address
			,city
			,state
			,postal_code
			,getdate()
			,getdate()
			,@etl_audit_sk
		FROM 
			edw_temp.policy_honk_policyholder_feed_temp1

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE(dateadd("dd",-1, cast(getdate() as date)),@last_source_extract_ts);
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added

		DROP TABLE IF EXISTS edw_temp.policy_honk_policyholder_feed_temp1;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END