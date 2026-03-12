-- ========================================================================================================================================
-- Description: This procedures inserts and updates quote grpel master coverage tier for WIP quotes
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date		|Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 03/06/26			Yunus Mohammed				1. Created this procedure
-- ======================================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_master_coverage_tier_wip]

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
		
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_tier_wip_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_tier_wip_temp2

		
		SELECT
            Id,PolicyNumber,EffectiveDate,0 as transaction_seq_no,ExpirationDate,CreatedDate,UpdatedDate,
            source_system_sk,
            LevelType as tier_type,
            NumberOfParticipatingMembers as no_of_participating_members
        into edw_temp.tquote_grpel_master_coverage_tier_wip_temp1
        from
        (
        select 
            acc.Id,acc.PolicyNumber,acc.EffectiveDate,
            acc.ExpirationDate,acc.CreatedDate,acc.UpdatedDate,
            case when acc.ExternalSourceId is not NULL 
                    then 2 --(AV2) 
                    Else 4 --(Metal)
            end source_system_sk,
            accof.Field,
            accof.[Value]
        from
            (
                SELECT a.*,p.ProductCode
                FROM [edw_stage].[Account] AS a
                inner join edw_stage.Product p on p.Id=a.ProductId and p.ProductLine = 'GroupPersonalLines' 
                WHERE 
                    NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
                    AND GREATEST(a.CreatedDate,a.UpdatedDate) > @last_source_extract_ts
                    AND a.PolicyNumber IS NOT NULL
            ) as acc
            inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
            inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
                and acco.ObjectType in ('Level')      
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
        into edw_temp.tquote_grpel_master_coverage_tier_wip_temp2
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
            acc.Id,
            accof.Field,
            accof.[Value]
            from
            edw_temp.tquote_grpel_master_coverage_tier_wip_temp1 as acc
            inner join edw_stage.AccountObject acco on acc.Id=acco.AccountId 
            and acco.ObjectType in ('LevelLimit')
            inner join edw_stage.AccountObjectField accof on acco.Id=accof.ObjectId
            ) as a
            group by Id
        ) a
        group by Id
		
        MERGE INTO [edw_core].[tquote_grpel_master_coverage_tier] AS Target
		USING (
		    select
			a.PolicyNumber as grpel_master_quote_no,gmc.quote_grpel_master_coverage_sk , a.EffectiveDate as effective_dt, 
            a.ExpirationDate as expiration_dt,
			a.transaction_seq_no,
            a.tier_type,a.no_of_participating_members,
            b.excess_liability_limit_min_amt,b.excess_liability_limit_max_amt,b.excess_liability_sponsored_amt,
            b.uninsured_underinsured_motorist_liability_limit_min_amt,b.uninsured_underinsured_motorist_liability_limit_max_amt,
            b.uninsured_underinsured_motorist_liability_limit_sponsored_amt,
            b.non_profit_do_liability_limit_min_amt,b.non_profit_do_liability_limit_max_amt,b.non_profit_do_liability_limit_sponsored_amt,
            b.employment_practices_liability_limit_min_amt,b.employment_practices_liability_limit_max_amt,b.employment_practices_liability_limit_sponsored_amt,
            b.family_trust_management_liability_limit_min_amt,b.family_trust_management_liability_limit_max_amt,
            b.family_trust_management_liability_limit_sponsored_amt,			
			a.source_system_sk,getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk
		from
			edw_temp.tquote_grpel_master_coverage_tier_wip_temp1 a
		    left join edw_temp.tquote_grpel_master_coverage_tier_wip_temp2 b on a.Id = b.Id
            left join edw_core.tquote_grpel_master_coverage gmc on gmc.grpel_master_quote_no = a.PolicyNumber 
                and gmc.effective_dt = a.EffectiveDate
                and gmc.transaction_seq_no = 0
		) AS source
		ON
		    TARGET.grpel_master_quote_no = source.grpel_master_quote_no AND
		    --TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = source.transaction_seq_no

		WHEN MATCHED THEN
		    UPDATE 
            SET               
                [Target].quote_grpel_master_coverage_sk = [Source].quote_grpel_master_coverage_sk,
                [Target].expiration_dt = [Source].expiration_dt,
                [Target].transaction_seq_no = [Source].transaction_seq_no,
                [Target].tier_type= [Source].tier_type,
                [Target].no_of_participating_members = [Source].no_of_participating_members,
                [Target].excess_liability_limit_min_amt = [Source].excess_liability_limit_min_amt,
                [Target].excess_liability_limit_max_amt = [Source].excess_liability_limit_max_amt,
                [Target].excess_liability_sponsored_amt = [Source].excess_liability_sponsored_amt,
                [Target].uninsured_underinsured_motorist_liability_limit_min_amt = [Source].uninsured_underinsured_motorist_liability_limit_min_amt,
                [Target].uninsured_underinsured_motorist_liability_limit_max_amt = [Source].uninsured_underinsured_motorist_liability_limit_max_amt,
                [Target].uninsured_underinsured_motorist_liability_limit_sponsored_amt = [Source].uninsured_underinsured_motorist_liability_limit_sponsored_amt,
                [Target].non_profit_do_liability_limit_min_amt = [Source].non_profit_do_liability_limit_min_amt,
                [Target].non_profit_do_liability_limit_max_amt = [Source].non_profit_do_liability_limit_max_amt,
                [Target].non_profit_do_liability_limit_sponsored_amt = [Source].non_profit_do_liability_limit_sponsored_amt,
                [Target].employment_practices_liability_limit_min_amt= [Source].employment_practices_liability_limit_min_amt,
                [Target].employment_practices_liability_limit_max_amt = [Source].employment_practices_liability_limit_max_amt,
                [Target].employment_practices_liability_limit_sponsored_amt = [Source].employment_practices_liability_limit_sponsored_amt,
                [Target].family_trust_management_liability_limit_min_amt = [Source].family_trust_management_liability_limit_min_amt,
                [Target].family_trust_management_liability_limit_max_amt = [Source].family_trust_management_liability_limit_max_amt,
                [Target].family_trust_management_liability_limit_sponsored_amt = [Source].family_trust_management_liability_limit_sponsored_amt,
                [Target].update_ts = [Source].update_ts
		    WHEN NOT MATCHED BY TARGET THEN
		    INSERT 
            (
                grpel_master_quote_no,quote_grpel_master_coverage_sk,effective_dt,expiration_dt,transaction_seq_no,
                tier_type,no_of_participating_members,
                excess_liability_limit_min_amt,excess_liability_limit_max_amt,excess_liability_sponsored_amt,
                uninsured_underinsured_motorist_liability_limit_min_amt,uninsured_underinsured_motorist_liability_limit_max_amt,
                uninsured_underinsured_motorist_liability_limit_sponsored_amt,
                non_profit_do_liability_limit_min_amt,non_profit_do_liability_limit_max_amt,non_profit_do_liability_limit_sponsored_amt,
                employment_practices_liability_limit_min_amt,employment_practices_liability_limit_max_amt,
                employment_practices_liability_limit_sponsored_amt,
                family_trust_management_liability_limit_min_amt,family_trust_management_liability_limit_max_amt,
                family_trust_management_liability_limit_sponsored_amt,
                source_system_sk,create_ts,update_ts,etl_audit_sk
		    )
		    VALUES (
                    source.grpel_master_quote_no,source.quote_grpel_master_coverage_sk, 
                    source.effective_dt, source.expiration_dt,source.transaction_seq_no,
                    source.tier_type,source.no_of_participating_members,
                    source.excess_liability_limit_min_amt,source.excess_liability_limit_max_amt,source.excess_liability_sponsored_amt,
                    source.uninsured_underinsured_motorist_liability_limit_min_amt,
                    source.uninsured_underinsured_motorist_liability_limit_max_amt,
                    source.uninsured_underinsured_motorist_liability_limit_sponsored_amt,
                    source.non_profit_do_liability_limit_min_amt,source.non_profit_do_liability_limit_max_amt,
                    source.non_profit_do_liability_limit_sponsored_amt,
                    source.employment_practices_liability_limit_min_amt,source.employment_practices_liability_limit_max_amt,
                    source.employment_practices_liability_limit_sponsored_amt,
                    source.family_trust_management_liability_limit_min_amt,source.family_trust_management_liability_limit_max_amt,
                    source.family_trust_management_liability_limit_sponsored_amt,

                    source.source_system_sk,create_ts,update_ts,etl_audit_sk
		);
        
		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_grpel_master_coverage_tier_wip_temp1 t2),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_tier_wip_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_tier_wip_temp2;
		
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