-- ========================================================================================================================================
-- Description: This procedures inserts and updates quote grpel master coverage tier
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date		|Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 03/06/26			Yunus Mohammed				1. Created this procedure
-- ======================================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_master_coverage_tier]

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
		DECLARE @CU DATETIME=GETDATE()
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));
		
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_tier_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_tier_temp2

		
		SELECT
            Id,PolicyNumber,EffectiveDate,[Number],ExpirationDate,CreatedDate,
            source_system_sk,
            LevelType as tier_type,
            NumberOfParticipatingMembers as no_of_participating_members
        into edw_temp.tquote_grpel_master_coverage_tier_temp1
        from
        (
        select 
            acct.Id,acct.PolicyNumber,acct.EffectiveDate,acct.[Number],
            acct.ExpirationDate,acct.[CreatedDate],
            case when acct.ExternalSourceId is not NULL 
                    then 2 --(AV2) 
                    Else 4 --(Metal)
            end source_system_sk,
            acctvof.Field,
            acctvof.[Value]
        from
            [edw_stage].[AccountTransaction] as acct
            inner join edw_stage.Product p on p.Id=acct.ProductId
            inner join edw_stage.AccountTransactionVersion acctv on acct.Id=acctv.AccountTransactionId
            inner join edw_stage.AccountTransactionVersionObject acctvo on acctv.Id=acctvo.AccountTransactionVersionId
            and acctvo.ObjectType in ('Level')
            inner join edw_stage.AccountTransactionVersionObjectField acctvof on acctvo.Id=acctvof.VersionObjectId
        where
            acct.PolicyNumber is not null and
            acct.[State] in ('QUOTE','POLICY')
            and p.ProductLine = 'GroupPersonalLines'
            AND acct.CreatedDate>@last_source_extract_ts
        ) as a
        PIVOT 
        (
        MAX(Value) FOR Field IN 
        (
            LevelType,NumberOfParticipatingMembers
        )
        ) pivottable

        select
            Id,
            max(case when LimitType = 'UMLiabilityLimit' then MinValue end) as uninsured_underinsured_motorist_liability_limit_min_amt,
            max(case when LimitType = 'UMLiabilityLimit' then MaxValue end) as uninsured_underinsured_motorist_liability_limit_max_amt,
            max(case when LimitType = 'UMLiabilityLimit' then SponsoredValue end) as uninsured_underinsured_motorist_liability_limit_sponsored_amt,

            max(case when LimitType = 'ExcessLiabilityLimit' then MinValue end) as excess_liability_limit_min_amt,
            max(case when LimitType = 'ExcessLiabilityLimit' then MaxValue end) as excess_liability_limit_max_amt,
            max(case when LimitType = 'ExcessLiabilityLimit' then SponsoredValue end) as excess_liability_sponsored_amt,

            max(case when LimitType = 'FTMLiabilityLimit' then MinValue end) as family_trust_management_liability_limit_min_amt,
            max(case when LimitType = 'FTMLiabilityLimit' then MaxValue end) as family_trust_management_liability_limit_max_amt,
            max(case when LimitType = 'FTMLiabilityLimit' then SponsoredValue end) as family_trust_management_liability_limit_sponsored_amt,

            max(case when LimitType = 'DOLiabilityLimit' then MinValue end) as non_profit_do_liability_limit_min_amt,
            max(case when LimitType = 'DOLiabilityLimit' then MaxValue end) as non_profit_do_liability_limit_max_amt,
            max(case when LimitType = 'DOLiabilityLimit' then SponsoredValue end) as non_profit_do_liability_limit_sponsored_amt,

            max(case when LimitType = 'EMPLiabilityLimit' then MinValue end) as employment_practices_liability_limit_min_amt,
            max(case when LimitType = 'EMPLiabilityLimit' then MaxValue end) as employment_practices_liability_limit_max_amt,
            max(case when LimitType = 'EMPLiabilityLimit' then SponsoredValue end) as employment_practices_liability_limit_sponsored_amt
        into edw_temp.tquote_grpel_master_coverage_tier_temp2
        from

        (
            select 
                Id,
                max(case when Field = 'Limit' then [Value] end) as LimitType,
                max(case when Field = 'Min' then [Value] end) as MinValue,
                max(case when Field = 'Max' then [Value] end) as MaxValue,
                max(case when Field = 'Sponsored' then [Value] end) as SponsoredValue
            from
            (
            select 
            acct.Id,
            acctvof.Field,
            acctvof.[Value]
            from
            edw_temp.tquote_grpel_master_coverage_tier_temp1 as acct
            inner join edw_stage.AccountTransactionVersion acctv on acct.Id=acctv.AccountTransactionId
            inner join edw_stage.AccountTransactionVersionObject acctvo on acctv.Id=acctvo.AccountTransactionVersionId 
            and acctvo.ObjectType in ('LevelLimit')
            inner join edw_stage.AccountTransactionVersionObjectField acctvof on acctvo.Id=acctvof.VersionObjectId   

            ) as a
            group by Id
        ) a
        group by Id
		
		INSERT INTO [edw_core].[tquote_grpel_master_coverage_tier]
		(
		grpel_master_quote_no,quote_grpel_master_coverage_sk,effective_dt,expiration_dt,transaction_seq_no,
        tier_type,no_of_participating_members,
        excess_liability_limit_min_amt,excess_liability_limit_max_amt,excess_liability_sponsored_amt,
        uninsured_underinsured_motorist_liability_limit_min_amt,uninsured_underinsured_motorist_liability_limit_max_amt,uninsured_underinsured_motorist_liability_limit_sponsored_amt,
        non_profit_do_liability_limit_min_amt,non_profit_do_liability_limit_max_amt,non_profit_do_liability_limit_sponsored_amt,
        employment_practices_liability_limit_min_amt,employment_practices_liability_limit_max_amt,employment_practices_liability_limit_sponsored_amt,
        family_trust_management_liability_limit_min_amt,family_trust_management_liability_limit_max_amt,family_trust_management_liability_limit_sponsored_amt,
		source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		select
			a.PolicyNumber as grpel_master_quote_no,gmc.quote_grpel_master_coverage_sk , a.EffectiveDate as effective_dt,
            a.ExpirationDate as expiration_dt,a.[Number] as transaction_dt,
            a.tier_type,a.no_of_participating_members,
            b.excess_liability_limit_min_amt,b.excess_liability_limit_max_amt,b.excess_liability_sponsored_amt,
            b.uninsured_underinsured_motorist_liability_limit_min_amt,b.uninsured_underinsured_motorist_liability_limit_max_amt,b.uninsured_underinsured_motorist_liability_limit_sponsored_amt,
            b.non_profit_do_liability_limit_min_amt,b.non_profit_do_liability_limit_max_amt,b.non_profit_do_liability_limit_sponsored_amt,
            b.employment_practices_liability_limit_min_amt,b.employment_practices_liability_limit_max_amt,b.employment_practices_liability_limit_sponsored_amt,
            b.family_trust_management_liability_limit_min_amt,b.family_trust_management_liability_limit_max_amt,b.family_trust_management_liability_limit_sponsored_amt,
			
			a.source_system_sk,getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk
		from
			edw_temp.tquote_grpel_master_coverage_tier_temp1 a
		    left join edw_temp.tquote_grpel_master_coverage_tier_temp2 b on a.Id = b.Id
            left join edw_core.tquote_grpel_master_coverage gmc on gmc.grpel_master_quote_no = a.PolicyNumber and gmc.effective_dt = a.EffectiveDate
                and gmc.transaction_seq_no = a.[Number]

		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t2.CreatedDate) FROM edw_temp.tquote_grpel_master_coverage_tier_temp1 t2),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_tier_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_tier_temp2;
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;


		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
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