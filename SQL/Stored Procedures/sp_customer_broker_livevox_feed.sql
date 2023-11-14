SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2023-11-14
-- Description: This stored procedure insert info related to customer_broker_livevox_feed.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_customer_broker_livevox_feed]
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

 		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[customer_broker_livevox_feed_temp1];

        WITH 
        max_prem_policy AS (
            SELECT 
                p.policy_no,
                p.product_cd as product,
                p.customer_id,
                p.latest_term_in,
                sum(coalesce(c.annual_premium_amt,0)) as premium_amt,
                ROW_NUMBER() OVER (partition by customer_id order by sum(coalesce(c.annual_premium_amt,0)) desc ) as rownum
            FROM vault_edw.edw_core.tpolicy_summary AS c 
            LEFT JOIN vault_edw.edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk 
            WHERE p.product_cd LIKE 'HO'
            GROUP BY
                p.policy_no,
                p.product_cd,
                p.customer_id,
                p.latest_term_in

            UNION 

            SELECT 
                p.policy_no,
                p.product_cd as product,
                p.customer_id,
                p.latest_term_in,
                sum(coalesce(c.annual_premium_amt,0)) as premium_amt,
                ROW_NUMBER() OVER (partition by customer_id order by sum(coalesce(c.annual_premium_amt,0)) desc ) as rownum
            FROM vault_edw.edw_core.tpolicy_summary AS c 
            LEFT JOIN vault_edw.edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk 
            WHERE p.product_cd LIKE 'PEL'
            GROUP BY
                p.policy_no,
                p.product_cd,
                p.customer_id,
                p.latest_term_in

            UNION 

            SELECT 
                p.policy_no,
                p.product_cd as product,
                p.customer_id,
                p.latest_term_in,
                sum(coalesce(c.annual_premium_amt,0)) as premium_amt,
                ROW_NUMBER() OVER (partition by customer_id order by sum(coalesce(c.annual_premium_amt,0)) desc ) as rownum
            FROM vault_edw.edw_core.tpolicy_summary AS c 
            LEFT JOIN vault_edw.edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk
            WHERE p.product_cd LIKE 'AU'
            GROUP BY
                p.policy_no,
                p.product_cd,
                p.customer_id,
                p.latest_term_in

            UNION 

            SELECT 
                p.policy_no as policy_no,
                p.product_cd as product,
                p.customer_id,
                p.latest_term_in,
                sum(coalesce(c.annual_premium_amt,0)) as premium_amt,
                ROW_NUMBER() OVER (partition by customer_id order by sum(coalesce(c.annual_premium_amt,0)) desc ) as rownum
            FROM vault_edw.edw_core.tpolicy_summary AS c 
            LEFT JOIN vault_edw.edw_core.tpolicy AS p ON p.policy_sk = c.policy_sk 
            WHERE p.product_cd LIKE 'LUX'
            GROUP BY
                p.policy_no,
                p.product_cd,
                p.customer_id,
                p.latest_term_in
        ),
        Home_policy_details AS (
            SELECT 
                mp.policy_no,
                h.address_line_1,
                p.effective_dt,
                p.expiration_dt,
                p.policy_status,
                mp.product,
                p.broker_id,
                b.broker_nm,
                p.customer_id 
            FROM vault_edw.edw_core.tpolicy AS p 
            LEFT JOIN vault_edw.edw_core.thome_location AS h ON p.policy_no = h.policy_no 
            LEFT JOIN max_prem_policy AS mp ON p.policy_no = mp.policy_no
            LEFT JOIN vault_edw.edw_core.tbroker AS b ON p.broker_id = b.broker_id 
            WHERE mp.rownum = 1
            and mp.product = 'HO'
        ),
        PEL_policy_details AS (
            SELECT 
                mp.policy_no,
                h.address_line_1,
                p.effective_dt,
                p.expiration_dt,
                p.policy_status,
                mp.product,
                p.broker_id,
                b.broker_nm,
                p.customer_id 
            FROM vault_edw.edw_core.tpolicy AS p 
            LEFT JOIN vault_edw.edw_core.tpel_location AS h ON p.policy_no = h.policy_no 
            LEFT JOIN max_prem_policy AS mp ON p.policy_no = mp.policy_no
            LEFT JOIN vault_edw.edw_core.tbroker AS b ON p.broker_id = b.broker_id 
            WHERE mp.rownum = 1
            and mp.product = 'PEL'
            and h.location_no =1
        ),
        LUX_policy_details AS (
            SELECT 
                mp.policy_no,
                h.address_line_1,
                p.effective_dt,
                p.expiration_dt,
                p.policy_status,
                mp.product,
                p.broker_id,
                b.broker_nm,
                p.customer_id 
            FROM vault_edw.edw_core.tpolicy AS p 
            LEFT JOIN vault_edw.edw_core.tcollection_location AS h ON p.policy_no = h.policy_no 
            LEFT JOIN max_prem_policy AS mp ON p.policy_no = mp.policy_no
            LEFT JOIN vault_edw.edw_core.tbroker AS b ON p.broker_id = b.broker_id 
            WHERE mp.rownum = 1
            and mp.product = 'LUX'
        ),
        AU_policy_details AS (
            SELECT 
                mp.policy_no,
                h.garage_address_line1 as address_line_1,
                p.effective_dt ,
                p.expiration_dt,
                p.policy_status,
                mp.product,
                p.broker_id,
                b.broker_nm,
                p.customer_id 
            FROM vault_edw.edw_core.tpolicy AS p 
            LEFT JOIN vault_edw.edw_core.tauto_garage_location AS h ON p.policy_no = h.policy_no 
            INNER JOIN max_prem_policy AS mp ON p.policy_no = mp.policy_no
            LEFT JOIN vault_edw.edw_core.tbroker AS b ON p.broker_id = b.broker_id 
            WHERE mp.rownum = 1
            and mp.product = 'AU'
        ),
        combined_pol_details AS (
            SELECT DISTINCT 
                mp.customer_id,
                hpd.policy_no as Policy_1,
                hpd.address_line_1 as Location_1,
                hpd.effective_dt as Effective_Date_1,
                hpd.expiration_dt as Expiration_Date_1,
                hpd.policy_status as Status_1,
                hpd.broker_id as Agency_Code_1,
                hpd.broker_nm as Legal_Entity_Name_1,
                ppd.policy_no as Policy_2,
                ppd.address_line_1 as Location_2,
                ppd.effective_dt as Effective_Date_2,
                ppd.expiration_dt as Expiration_Date_2,
                ppd.policy_status as Status_2,
                ppd.broker_id as Agency_Code_2,
                ppd.broker_nm as Legal_Entity_Name_2,
                apd.policy_no as Policy_3,
                apd.address_line_1 as Location_3,
                apd.effective_dt as Effective_Date_3,
                apd.expiration_dt as Expiration_Date_3,
                apd.policy_status as Status_3,
                apd.broker_id as Agency_Code_3,
                apd.broker_nm as Legal_Entity_Name_3,
                lpd.policy_no as Policy_4,
                lpd.address_line_1 as Location_4,
                lpd.effective_dt as Effective_Date_4,
                lpd.expiration_dt as Expiration_Date_4,
                lpd.policy_status as Status_4,
                lpd.broker_id as Agency_Code_4,
                lpd.broker_nm as Legal_Entity_Name_4
            FROM max_prem_policy AS mp
            LEFT JOIN Home_policy_details AS hpd ON mp.customer_id = hpd.customer_id
            LEFT JOIN PEL_policy_details AS ppd ON mp.customer_id = ppd.customer_id
            LEFT JOIN LUX_policy_details AS lpd ON hpd.customer_id = lpd.customer_id
            LEFT JOIN AU_policy_details AS apd ON hpd.customer_id = apd.customer_id
        ),
        final_query AS (
            SELECT DISTINCT 
                c.customer_id as [ID],
                c.mailing_address_line1 as [Address_1],
                c.mailing_address_line2 as [Address_2],
                c.mailing_address_city_nm as [City],
                c.mailing_address_state_cd as [State],
                c.mailing_address_zip_cd as [Zip_Code],
                NULL as [Do_Not_Contact],
                c.email as [Email_Address],
                c.first_nm as [First_Name],
                c.last_nm as [Last_Name],
                c.birth_dt as [DOB],
                NULL as [Payment_Balance],
                c.home_phone_no as [Phone_1],
                NULL as [Phone_1_SMS_Consent],
                c.mobile_phone_no as [Phone_2],
                NULL as [Phone_2_SMS_Consent],
                NULL as [Email_Consent],
                NULL as [SMS],
                NULL as [Legal_Entity_Name],
                NULL as [Brokerage_Type],
                NULL as [Broker_Name_Agent_Name],
                NULL as [Broker_Title_Status],
                NULL as [Broker_Phone], 
                NULL as [Broker_Email],
                c.vip_in as [VIP],
                cpd.Policy_1 as [Policy_1],
                cpd.Location_1 as [Location_1],
                cpd.Effective_Date_1 as [Effective_Date_1],
                cpd.Expiration_Date_1 as [Expiration_Date_1],
                cpd.Status_1 as [Status_1],
                cpd.Agency_Code_1 as [Agency_Code_1],
                cpd.Legal_Entity_Name_1 as [Legal_Entity_Name_1],
                cpd.Policy_2 as [Policy_2],
                cpd.Location_2 as [Location_2],
                cpd.Effective_Date_2 as [Effective_Date_2],
                cpd.Expiration_Date_2 as [Expiration_Date_2],
                cpd.Status_2 as [Status_2],
                cpd.Agency_Code_2 as [Agency_Code_2],
                cpd.Legal_Entity_Name_2 as [Legal_Entity_Name_2],
                cpd.Policy_3 as [Policy_3],
                cpd.Location_3 as [Location_3],
                cpd.Effective_Date_3 as [Effective_Date_3],
                cpd.Expiration_Date_3 as [Expiration_Date_3],
                cpd.Status_3 as [Status_3],
                cpd.Agency_Code_3 as [Agency_Code_3],
                cpd.Legal_Entity_Name_3 as [Legal_Entity_Name_3],
                cpd.Policy_4 as [Policy_4],
                cpd.Location_4 as [Location_4],
                cpd.Effective_Date_4 as [Effective_Date_4],
                cpd.Expiration_Date_4 as [Expiration_Date_4],
                cpd.Status_4 as [Status_4],
                cpd.Agency_Code_4 as [Agency_Code_4],
                cpd.Legal_Entity_Name_4 as [Legal_Entity_Name_4],
                'Customer' as [Contact_Type]
            FROM vault_edw.edw_core.tcustomer AS c 
            LEFT JOIN combined_pol_details AS cpd ON c.customer_id = cpd.customer_id
            WHERE c.insured_type = 'Individual'

            UNION

            SELECT DISTINCT 
                c.broker_id as [ID],
                c.primary_address_line_1 as [Address_1],
                c.primary_address_line_2 as [Address_2],
                c.primary_address_city_nm as [City],
                c.primary_address_state_cd as [State],
                c.primary_address_zip_cd as [Zip_Code],
                NULL as [Do_Not_Contact],
                c.broker_email as [Email_Address],
                NULL as [First_Name],
                NULL as [Last_Name],
                NULL as [DOB],
                NULL as [Payment_Balance],
                c.broker_phone_no as [Phone_1],
                NULL as [Phone_1_SMS_Consent],
                NULL as [Phone_2],
                NULL as [Phone_2_SMS_Consent],
                NULL as [Email_Consent],
                NULL as [SMS],
                c.broker_nm as [Legal_Entity_Name],
                c.broker_type as [Brokerage_Type],
                NULL as [Broker_Name_Agent_Name],
                c.broker_status as [Broker_Title_Status],
                NULL as [Broker_Phone],
                NULL as [Broker_Email],
                NULL as [VIP],
                NULL as [Policy_1],
                NULL as [Location_1],
                NULL as [Effective_Date_1],
                NULL as [Expiration_Date_1],
                NULL as [Status_1],
                NULL as [Agency_Code_1],
                NULL as [Legal_Entity_Name_1],
                NULL as [Policy_2],
                NULL as [Location_2],
                NULL as [Effective_Date_2],
                NULL as [Expiration_Date_2],
                NULL as [Status_2],
                NULL as [Agency_Code_2],
                NULL as [Legal_Entity_Name_2],
                NULL as [Policy_3],
                NULL as [Location_3],
                NULL as [Effective_Date_3],
                NULL as [Expiration_Date_3],
                NULL as [Status_3],
                NULL as [Agency_Code_3],
                NULL as [Legal_Entity_Name_3],
                NULL as [Policy_4],
                NULL as [Location_4],
                NULL as [Effective_Date_4],
                NULL as [Expiration_Date_4],
                NULL as [Status_4],
                NULL as [Agency_Code_4],
                NULL as [Legal_Entity_Name_4],
                'Agency' as [Contact_Type]
            FROM vault_edw.edw_core.tbroker c

            UNION 

            SELECT 
                CONCAT(c.broker_id,'-',p.email) as [ID],
                c.primary_address_line_1 as [Address_1],
                c.primary_address_line_2 as [Address_2],
                c.primary_address_city_nm as [City],
                c.primary_address_state_cd as [State],
                c.primary_address_zip_cd as [Zip_Code],
                NULL as [Do_Not_Contact],
                p.email as [Email_Address],
                p.first_nm as [First_Name],
                p.last_nm as [Last_Name],
                NULL as [DOB],
                NULL as [Payment_Balance],
                p.phone_no as [Phone_1],
                NULL as [Phone_1_SMS_Consent],
                NULL as [Phone_2],
                NULL as [Phone_2_SMS_Consent],
                NULL as [Email_Consent],
                NULL as [SMS],
                c.dba_nm as [Legal_Entity_Name],
                c.broker_type as [Brokerage_Type],
                NULL as [Broker_Name_Agent_Name],
                c.broker_status as [Broker_Title_Status],
                NULL as [Broker_Phone],
                NULL as [Broker_Email],
                NULL as [VIP],
                NULL as [Policy_1],
                NULL as [Location_1],
                NULL as [Effective_Date_1],
                NULL as [Expiration_Date_1],
                NULL as [Status_1],
                NULL as [Agency_Code_1],
                NULL as [Legal_Entity_Name_1],
                NULL as [Policy_2],
                NULL as [Location_2],
                NULL as [Effective_Date_2],
                NULL as [Expiration_Date_2],
                NULL as [Status_2],
                NULL as [Agency_Code_2],
                NULL as [Legal_Entity_Name_2],
                NULL as [Policy_3],
                NULL as [Location_3],
                NULL as [Effective_Date_3],
                NULL as [Expiration_Date_3],
                NULL as [Status_3],
                NULL as [Agency_Code_3],
                NULL as [Legal_Entity_Name_3],
                NULL as [Policy_4],
                NULL as [Location_4],
                NULL as [Effective_Date_4],
                NULL as [Expiration_Date_4],
                NULL as [Status_4],
                NULL as [Agency_Code_4],
                NULL as [Legal_Entity_Name_4],
                'Agency User' as [Contact_Type]
            FROM vault_edw.edw_core.tproducer AS p
            LEFT JOIN vault_edw.edw_core.tbroker AS c ON p.broker_id = c.broker_id 
        )

        SELECT DISTINCT * 
        INTO [edw_temp].[customer_broker_livevox_feed_temp1] 
        FROM final_query
        ;

        -- Start Insert process
        TRUNCATE TABLE [edw_integration].[customer_broker_livevox_feed]
        ;


        INSERT INTO [edw_integration].[customer_broker_livevox_feed](
            [ID],
            [Address_1],
            [Address_2],
            [City],
            [State],
            [Zip_Code],
            [Do_Not_Contact],
            [Email_Address],
            [First_Name],
            [Last_Name],
            [DOB],
            [Payment_Balance],
            [Phone_1],
            [Phone_1_SMS_Consent],
            [Phone_2],
            [Phone_2_SMS_Consent],
            [Email_Consent],
            [SMS],
            [Legal_Entity_Name],
            [Brokerage_Type],
            [Broker_Name_Agent_Name],
            [Broker_Title_Status],
            [Broker_Phone],
            [Broker_Email],
            [VIP],
            [Policy_1],
            [Location_1],
            [Effective_Date_1],
            [Expiration_Date_1],
            [Status_1],
            [Agency_Code_1],
            [Legal_Entity_Name_1],
            [Policy_2],
            [Location_2],
            [Effective_Date_2],
            [Expiration_Date_2],
            [Status_2],
            [Agency_Code_2],
            [Legal_Entity_Name_2],
            [Policy_3],
            [Location_3],
            [Effective_Date_3],
            [Expiration_Date_3],
            [Status_3],
            [Agency_Code_3],
            [Legal_Entity_Name_3],
            [Policy_4],
            [Location_4],
            [Effective_Date_4],
            [Expiration_Date_4],
            [Status_4],
            [Agency_Code_4],
            [Legal_Entity_Name_4],
            [Contact_Type],
            [create_ts],
            [update_ts],
            [etl_audit_sk]
        )
        SELECT 
            [ID],
            [Address_1],
            [Address_2],
            [City],
            [State],
            [Zip_Code],
            [Do_Not_Contact],
            [Email_Address],
            [First_Name],
            [Last_Name],
            [DOB],
            [Payment_Balance],
            [Phone_1],
            [Phone_1_SMS_Consent],
            [Phone_2],
            [Phone_2_SMS_Consent],
            [Email_Consent],
            [SMS],
            [Legal_Entity_Name],
            [Brokerage_Type],
            [Broker_Name_Agent_Name],
            [Broker_Title_Status],
            [Broker_Phone],
            [Broker_Email],
            [VIP],
            [Policy_1],
            [Location_1],
            [Effective_Date_1],
            [Expiration_Date_1],
            [Status_1],
            [Agency_Code_1],
            [Legal_Entity_Name_1],
            [Policy_2],
            [Location_2],
            [Effective_Date_2],
            [Expiration_Date_2],
            [Status_2],
            [Agency_Code_2],
            [Legal_Entity_Name_2],
            [Policy_3],
            [Location_3],
            [Effective_Date_3],
            [Expiration_Date_3],
            [Status_3],
            [Agency_Code_3],
            [Legal_Entity_Name_3],
            [Policy_4],
            [Location_4],
            [Effective_Date_4],
            [Expiration_Date_4],
            [Status_4],
            [Agency_Code_4],
            [Legal_Entity_Name_4],
            [Contact_Type],
            getdate() as create_ts,
            getdate() as update_ts,
            @etl_audit_sk as etl_audit_sk
        FROM [edw_temp].[customer_broker_livevox_feed_temp1];

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT getdate() FROM edw_temp.[customer_broker_livevox_feed_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[customer_broker_livevox_feed_temp1];

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
