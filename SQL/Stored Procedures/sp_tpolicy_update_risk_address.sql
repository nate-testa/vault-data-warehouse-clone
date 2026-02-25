-- =======================================================================================================================================================
-- Description: This procedure updates risk address for tpolicy
-------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
-------------------------------------------------------------------------------------------
-- 02/24/25		     Yunus Mohammed			    1. Created this procedure
-- ========================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_update_risk_address]
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
		DROP TABLE IF EXISTS edw_temp.tpolicy_update_risk_address_temp1
        
    select 
        p.policy_sk, p.update_ts,
        case
        when p.product_cd in ('HO','CO') then hl.address_line_1
        when p.product_cd in ('LUX')     then cl.address_line_1
        when p.product_cd in ('PEL')     then pl.address_line_1
        when p.product_cd in ('BY')      then mbyl.address_line_1
        when p.product_cd in ('AU')      then p.mailing_address_line1
        else NULL
        end risk_address_line_1
        ,case
        when p.product_cd in ('HO','CO') then hl.address_line_2
        when p.product_cd in ('LUX')     then cl.address_line_2
        when p.product_cd in ('PEL')     then pl.address_line_2
        when p.product_cd in ('BY')      then mbyl.address_line_2
        when p.product_cd in ('AU')      then p.mailing_address_line2
        else NULL
        end risk_address_line_2
        ,case
        when p.product_cd in ('HO','CO') then hl.unit_no
        when p.product_cd in ('LUX')     then cl.unit_no
        when p.product_cd in ('PEL')     then pl.unit_no
        when p.product_cd in ('BY')      then mbyl.unit_no
        when p.product_cd in ('AU')      then p.mailing_address_unit_no
        else NULL
        end risk_address_unit_no
        ,case
        when p.product_cd in ('HO','CO') then hl.city_nm
        when p.product_cd in ('LUX')     then cl.city_nm
        when p.product_cd in ('BY')      then mbyl.city_nm
        when p.product_cd in ('AU')      then p.mailing_address_city_nm
        else NULL
        end risk_address_city_nm
        ,case
        when p.product_cd in ('HO','CO') then hl.state_cd
        when p.product_cd in ('LUX')     then cl.state_cd
        when p.product_cd in ('PEL')     then pl.state_cd
        when p.product_cd in ('BY')      then mbyl.state_cd
        when p.product_cd in ('AU')      then p.mailing_address_state_cd
        else NULL
        end risk_address_state_cd
        ,case
        when p.product_cd in ('HO','CO') then hl.zip_cd
        when p.product_cd in ('LUX')     then cl.zip_cd
        when p.product_cd in ('PEL') then pl.zip_cd
        when p.product_cd in ('BY') then mbyl.zip_cd
        when p.product_cd in ('AU')  then p.mailing_address_zip_cd
        else NULL
        end risk_address_zip_cd
        ,case
        when p.product_cd in ('HO','CO') then hl.country_nm
        when p.product_cd in ('LUX')     then cl.country_nm
        when p.product_cd in ('PEL') then pl.country_nm
        when p.product_cd in ('BY') then mbyl.country_nm
        when p.product_cd in ('AU')  then p.mailing_address_country_nm
        else NULL
        end risk_address_country_nm
    into edw_temp.tpolicy_update_risk_address_temp1
    from
    edw_core.tpolicy p
    inner join edw_core.tpolicy_history ph on p.policy_sk = ph.policy_sk and ph.latest_transaction_in = 'Y'
    left join edw_core.thome_location hl on hl.policy_no = p.policy_no and hl.effective_dt = p.effective_dt
    left join edw_core.tpel_location pl ON pl.policy_history_sk = ph.policy_history_sk and pl.primary_location_in = 'Yes'
    LEFT JOIN edw_core.tcollection_location cl ON cl.policy_no = p.policy_no and cl.effective_dt = p.effective_dt
    LEFT JOIN edw_core.tmarine_boat_yacht_location mbyl ON mbyl.policy_history_sk = ph.policy_history_sk
    where
        ph.create_ts > @last_source_extract_ts

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
            edw_core.tpolicy [target]
            INNER JOIN edw_temp.tpolicy_update_risk_address_temp1 as [source] ON  [target].policy_sk = [source].policy_sk
        
		SET @rows_affected=@@ROWCOUNT; 
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.update_ts) FROM edw_temp.tpolicy_update_risk_address_temp1 t1),@last_source_extract_ts);		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;	

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 

        -- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tpolicy_update_risk_address_temp1
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

GO
