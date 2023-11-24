-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 11/23/2023
-- Description: This procedures update ebao claims into tclaim table (company and loss state cd)
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_ebao_tclaim_onetime_datafix]

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

		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= ''

		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C20HOA00085'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21AUA00167'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21HOA00167'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21HOA00284'
		Update edw_core.tclaim set underwriting_company_nm='Vault E&S Insurance Company' where claim_no='C22XLA00007'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C20AUA00061'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21AUA00129'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C20AUA00058'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21AUA00240'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21HOA00376'
		Update edw_core.tclaim set underwriting_company_nm='Vault E&S Insurance Company' where claim_no='C21HOA00377'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21AUA00226'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21HOA00416'

		UPDATE tc set tc.loss_state_cd= src.state_cd
		-- select tc.claim_sk,tc.claim_no,tc.loss_state_cd,src.state_cd
		from
		edw_core.tclaim tc
		inner join 
		(
			select
			ts.claim_sk,st.state_cd,
			case when st.state_sk is not null then st.state_cd
			else
			case ts.loss_state_cd
				when 'GA-GEORGIA' then 'GA'
				when 'WASHINGTON D.C.' then 'DC' 
				when 'TOMBALL' then 'TX'
				when '29466' then 'SC'
				when 'CT-CONNECTICUT' then 'CT'
				when 'TX-TEXAS' then 'TX'
				when 'MALVERN' then 'PA'
				when 'NJ-NEW JERSEY' then 'NJ'
				when '77057' then 'TX'
				when 'MOUNT PLEASANT' then 'SC'
				when 'PENNSYLVIANIA' then 'PA'
				when '33140' then 'FL'
				when 'S.C.' then 'SC'
				when 'TAMPA' then 'FL'
				when '33609' then 'FL'
				when 'Austin' then 'TX'
				when '75068' then 'TX'
				when 'DE/PA' then 'DE'
				when ', FL' then 'FL'
			end 
			end as loss_state_cd
		from
		(
			select distinct claim_sk, loss_state_cd from edw_core.tclaim 
			where datalength(loss_state_cd)>2
		) AS ts
		LEFT JOIN
		edw_core.tstate st
		on st.state_nm=ts.loss_state_cd
		) as src on tc.claim_sk = src.claim_sk
		where
		src.state_cd is not null

		SET @rows_affected=@@ROWCOUNT;	

		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tclaim_update_temp1

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;

	END CATCH
END