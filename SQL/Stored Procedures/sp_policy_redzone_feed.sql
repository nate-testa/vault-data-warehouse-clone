SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2024-07-17
-- Description: This stored procedure insert info related to policy_redzone_feed.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_redzone_feed]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT = NULL
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
		DROP TABLE IF EXISTS [edw_temp].[policy_redzone_feed_temp0];
        DROP TABLE IF EXISTS [edw_temp].[policy_redzone_feed_temp1];
        DROP TABLE IF EXISTS [edw_temp].[policy_redzone_feed_temp2];
        

        --HO Data
        SELECT	 
            '' as unique_id, 
            pol.policy_no, 
            pr.product_nm, 		
            loc.[latitude], 
            loc.[longitude], 
            trim(trim(loc.[address_line_1] || ' ' || isnull(loc.[address_line_2],'')) || ' ' || isnull(loc.[unit_no],'')) as address_line,
            loc.[city_nm], 
            loc.[county_nm], 
            loc.[state_cd], 
            loc.[zip_cd],
            cov.[total_insured_value_amt] as total_insured_value_amt,
            ins.insured_nm, 
            isnull(ins.mobile_phone_no, ins.home_phone_no) as ins_ph_no, 
            ins.email as ins_email,
            br.[broker_id], 
            br.[broker_nm], 
            br.[broker_phone_no], 
            br.[broker_email],
            cov.[dwelling_limit_amt] as dwelling_limit_amt, 
            cov.[other_structures_limit_amt] as other_structures_limit_amt, 
            cov.[contents_limit_amt] as contents_limit_amt, 
            round(
                case 
                    when cov.[dwelling_limit_amt]> 0 then cov.[dwelling_limit_amt]*cov.loss_of_use_derived_pc
                    else cov.[contents_limit_amt]*cov.loss_of_use_derived_pc 
                end
                ,0) as cov_d,
            '' as gate_code,
            @current_date AS create_ts,
            @current_date AS update_ts,
            @etl_audit_sk AS etl_audit_sk
        INTO [edw_temp].[policy_redzone_feed_temp0]
        FROM edw_core.titem_inforce AS summ	
        INNER JOIN edw_core.tdate AS td ON td.date_sk = summ.month_sk		
        INNER JOIN edw_core.thome_coverage AS cov ON summ.coverage_sk = cov.home_coverage_sk		
        INNER JOIN edw_core.thome_location AS loc ON summ.item_sk = loc.home_location_sk		
        INNER JOIN edw_core.tpolicy AS pol ON summ.policy_sk = pol.policy_sk		
        INNER JOIN edw_core.tproduct AS pr ON summ.product_sk = pr.product_sk		
        INNER JOIN edw_core.tbroker AS br ON summ.broker_sk = br.broker_sk		
        LEFT JOIN edw_core.tpolicy_insured AS ins ON summ.policy_history_sk = ins.policy_history_sk AND ins.primary_insured_in = 'Yes'		
        WHERE pr.product_cd = 'HO'
        AND td.yearmonth = (select max(yearmonth) from edw_core.tdate where actual_dt < cast(getdate() as date))
        ;


        --Collection Data
        WITH 
        coll_limit AS
            (
                SELECT
                    summ.policy_sk, summ.item_sk, summ.policy_history_sk, summ.broker_sk, pr.product_nm,
                    SUM(ISNULL(ct.scheduled_limit_amt,0) + ISNULL(ct.blanket_limit_amt,0)) as total_limit
                FROM edw_core.tinternal_coverage_inforce AS summ
                INNER JOIN edw_core.tdate AS td ON td.date_sk = summ.month_sk
                INNER JOIN edw_core.tproduct AS pr ON summ.product_sk = pr.product_sk
                INNER JOIN edw_core.tcollection_class_type AS ct ON ct.collection_class_type_sk = summ.collection_class_type_sk
                WHERE pr.product_cd = 'LUX'
                AND summ.collection_class_type_sk <> 0
                AND td.yearmonth = (select max(yearmonth) from edw_core.tdate where actual_dt < cast(getdate() as date))
                GROUP BY summ.policy_sk, summ.item_sk, summ.policy_history_sk, summ.broker_sk, pr.product_nm
            )

        SELECT 
            '' as unique_id,
            pol.policy_no,
            coll_limit.product_nm,
            loc.[latitude],
            loc.[longitude],
            trim(trim(loc.[address_line_1] || ' ' || isnull(loc.[address_line_2],'')) || ' ' || isnull(loc.[unit_no],'')) as address_line,
            loc.[city_nm],
            loc.[county_nm],
            loc.[state_cd],
            loc.[zip_cd],
            CAST(coll_limit.total_limit AS BIGINT) as tiv,
            ins.insured_nm,
            isnull(ins.mobile_phone_no, ins.home_phone_no) as ins_ph_no,
            ins.email as ins_email,
            br.[broker_id],
            br.[broker_nm],
            br.[broker_phone_no],
            br.[broker_email],
            CAST(0 AS BIGINT) as cov_a,
            CAST(0 AS BIGINT) as cov_b,
            CAST(0 AS BIGINT) as cov_c,
            CAST(0 AS BIGINT) as cov_d,
            '' as gate_code,
            @current_date as create_ts,
            @current_date as update_ts,
            @etl_audit_sk as etl_audit_sk
        INTO [edw_temp].[policy_redzone_feed_temp2]
        FROM coll_limit
        INNER JOIN edw_core.tcollection_location AS loc ON coll_limit.item_sk = loc.collection_location_sk
        INNER JOIN edw_core.tpolicy AS pol ON coll_limit.policy_sk = pol.policy_sk
        INNER JOIN edw_core.tbroker AS br ON coll_limit.broker_sk = br.broker_sk
        LEFT JOIN edw_core.tpolicy_insured AS ins ON coll_limit.policy_history_sk = ins.policy_history_sk AND ins.primary_insured_in = 'Yes'


        --Union HO and Collection data
        SELECT * 
        INTO [edw_temp].[policy_redzone_feed_temp1]
        FROM (
            SELECT * FROM [edw_temp].[policy_redzone_feed_temp0]
            UNION ALL
            SELECT * FROM [edw_temp].[policy_redzone_feed_temp2]
        ) AS tbl
        ;


        -- Delete target table
        DELETE FROM [edw_integration].[policy_redzone_feed];

        -- Start Insert process
        INSERT INTO [edw_integration].[policy_redzone_feed](
             [unique_id]
            ,[policy_id]
            ,[policy_type]
            ,[latitude]
            ,[longitude]
            ,[address]
            ,[city]
            ,[county]
            ,[state]
            ,[zip]
            ,[tiv]
            ,[insured_name]
            ,[insured_phone]
            ,[insured_email]
            ,[broker_id]
            ,[broker_name]
            ,[broker_phone]
            ,[broker_email]
            ,[coverage_a]
            ,[coverage_b]
            ,[coverage_c]
            ,[coverage_d]
            ,[gate_code]
            ,[create_ts]
            ,[update_ts]
            ,[etl_audit_sk]
        )
        SELECT 
            unique_id, 
            policy_no, 
            product_nm, 		
            latitude, 
            longitude, 
            address_line,
            city_nm, 
            county_nm, 
            state_cd, 
            zip_cd,
            total_insured_value_amt,
            insured_nm, 
            ins_ph_no, 
            ins_email,
            broker_id, 
            broker_nm, 
            broker_phone_no, 
            broker_email,
            dwelling_limit_amt, 
            other_structures_limit_amt, 
            contents_limit_amt, 
            cov_d,
            gate_code,
            [create_ts],
            [update_ts],
            [etl_audit_sk]
        FROM [edw_temp].[policy_redzone_feed_temp1];

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		-- SET @new_last_source_extract_ts=COALESCE((SELECT MAX(filter_dt) FROM edw_temp.[policy_redzone_feed_temp1]),@last_source_extract_ts);
        -- EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[policy_redzone_feed_temp0];
        DROP TABLE IF EXISTS [edw_temp].[policy_redzone_feed_temp1];
        DROP TABLE IF EXISTS [edw_temp].[policy_redzone_feed_temp2];

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
