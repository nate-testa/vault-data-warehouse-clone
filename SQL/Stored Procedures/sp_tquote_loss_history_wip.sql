SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =================================================================================================
-- Description: This procedures inserts quote loss history wip
-----------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------
-- 05/09/24		        Yunus Mohammed			    1. Created the proc
-- 08/22/24				Yunus Mohammed				2. Removed effective date from merge and added in update clause
-- 01/15/25				Alberto Almario				3. Add include_in_rating_in column.
-- 02/05/25				Alberto Almario				4. Add new columns source_of_water, source_of_fire and include_in_rating_override_in.
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_loss_history_wip]
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
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) --20230717 added

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.tquote_loss_history_wip_temp1;
		SELECT 
			PolicyNumber as quote_no, EffectiveDate, ExpirationDate, [Number]
			,quote_history_sk
			,[index] as loss_seq_no
			,PropertyOrLiability, Source as source_nm, ClaimStatus, Claimant, FileNumber, LossDate, LossIdentifier, LossType, 
			SubCauseofLoss as sub_cause_of_loss, LossDescription, PolicyType, CatIndicator, Disputed,
			AddressLine1, AddressLine2, AddressLineUnit, AddressCity, AddressState, AddressZipCode, Coverage,
			ReserveIndemnity, ReserveExpense, PaidIndemnity, PaidExpense, TotalIncurred, IncludeInRating
			,SourceOfWater, SourceOfFire, IncludeInRatingOverride
			--,4 as source_system_sk --20230717 removed
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
		INTO edw_temp.tquote_loss_history_wip_temp1
		FROM
			(
			SELECT
				acc.PolicyNumber, acc.EffectiveDate, acc.ExpirationDate, acc.TransactionEffectiveDate as transaction_dt, 0 As [Number]
				,tqh.quote_history_sk as quote_history_sk
				,acco.[Index]
				,accof.Field, NULLIF(accof.Value, '') as Value
				,acc.CreatedDate, acc.UpdatedDate
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as source_system_sk --20230717 added
			FROM
				(SELECT
					acc.*
				FROM edw_stage.Account acc
				WHERE
					not exists (select * from edw_stage.AccountTransaction actr where actr.AccountId=acc.id)
					AND CreatedDate>@last_source_extract_ts --20230717 added
				) acc
				INNER JOIN edw_stage.Product p on p.Id = acc.ProductId
                INNER JOIN edw_stage.AccountObject AS acco ON acco.AccountId = acc.Id
                INNER JOIN edw_stage.AccountObjectField AS accof ON accof.ObjectId = acco.id
				LEFT JOIN edw_core.tquote_history tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = 0
			WHERE
				--p.Name='Collections'
				acco.ObjectType = 'LossHistory'
				--AND p.ProductLine='PersonalLines' --20230717 added
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (
					PropertyOrLiability, Source, ClaimStatus, Claimant, FileNumber, LossDate, LossIdentifier, LossType, SubCauseofLoss, 
					LossDescription, PolicyType, CatIndicator, Disputed, AddressLine1, AddressLine2, AddressLineUnit, AddressCity, AddressState, AddressZipCode, 
					Coverage, ReserveIndemnity, ReserveExpense, PaidIndemnity, PaidExpense, TotalIncurred, IncludeInRating
					,SourceOfWater, SourceOfFire, IncludeInRatingOverride
					)
			) pivottable

		MERGE edw_core.tquote_loss_history AS Target
		USING edw_temp.tquote_loss_history_wip_temp1 AS Source
		ON Target.quote_no = Source.quote_no and
		Target.transaction_seq_no = Source.Number and Source.loss_seq_no = Target.loss_seq_no
		WHEN NOT MATCHED BY Target THEN
		-- Start Insert process
		INSERT
        (
        quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,loss_seq_no,property_or_liability,source_nm
        ,claim_status,claimant_nm,file_no,loss_dt,loss_indentifier,type_of_loss,sub_cause_of_loss_desc,loss_desc,policy_type
        ,cat_loss_in,disputed_in,loss_address_line_1,loss_address_line_2,loss_address_unit_no,loss_address_city_nm,loss_address_state_cd
        ,loss_address_zip_cd,coverage_desc,indemnity_reserve_amt,expense_reserve_amt,indemnity_paid_amt,expense_paid_amt,total_incurred_amt
        ,source_system_sk,create_ts,update_ts,etl_audit_sk,include_in_rating_in
		,source_of_water,source_of_fire,include_in_rating_override_in
        )
        VALUES 
		(
		quote_no,EffectiveDate,ExpirationDate,[Number],quote_history_sk,loss_seq_no,PropertyOrLiability,Source_nm,ClaimStatus
        ,Claimant,FileNumber,LossDate,LossIdentifier,LossType,sub_cause_of_loss,LossDescription,PolicyType,CatIndicator
        ,Disputed,AddressLine1,AddressLine2,AddressLineUnit,AddressCity,AddressState,AddressZipCode,Coverage,ReserveIndemnity
        ,ReserveExpense,PaidIndemnity,PaidExpense,TotalIncurred
        ,source_system_sk,getdate(),getdate(),@etl_audit_sk
		,CASE 
			WHEN IncludeInRating = 'true' THEN 'Yes'
			WHEN IncludeInRating = 'false' THEN 'No'
			ELSE IncludeInRating
		END
		,SourceOfWater,SourceOfFire,IncludeInRatingOverride
		)
        WHEN MATCHED THEN UPDATE
		SET
		Target.effective_dt= Source.EffectiveDate,
		Target.expiration_dt = Source.ExpirationDate,
		Target.quote_history_sk = Source.quote_history_sk,
		Target.property_or_liability = Source.PropertyOrLiability,
		Target.source_nm =Source.Source_nm ,
		Target.claim_status = Source.ClaimStatus,
		Target.claimant_nm = Source.Claimant,
		Target.file_no = Source.FileNumber,
		Target.loss_dt = Source.LossDate,
		Target.loss_indentifier = Source.LossIdentifier,
		Target.type_of_loss = Source.LossType,
		Target.sub_cause_of_loss_desc = Source.sub_cause_of_loss,
		Target.loss_desc = Source.LossDescription,
		Target.policy_type = Source.PolicyType,
		Target.cat_loss_in = Source.CatIndicator,
		Target.disputed_in = Source.Disputed,
		Target.loss_address_line_1 = Source.AddressLine1,
		Target.loss_address_line_2 = Source.AddressLine2,
		Target.loss_address_unit_no = Source.AddressLineUnit,
		Target.loss_address_city_nm= Source.AddressCity,
		Target.loss_address_state_cd = Source.AddressState,
		Target.loss_address_zip_cd = Source.AddressZipCode,
		Target.coverage_desc = Source.Coverage,
		Target.indemnity_reserve_amt = Source.ReserveIndemnity,
		Target.expense_reserve_amt = Source.ReserveExpense,
		Target.indemnity_paid_amt = Source.PaidIndemnity,
		Target.expense_paid_amt = Source.PaidExpense,
		Target.total_incurred_amt = Source.TotalIncurred,
		Target.update_ts = GETDATE(),
		Target.include_in_rating_in = 	CASE 
											WHEN Source.IncludeInRating = 'true' THEN 'Yes'
											WHEN Source.IncludeInRating = 'false' THEN 'No'
											ELSE Source.IncludeInRating
										END
		,Target.source_of_water=Source.SourceOfWater
		,Target.source_of_fire=Source.SourceOfFire
		,Target.include_in_rating_override_in=Source.IncludeInRatingOverride
		;

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(t1.createddate,t1.createddate)) FROM edw_temp.tquote_loss_history_wip_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tquote_loss_history_wip_temp1;
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END
GO