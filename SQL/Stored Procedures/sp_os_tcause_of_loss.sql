-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 11/08/2023
-- Description: This procedures insert OneShied cause of loss
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tcause_of_loss]

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
		-- SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		-- SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.os_tcause_of_loss_temp1

        SELECT *
        INTO edw_temp.os_tcause_of_loss_temp1
        FROM
        (
		SELECT 'OS_1' AS cause_of_loss_cd,'Water' as cause_of_loss_desc union
        SELECT 'OS_10' AS cause_of_loss_cd,'Theft/Break-in/Burglary' as cause_of_loss_desc union
        SELECT 'OS_11' AS cause_of_loss_cd,'Fire' as cause_of_loss_desc union
        SELECT 'OS_12' AS cause_of_loss_cd,'Equipment Breakdown' as cause_of_loss_desc union
        SELECT 'OS_13' AS cause_of_loss_cd,'Sinkhole' as cause_of_loss_desc union
        SELECT 'OS_14' AS cause_of_loss_cd,'Liability due to Injury or Death while on Insured Premises' as cause_of_loss_desc union
        SELECT 'OS_15' AS cause_of_loss_cd,'Lost stone' as cause_of_loss_desc union
        SELECT 'OS_16' AS cause_of_loss_cd,'Dwelling Damage' as cause_of_loss_desc union
        SELECT 'OS_17' AS cause_of_loss_cd,'Tornado' as cause_of_loss_desc union
        SELECT 'OS_18' AS cause_of_loss_cd,'Roadside Assistance' as cause_of_loss_desc union
        SELECT 'OS_19' AS cause_of_loss_cd,'Tropical Storm' as cause_of_loss_desc union
        SELECT 'OS_2' AS cause_of_loss_cd,'Windstorm' as cause_of_loss_desc union
        SELECT 'OS_20' AS cause_of_loss_cd,'Not at fault' as cause_of_loss_desc union
        SELECT 'OS_21' AS cause_of_loss_cd,'Fungi/ Mold' as cause_of_loss_desc union
        SELECT 'OS_22' AS cause_of_loss_cd,'Golf Cart/ ATV related accident' as cause_of_loss_desc union
        SELECT 'OS_23' AS cause_of_loss_cd,'Hurricane ' as cause_of_loss_desc union
        SELECT 'OS_24' AS cause_of_loss_cd,'Loss Assessment' as cause_of_loss_desc union
        SELECT 'OS_25' AS cause_of_loss_cd,'Car accident' as cause_of_loss_desc union
        SELECT 'OS_26' AS cause_of_loss_cd,'Liability due to Fall, Slip, or Trip on Insured''s Interior Premises' as cause_of_loss_desc union
        SELECT 'OS_27' AS cause_of_loss_cd,'Boat struck insured dock' as cause_of_loss_desc union
        SELECT 'OS_28' AS cause_of_loss_cd,'Explosion' as cause_of_loss_desc union
        SELECT 'OS_29' AS cause_of_loss_cd,'N/A' as cause_of_loss_desc union
        SELECT 'OS_3' AS cause_of_loss_cd,'Others' as cause_of_loss_desc union
        SELECT 'OS_30' AS cause_of_loss_cd,'Libel, Slander, Defamation of Character related liability' as cause_of_loss_desc union
        SELECT 'OS_31' AS cause_of_loss_cd,'Collapse' as cause_of_loss_desc union
        SELECT 'OS_32' AS cause_of_loss_cd,'Power Outage' as cause_of_loss_desc union
        SELECT 'OS_33' AS cause_of_loss_cd,'Water Leak' as cause_of_loss_desc union
        SELECT 'OS_34' AS cause_of_loss_cd,'Auto Accident' as cause_of_loss_desc union
        SELECT 'OS_35' AS cause_of_loss_cd,'Toilet supply line leaked' as cause_of_loss_desc union
        SELECT 'OS_36' AS cause_of_loss_cd,'Lost jewelry' as cause_of_loss_desc union
        SELECT 'OS_37' AS cause_of_loss_cd,'Roof leak' as cause_of_loss_desc union
        SELECT 'OS_38' AS cause_of_loss_cd,'Broken pipe in basement' as cause_of_loss_desc union
        SELECT 'OS_39' AS cause_of_loss_cd,'Dog bite liability' as cause_of_loss_desc union
        SELECT 'OS_4' AS cause_of_loss_cd,'Identity Theft' as cause_of_loss_desc union
        SELECT 'OS_5' AS cause_of_loss_cd,'Lightning' as cause_of_loss_desc union
        SELECT 'OS_6' AS cause_of_loss_cd,'Hail ' as cause_of_loss_desc union
        SELECT 'OS_7' AS cause_of_loss_cd,'Liability due to Fall, Slip, or Trip on Insured''s Exterior Premises' as cause_of_loss_desc union
        SELECT 'OS_8' AS cause_of_loss_cd,'roof and water leak' as cause_of_loss_desc union
        SELECT 'OS_9' AS cause_of_loss_cd,'Glass Breakage' as cause_of_loss_desc
        ) as temp

		INSERT INTO edw_core.tcause_of_loss
		(
			cause_of_loss_cd,cause_of_loss_desc,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT cause_of_loss_cd,cause_of_loss_desc,1 as source_system_sk,getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk
		FROM edw_temp.os_tcause_of_loss_temp1

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tcause_of_loss_temp1
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