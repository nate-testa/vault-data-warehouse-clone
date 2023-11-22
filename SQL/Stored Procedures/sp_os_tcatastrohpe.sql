-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 11/08/2023
-- Description: This procedures insert OneShield catastrophe
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tcatastrohpe]

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

		INSERT INTO edw_core.tcatastrophe
		(catastrophe_cd, catastrophe_nm, catastrophe_desc, source_system_sk, create_ts, update_ts, etl_audit_sk)
		VALUES('1744', 'Hurricane Irma (09.06.17 - 09.07.17)', 'DATES: September 6, 2017 To September 7, 2017 ---- STATES: Puerto Rico, U.S. Virgin Islands, and Possibly Other Areas ---- PERILS: Flooding, Hurricane, Wind ---- STORM FAMILY: Hurricane Irma', 1, 
		getdate(), getdate(), @etl_audit_sk);

		INSERT INTO edw_core.tcatastrophe
		(catastrophe_cd, catastrophe_nm, catastrophe_desc, source_system_sk, create_ts, update_ts, etl_audit_sk)
		VALUES('1857', 'Hurricane Michael (10.10.18 - 10.10.18)', 'DATES: October 10, 2018 To October 10, 2018 ---- STATES: Alabama, Florida, Georgia, and Possibly Other Areas ---- PERILS: Flooding, Hurricane, Wind ---- STORM FAMILY: Hurricane Michael', 1, 
		getdate(), getdate(), @etl_audit_sk);

		INSERT INTO edw_core.tcatastrophe
		(catastrophe_cd, catastrophe_nm, catastrophe_desc, source_system_sk, create_ts, update_ts, etl_audit_sk)
		VALUES('2020', 'Wind and Thunderstorm Event (04.10.20 - 04.12.20)', 'DATES: April 10, 2020 To April 12, 2020 ---- STATES: Kansas, Nebraska, Oklahoma, Texas, and Possibly Other Areas ---- PERILS: Flooding, Hail, Wind ---- STORM FAMILY: Wind and Thunderstorm Event', 1, 
		getdate(), getdate(), @etl_audit_sk);

		INSERT INTO edw_core.tcatastrophe
		(catastrophe_cd, catastrophe_nm, catastrophe_desc, source_system_sk, create_ts, update_ts, etl_audit_sk)
		VALUES('2063', 'Hurricane Sally (09.14.20 - 09.15.20)', 'DATES: September 14, 2020 To September 15, 2020 ---- STATES: Alabama, Florida, Louisiana, Mississippi, and Possibly Other Areas ---- PERILS: Flooding, Hurricane, Wind ---- STORM FAMILY: Hurricane Sally', 1, 
		getdate(), getdate(), @etl_audit_sk);

		INSERT INTO edw_core.tcatastrophe
		(catastrophe_cd, catastrophe_nm, catastrophe_desc, source_system_sk, create_ts, update_ts, etl_audit_sk)
		VALUES('MAJ-19', 'COVID (03.11.20 - 02.28.21)', 'DATES: March 11, 2020 To February 28, 2021 ---- STATES: All ---- PERILS: NA ---- STORM FAMILY: NA', 1, 
		getdate(), getdate(), @etl_audit_sk);
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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