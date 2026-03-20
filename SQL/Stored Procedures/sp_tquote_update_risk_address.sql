-- =======================================================================================================================================================
-- Description: This procedure updates risk address for tquote
-------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
-------------------------------------------------------------------------------------------
-- 02/26/25		     Yunus Mohammed			    1. Created this procedure
-- 03/20/26          Yununs Mohammed            2. AD-12872 Added risk_adress_city_nm for PEL policies
-- ========================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_update_risk_address]
AS 
BEGIN
	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

        -- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_update_risk_address_temp1
        
        select 
                q.quote_sk, qh.create_ts,
                case
                when q.product_cd in ('HO','CO') then qhl.address_line_1
                when q.product_cd in ('LUX')     then qcl.address_line_1
                when q.product_cd in ('PEL')     then qpl.address_line_1
                when q.product_cd in ('BY')      then qmbyl.address_line_1
                when q.product_cd in ('AU')      then q.mailing_address_line1
                else NULL
                end risk_address_line_1
                ,case
                when q.product_cd in ('HO','CO') then qhl.address_line_2
                when q.product_cd in ('LUX')     then qcl.address_line_2
                when q.product_cd in ('PEL')     then qpl.address_line_2
                when q.product_cd in ('BY')      then qmbyl.address_line_2
                when q.product_cd in ('AU')      then q.mailing_address_line2
                else NULL
                end risk_address_line_2
                ,case
                when q.product_cd in ('HO','CO') then qhl.unit_no
                when q.product_cd in ('LUX')     then qcl.unit_no
                when q.product_cd in ('PEL')     then qpl.unit_no
                when q.product_cd in ('BY')      then qmbyl.unit_no
                when q.product_cd in ('AU')      then q.mailing_address_unit_no
                else NULL
                end risk_address_unit_no
                ,case
                when q.product_cd in ('HO','CO') then qhl.city_nm
                when q.product_cd in ('LUX')     then qcl.city_nm
                when q.product_cd in ('PEL')     then qpl.city_nm
                when q.product_cd in ('BY')      then qmbyl.city_nm
                when q.product_cd in ('AU')      then q.mailing_address_city_nm
                else NULL
                end risk_address_city_nm
                ,case
                when q.product_cd in ('HO','CO') then qhl.state_cd
                when q.product_cd in ('LUX')     then qcl.state_cd
                when q.product_cd in ('PEL')     then qpl.state_cd
                when q.product_cd in ('BY')      then qmbyl.state_cd
                when q.product_cd in ('AU')      then q.mailing_address_state_cd
                else NULL
                end risk_address_state_cd
                ,case
                when q.product_cd in ('HO','CO') then qhl.zip_cd
                when q.product_cd in ('LUX')     then qcl.zip_cd
                when q.product_cd in ('PEL') then qpl.zip_cd
                when q.product_cd in ('BY') then qmbyl.zip_cd
                when q.product_cd in ('AU')  then q.mailing_address_zip_cd
                else NULL
                end risk_address_zip_cd
                ,case
                when q.product_cd in ('HO','CO') then qhl.country_nm
                when q.product_cd in ('LUX')     then qcl.country_nm
                when q.product_cd in ('PEL') then qpl.country_nm
                when q.product_cd in ('BY') then qmbyl.country_nm
                when q.product_cd in ('AU')  then q.mailing_address_country_nm
                else NULL
                end risk_address_country_nm
            into edw_temp.tquote_update_risk_address_temp1
            from
            edw_core.tquote q
            inner join edw_core.tquote_history qh on q.quote_sk = qh.quote_sk and qh.latest_transaction_in = 'Y'
            left join edw_core.tquote_home_location qhl on qhl.quote_no = q.quote_no and qhl.effective_dt = q.effective_dt
            left join edw_core.tquote_pel_location qpl ON qpl.quote_history_sk = qh.quote_history_sk and qpl.primary_location_in = 'Yes'
            LEFT JOIN edw_core.tquote_collection_location qcl ON qcl.quote_no = q.quote_no and qcl.effective_dt = q.effective_dt
            LEFT JOIN edw_core.tquote_marine_boat_yacht_location qmbyl ON qmbyl.quote_history_sk = qh.quote_history_sk
            where
                qh.create_ts > @last_source_extract_ts

        UPDATE [target]
        SET
            [target].risk_address_line_1 = [source].risk_address_line_1,
            [target].risk_address_line_2 =  [source].risk_address_line_2,
            [target].risk_address_unit_no =  [source].risk_address_unit_no,
            [target].risk_address_city_nm =  [source].risk_address_city_nm,
            [target].risk_address_state_cd=  [source].risk_address_state_cd,
            [target].risk_address_zip_cd = [source].risk_address_zip_cd,
            [target].risk_address_country_nm = [source].risk_address_country_nm
        FROM
            edw_core.tquote [target]
            INNER JOIN edw_temp.tquote_update_risk_address_temp1 as [source] ON  [target].quote_sk = [source].quote_sk
        
		SET @rows_affected=@@ROWCOUNT; 
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.create_ts) FROM edw_temp.tquote_update_risk_address_temp1 t1),@last_source_extract_ts);		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;	

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 

        -- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_update_risk_address_temp1
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