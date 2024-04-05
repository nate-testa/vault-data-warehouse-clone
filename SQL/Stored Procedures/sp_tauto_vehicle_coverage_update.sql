-- =================================================================================================
-- Description: This procedures backfills motor_home_class for a few auto policies
---------------------------------------------------------------------------------------------------
-- Change date		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 4/5/2024			Rushin Shah					1. Created this procedure
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_temp].[sp_tauto_vehicle_coverage_update]

AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()

		-- Set last source extract date
		SET @last_source_extract_ts = '20170101'
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		update edw_core.tauto_vehicle_coverage set motor_home_class='A' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100127678-01' and vehicle_vin = '1F6NF53Y780A03737')
		update edw_core.tauto_vehicle_coverage set motor_home_class='C' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100209562-01' and vehicle_vin = '1FDXE4FS3ADA12942')
		update edw_core.tauto_vehicle_coverage set motor_home_class='A' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100055414-02' and vehicle_vin = '4VZBU1D9XFC079551')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100217737-01' and vehicle_vin = 'WD4FF4CDXKP180506')
		update edw_core.tauto_vehicle_coverage set motor_home_class='A' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100089896-02' and vehicle_vin = '2P9V33497S1001067')
		update edw_core.tauto_vehicle_coverage set motor_home_class='A' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100029343-03' and vehicle_vin = '4UZACGFC2KCKN2352')
		update edw_core.tauto_vehicle_coverage set motor_home_class='A' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100042763-02' and vehicle_vin = '1F66F5DN0M0A01248')
		update edw_core.tauto_vehicle_coverage set motor_home_class='Super C' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100206035-01' and vehicle_vin = '1HTWHAAT8DJ293991')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100170639-02' and vehicle_vin = 'W1X8ED3Y1LT042631')
		update edw_core.tauto_vehicle_coverage set motor_home_class='A' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100077598-02' and vehicle_vin = '4UZACGCY6GCHP4167')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100222247-02' and vehicle_vin = '3C6MRVJG8ME590341')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100088373-04' and vehicle_vin = 'W1W4EBVY0NP482033')
		update edw_core.tauto_vehicle_coverage set motor_home_class='A' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100091267-02' and vehicle_vin = '4CDR5E2XN23011920')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100114546-02' and vehicle_vin = 'W1X8E33Y2MN154919')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100041907-03' and vehicle_vin = 'WDZPE8CD2HP413294')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100074201-02' and vehicle_vin = 'WDAPF4CC8HP384710')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100144312-01' and vehicle_vin = 'W1X8ED3Y3LT022526')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100219173-01' and vehicle_vin = 'WD3FF4CC6FP142692')
		update edw_core.tauto_vehicle_coverage set motor_home_class='C' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100055607-02' and vehicle_vin = '1FDXE45S03HA48181')
		update edw_core.tauto_vehicle_coverage set motor_home_class='A' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100127678-01' and vehicle_vin = '4VZAT1C053394')
		update edw_core.tauto_vehicle_coverage set motor_home_class='B' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100192380-01' and vehicle_vin = '3C6URVJG1KE564998')
		update edw_core.tauto_vehicle_coverage set motor_home_class='Super C' where auto_vehicle_sk in (select auto_vehicle_sk from tauto_vehicle where policy_no = 'AU100204548-01' and vehicle_vin = 'WDB9490661V228771')

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update audit table
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