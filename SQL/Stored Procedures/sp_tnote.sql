-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts and updates notes
-----------------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 03/22/24		    Yunus Mohammed				1. Created this procedure
-- 08/08/24         Yunus Mohammed              2. Update customer and broker joins
-- 06/04/24         Dinesh Bobbili              3. AZ9638 - Commercial changes
-- 07/04/24         Dinesh Bobbili              4. AZ9638 - changed db name from edw_core to edw_commercial
-- 07/04/24         Dinesh Bobbili              5. AZ11325 - included flagged_in in merge
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tnote]

AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF exists edw_temp.tnote_temp1;

        select
            nt.Id as note_id,
            case when tcq.quote_no is not null then tcq.quote_no else acc.policyNumber end as policy_no,
            nt.ObjectType as object_type,
            u.first_nm as user_first_nm,
            u.last_nm as user_last_nm,
            u.user_sk,
            nt.Content as note_desc,
            nt.CreatedDate as note_created_ts,
            nt.UpdatedDate as note_updated_ts,
            cust.customer_sk ,
            tbrk.broker_sk,
            prd.producer_sk,
            case
                when nt.IsExternallyShared = 0 then 'No'
                when nt.IsExternallyShared = 1 then 'Yes'
            end as externally_shared_in,
            case
                when nt.IsFlagged = 0 then 'No'
                when nt.IsFlagged = 1 then 'Yes'
            end as flagged_in,
            case when nt.ExternalSourceId is null then 4 else 2 end as source_system_sk
            into edw_temp.tnote_temp1
        from 
            edw_stage.Note nt
            left join edw_stage.WorkTask wt on wt.Id =case when nt.ObjectType IN('WorkTaskComment') then nt.ParentId end
            left join edw_stage.Account acc on acc.Id = 
            case
                when nt.ObjectType IN('Account','AccountClose','PendingNonRenewPolicy') then nt.ParentId
                when nt.ObjectType IN('WorkTaskComment') then wt.AccountId
                end
            left join edw_core.tuser u on u.[user_id] = nt.UserId
            left join edw_core.tquote tq on tq.quote_no = acc.PolicyNumber and tq.effective_dt = acc.EffectiveDate
            left join edw_commercial.tcommercial_quote tcq on tcq.quote_no = acc.number and tcq.effective_dt = acc.EffectiveDate
            left join edw_stage.Insured ins on ins.Id = case 
                                                            when nt.ObjectType = 'Insured' then nt.ParentId
                                                            when nt.ObjectType = 'WorkTaskComment' then wt.InsuredId
                                                        end
            left join edw_core.tcustomer cust on cust.customer_id = CASE
                                                                        when nt.ObjectType IN('Account','AccountClose','PendingNonRenewPolicy') and tq.customer_id is not null then tq.customer_id
                                                                        when nt.ObjectType IN('Account','AccountClose','PendingNonRenewPolicy') and tcq.customer_id is not null then tcq.customer_id
                                                                        when nt.ObjectType in ('Insured','WorkTaskComment') then cast(ins.ReferenceCode as varchar(255))
                                                                    END
            left join edw_stage.Brokerage brkg on brkg.Id = case 
                                                                when nt.ObjectType = 'Brokerage' then nt.ParentId
                                                                when nt.ObjectType = 'WorkTaskComment' then wt.BrokerageId
                                                            end            
            left join edw_core.tbroker tbrk on tbrk.broker_id = case					
                                                                    when nt.ObjectType IN('Account','AccountClose','PendingNonRenewPolicy') then tq.broker_id
                                                                    when nt.ObjectType in ('Brokerage','WorkTaskComment') then cast(brkg.ReferenceCode as varchar(255))													
                                                                end
            left join edw_core.tproducer prd on prd.producer_id = case when nt.ObjectType = 'Broker' then nt.ParentId end
        WHERE
			GREATEST(nt.UpdatedDate,nt.CreatedDate) > @last_source_extract_ts;

        MERGE edw_core.tnote AS Target
	    USING edw_temp.tnote_temp1 AS Source
	    ON Source.note_id=Target.note_id
	-- For Inserts
        WHEN NOT MATCHED BY Target THEN
        INSERT (
                policy_no,note_id ,object_type ,user_first_nm ,user_last_nm ,user_sk ,note_desc ,note_created_ts
                ,note_updated_ts ,customer_sk, broker_sk, producer_sk, externally_shared_in ,flagged_in, source_system_sk
                ,create_ts, update_ts,etl_audit_sk
           
            )
        VALUES
            (
            policy_no,note_id ,object_type ,user_first_nm ,user_last_nm ,user_sk ,note_desc ,note_created_ts,
            note_updated_ts, customer_sk, broker_sk, producer_sk, externally_shared_in ,flagged_in, source_system_sk,
            @current_date,@current_date,@etl_audit_sk
            )
	-- For Updates
	WHEN MATCHED THEN UPDATE 
	SET
		Target.note_desc=Source.note_desc,
        Target.note_updated_ts = Source.note_updated_ts,
        Target.update_ts = @current_date,
        Target.flagged_in = flagged_in;
		

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(note_updated_ts,note_created_ts)) FROM edw_temp.tnote_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tnote_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END