SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2023-09-29
-- Description: This stored procedure insert and update info related to policy_ivans_auto_feed.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_ivans_auto_feed]
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
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_auto_feed_temp1];
		SELECT 
            'PolicyDownload' as [MsgTypeCd_001],
            CASE 
                WHEN ptt.policy_transaction_type_nm = 'New' THEN 'NBS'
                WHEN ptt.policy_transaction_type_nm = 'Endorsement' THEN 'PCH'
                WHEN ptt.policy_transaction_type_nm = 'Cancellation' THEN 'XLC'
                WHEN ptt.policy_transaction_type_nm = 'Reinstatement' THEN 'REI'
                WHEN ptt.policy_transaction_type_nm = 'Renewal' THEN 'RW'
                ELSE 'OTH'
            END as [BusinessPurposeTypeCd_002],
            d2.actual_dt as [TransactionRequestDt_003],
            d1.actual_dt as [TransactionEffectiveDt_004],
            'USD' as [CurCd_005],
            'P' as [BroadLOBCd_006],
            '2.0' as [IVANSXMLVersionCd_007],
            'DWH2.0' as [SourceSystem_008],
            '' as [ActivityDt_009],
            p.broker_id as [ContractNumber_010],
            '' as [ProducerSubCode_011],
            c.customer_id as [InsurerId_012],
            c.last_nm as [Surname_013],
            c.first_nm as [GivenName_014],
            c.middle_nm as [OtherGivenName_015],
            c.title as [TitlePrefix_016],
            c.customer_nm as [CommercialName_100],
            CASE
                WHEN COALESCE(pi.mailing_address_line_1, p.mailing_address_line1) is null THEN ''
                ELSE 'MailingAddress' 
            END as [AddrTypeCd_017], 
            COALESCE(pi.mailing_address_line_1, p.mailing_address_line1) as [Addr1_018],
            COALESCE(pi.mailing_address_city_nm, p.mailing_address_city_nm) as [City_019], 
            COALESCE(pi.mailing_address_state_cd, p.mailing_address_state_cd) as [StateProvCd_020],
            COALESCE(pi.mailing_address_zip_cd, p.mailing_address_zip_cd) as [PostalCode_021],
            COALESCE(pi.mailing_address_country_nm, p.mailing_address_country_nm) as [Country_022],
            '' as [Latitude_023],
            '' as [Longitude_024],
            '' as [County_025],
            CASE
                WHEN pi.home_phone_no is not null THEN 'Home'
                WHEN pi.mobile_phone_no is not null THEN 'Mobile'
                ELSE ''
            END as [PhoneTypeCd_026],
            COALESCE(pi.home_phone_no, pi.mobile_phone_no, '') as [PhoneNumber_027],
            pi.email as [EmailAddr_028],
            CASE 
                WHEN pi.primary_insured_in = 'Yes' THEN 'Primary'
                ELSE ''
            END as [InsuredOrPrincipalRoleCd_029],
            CASE 
                WHEN pi.primary_insured_in = 'Yes' THEN 'Primary'
                ELSE ''
            END as [InsuredOrPrincipalRoleDesc_030],
            p.policy_no as [PolicyNumber_031],
            'P' as [BroadLOBCd_032],
            pr.product_nm as [LOBCd_033],
            CASE 
                WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '16186' 
                WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '16237' 
                ELSE '' 
            END as [NAICCd_034],
            p.effective_dt as [EffectiveDt_035],
            p.expiration_dt as [ExpirationDt_036],
            '' as [Dummy_037],
            '' as [Dummy_038],
            '****Pending****' as [BillingMethodCd_039],
            NULL as [Amt_040], --'****Pending****'
            pt.premium_amt as [Amt_041],
            'en' as [LanguageCd_042],
            op.min_effective_dt as [OriginalPolicyInceptionDt_043],
            '' as [Dummy_044],
            '' as [Dummy_045],
            '' as [Dummy_046],
            '' as [Dummy_047],
            '' as [Dummy_048],
            '' as [Dummy_049],
            '' as [Dummy_050],
            '' as [TotalPaidLossAmt_051],
            lh.loss_seq_no as [NumLosses_052],
            CASE
                WHEN p.prior_policy_no is not null AND p.prior_policy_no <> p.policy_no THEN 'Prior'
                ELSE ''
            END as [PolicyCd_053],
            CASE
                WHEN p.prior_policy_no is not null AND p.prior_policy_no <> p.policy_no THEN P.prior_policy_no
                ELSE ''
            END as [PolicyNumber_054],
            pr.product_nm as [LOBCd_055],
            CASE 
                WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '16186' 
                WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '16237' 
                ELSE '' 
            END as [NAICCd_056],
            op.min_effective_dt as [EffectiveDt_057],
            op.min_expiration_dt as [ExpirationDt_058],
            CASE 
                WHEN ba.payment_plan = '1P' THEN 'Full Pay'
                ELSE replace(ba.payment_plan, 'P', ' Pay')
            END AS [PaymentPlanCd_059],
            '' as [MethodPaymentCd_060],
            CASE 
                WHEN ba.payment_plan = '1P' THEN 'Y'
                WHEN ba.payment_plan is null OR ba.payment_method = '' THEN ''
                ELSE 'N'
            END AS [PaidInFullInd_061],
            '' as AU_Coverages,
            '' as AU_Vehicles,
            '' as AU_Drivers,
            '' as AU_Garaging_Locations,
            pt.transaction_seq_no,
            getdate() as create_ts,
            getdate() as update_ts,
            @etl_audit_sk as etl_audit_sk,
            pt.create_ts as policy_transaction_create_ts
        INTO [edw_temp].[policy_ivans_auto_feed_temp1] 
        FROM (
                SELECT DISTINCT policy_sk, transaction_seq_no, transaction_effective_dt_sk, transaction_dt_sk, customer_sk, policy_transaction_type_sk, source_system_sk, item_sk, create_ts, sum(premium_amt) as premium_amt
			    FROM edw_core.tpolicy_transaction
                WHERE product_sk = 3 --Auto
                GROUP BY policy_sk, transaction_seq_no, transaction_effective_dt_sk, transaction_dt_sk, customer_sk, policy_transaction_type_sk, source_system_sk, item_sk, create_ts
            ) AS pt
		INNER JOIN edw_core.tpolicy AS p ON pt.policy_sk = p.policy_sk
        LEFT JOIN edw_core.tpolicy_insured as pi ON p.policy_no = pi.policy_no AND p.effective_dt = pi.effective_dt AND pt.transaction_seq_no = pi.transaction_seq_no
		LEFT JOIN edw_core.tdate AS d1 ON pt.transaction_effective_dt_sk = d1.date_sk
        LEFT JOIN edw_core.tdate AS d2 ON pt.transaction_dt_sk = d2.date_sk
		LEFT JOIN edw_core.tcustomer AS c ON pt.customer_sk = c.customer_sk
		LEFT JOIN edw_core.tproduct AS pr ON p.product_cd = pr.product_cd
		LEFT JOIN edw_core.tpolicy_transaction_type AS ptt ON pt.policy_transaction_type_sk = ptt.policy_transaction_type_sk
        LEFT JOIN edw_core.tbillingaccount AS ba ON p.billingaccount_sk = ba.billingaccount_sk
        LEFT JOIN (
                    SELECT policy_no, effective_dt, transaction_seq_no, max(loss_seq_no) as loss_seq_no 
                    FROM edw_core.tloss_history
                    GROUP BY policy_no, effective_dt, transaction_seq_no
                ) AS lh ON p.policy_no = lh.policy_no AND p.effective_dt = lh.effective_dt AND pt.transaction_seq_no = lh.transaction_seq_no
        LEFT JOIN (
                    select original_policy_no, min(effective_dt) as min_effective_dt, min(expiration_dt) as min_expiration_dt 
                    from edw_core.tpolicy 
                    group by original_policy_no
                ) AS op ON p.original_policy_no = op.original_policy_no
		WHERE cast(pt.create_ts as datetime2(7)) > @last_source_extract_ts
        ;

        -- Start Insert process
        INSERT INTO [edw_integration].[policy_ivans_auto_feed](
            [MsgTypeCd_001],
            [BusinessPurposeTypeCd_002],
            [TransactionRequestDt_003],
            [TransactionEffectiveDt_004],
            [CurCd_005],
            [BroadLOBCd_006],
            [IVANSXMLVersionCd_007],
            [SourceSystem_008],
            [ActivityDt_009],
            [ContractNumber_010],
            [ProducerSubCode_011],
            [InsurerId_012],
            [Surname_013],
            [GivenName_014],
            [OtherGivenName_015],
            [TitlePrefix_016],
            [AddrTypeCd_017],
            [Addr1_018],
            [City_019],
            [StateProvCd_020],
            [PostalCode_021],
            [Country_022],
            [Latitude_023],
            [Longitude_024],
            [County_025],
            [PhoneTypeCd_026],
            [PhoneNumber_027],
            [EmailAddr_028],
            [InsuredOrPrincipalRoleCd_029],
            [InsuredOrPrincipalRoleDesc_030],
            [PolicyNumber_031],
            [BroadLOBCd_032],
            [LOBCd_033],
            [NAICCd_034],
            [EffectiveDt_035],
            [ExpirationDt_036],
            [Dummy_037],
            [Dummy_038],
            [BillingMethodCd_039],
            [Amt_040],
            [Amt_041],
            [LanguageCd_042],
            [OriginalPolicyInceptionDt_043],
            [Dummy_044],
            [Dummy_045],
            [Dummy_046],
            [Dummy_047],
            [Dummy_048],
            [Dummy_049],
            [Dummy_050],
            [TotalPaidLossAmt_051],
            [NumLosses_052],
            [PolicyCd_053],
            [PolicyNumber_054],
            [LOBCd_055],
            [NAICCd_056],
            [EffectiveDt_057],
            [ExpirationDt_058],
            [PaymentPlanCd_059],
            [MethodPaymentCd_060],
            [PaidInFullInd_061],
            [AU_Coverages],
            [AU_Vehicles],
            [AU_Drivers],
            [AU_Garaging_Locations],
            [transaction_seq_no],
            [create_ts],
            [update_ts],
            [etl_audit_sk]
        )
        SELECT 
            [MsgTypeCd_001],
            [BusinessPurposeTypeCd_002],
            [TransactionRequestDt_003],
            [TransactionEffectiveDt_004],
            [CurCd_005],
            [BroadLOBCd_006],
            [IVANSXMLVersionCd_007],
            [SourceSystem_008],
            [ActivityDt_009],
            [ContractNumber_010],
            [ProducerSubCode_011],
            [InsurerId_012],
            [Surname_013],
            [GivenName_014],
            [OtherGivenName_015],
            [TitlePrefix_016],
            [AddrTypeCd_017],
            [Addr1_018],
            [City_019],
            [StateProvCd_020],
            [PostalCode_021],
            [Country_022],
            [Latitude_023],
            [Longitude_024],
            [County_025],
            [PhoneTypeCd_026],
            [PhoneNumber_027],
            [EmailAddr_028],
            [InsuredOrPrincipalRoleCd_029],
            [InsuredOrPrincipalRoleDesc_030],
            [PolicyNumber_031],
            [BroadLOBCd_032],
            [LOBCd_033],
            [NAICCd_034],
            [EffectiveDt_035],
            [ExpirationDt_036],
            [Dummy_037],
            [Dummy_038],
            [BillingMethodCd_039],
            [Amt_040],
            [Amt_041],
            [LanguageCd_042],
            [OriginalPolicyInceptionDt_043],
            [Dummy_044],
            [Dummy_045],
            [Dummy_046],
            [Dummy_047],
            [Dummy_048],
            [Dummy_049],
            [Dummy_050],
            [TotalPaidLossAmt_051],
            [NumLosses_052],
            [PolicyCd_053],
            [PolicyNumber_054],
            [LOBCd_055],
            [NAICCd_056],
            [EffectiveDt_057],
            [ExpirationDt_058],
            [PaymentPlanCd_059],
            [MethodPaymentCd_060],
            [PaidInFullInd_061],
            [AU_Coverages],
            [AU_Vehicles],
            [AU_Drivers],
            [AU_Garaging_Locations],
            [transaction_seq_no],
            [create_ts],
            [update_ts],
            [etl_audit_sk]
        FROM [edw_temp].[policy_ivans_auto_feed_temp1];

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(policy_transaction_create_ts) FROM edw_temp.[policy_ivans_auto_feed_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[policy_ivans_auto_feed_temp1];

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
