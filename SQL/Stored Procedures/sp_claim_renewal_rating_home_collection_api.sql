SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 10/06/2023
-- Description: This procedures inserts and updates data for claim renewal rating for home and collection
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 10/06/2023		Mohammed Yunus				1. Created this procedure 
-- 01/08/2025		Rushin Shah					2. AD7660 - Added new columns
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_renewal_rating_home_collection_api]

AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF EXISTS edw_temp.claim_renewal_rating_home_collection_api_temp1

		SELECT DISTINCT
			CASE cl.product_sk
			WHEN 1 THEN 'Property'
			WHEN 2 THEN 'Liability'
			END AS PropertyOrLiability,
			cl.policy_no AS [PolicyNumber],
			cl.claim_no AS [FileNumber],
			cl.claim_status AS [ClaimStatus],
			NULL AS [Claimant],
			cl.loss_dt AS [LossDate],
			'Customer-Location Loss' AS [LossIdentifier],
			l.cause_of_loss_desc AS LossType,
			NULL AS [SubCauseOfLoss],
			cl.loss_desc AS [LossDescription],
			p.policy_term AS PolicyType,
			CASE
				WHEN cl.catastrophe_sk IS NOT NULL THEN 'Y'
			   ELSE 'N'
			END AS [CatIndicator],
			cat.catastrophe_nm as CatCode,
			cl.loss_address AS AddressLine1,
			NULL AS AddressLine2,
			NULL AS	AddressLineUnit,
			cl.loss_city_nm AS AddressCity,
			cl.loss_zip_cd AS AddressZipCode,
			cl.loss_state_cd AS	AddressState,
			NULL AS	 AddressCounty,
			CL.loss_country_nm AS AddressCountry,
			NULL AS Coverage,
			cl.expense_reserve_amt AS ReserveExpense,
			cl.loss_reserve_amt AS ReserveIndemnity,
			cl.expense_paid_amt AS PaidExpense,
			cl.loss_paid_amt AS PaidIndemnity,
			cl.source_of_fire as SourceOfFire,
			cl.source_of_water as SourceOfWater
		INTO edw_temp.claim_renewal_rating_home_collection_api_temp1
		FROM
			edw_core.tclaim cl
			inner join edw_core.tproduct tp on tp.product_sk=cl.product_sk
			LEFT JOIN edw_core.tcause_of_loss l on cl.cause_of_loss_sk = l.cause_of_loss_sk 
			--LEFT JOIN edw_core.tsub_cause_of_loss s on cl.sub_cause_of_loss_sk =s.sub_cause_of_loss_sk 
			Left join edw_core.tpolicy p on p.policy_no = cl.policy_no 
			left join edw_core.tcatastrophe cat on cat.catastrophe_sk=cl.catastrophe_sk
			INNER JOIN
			(
				SELECT 
					row_number() over(partition by claim_sk order by sum(clf.expense_reserve_amt + clf.loss_reserve_amt + clf.expense_paid_amt + clf.loss_paid_amt) desc) as row_no, 
				claim_sk,claim_coverage_desc
				FROM
					edw_core.tclaim_feature clf				
				group by claim_sk,claim_coverage_desc

			) cf on cf.claim_sk= cl.claim_sk and cf.row_no = 1
		WHERE
			cl.product_sk in(1,2)


	MERGE edw_integration.claim_renewal_rating_home_collection_api AS Target
	USING edw_temp.claim_renewal_rating_home_collection_api_temp1 AS Source
	ON Source.[FileNumber]=Target.[FileNumber]
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT
		(
			PropertyOrLiability,PolicyNumber,FileNumber,ClaimStatus,Claimant,LossDate,LossIdentifier,LossType,SubCauseOfLoss,
			LossDescription,PolicyType,CatIndicator,CatCode,AddressLine1,AddressLine2,AddressLineUnit,AddressCity,AddressZipCode,
			AddressState,AddressCounty,AddressCountry,Coverage,ReserveExpense,ReserveIndemnity,PaidExpense,PaidIndemnity,
			SourceOfFire,SourceOfWater,
			create_ts,update_ts,etl_audit_sk
		)
	VALUES
		(
			PropertyOrLiability,PolicyNumber,FileNumber,ClaimStatus,Claimant,LossDate,LossIdentifier,LossType,SubCauseOfLoss,
			LossDescription,PolicyType,CatIndicator,CatCode,AddressLine1,AddressLine2,AddressLineUnit,AddressCity,AddressZipCode,
			AddressState,AddressCounty,AddressCountry,Coverage,ReserveExpense,ReserveIndemnity,PaidExpense,PaidIndemnity,
			SourceOfFire,SourceOfWater,
			GETDATE(),GETDATE(),@etl_audit_sk
		)
	-- For Updates
	WHEN MATCHED THEN UPDATE 
	SET
		Target.PropertyOrLiability = Source.PropertyOrLiability,
		Target.PolicyNumber = Source.PolicyNumber,
		Target.ClaimStatus = Source.ClaimStatus,
		Target.Claimant = Source.Claimant,
		Target.LossDate = Source.LossDate,
		Target.LossIdentifier = Source.LossIdentifier,
		Target.LossType = Source.LossType,
		Target.SubCauseOfLoss = Source.SubCauseOfLoss,
		Target.LossDescription = Source.LossDescription,
		Target.PolicyType = Source.PolicyType,
		Target.CatIndicator = Source.CatIndicator,
		Target.CatCode = Source.CatCode,
		Target.AddressLine1 = Source.AddressLine1,
		Target.AddressLine2 = Source.AddressLine2,
		Target.AddressLineUnit = Source.AddressLineUnit,
		Target.AddressCity = Source.AddressCity,
		Target.AddressZipCode = Source.AddressZipCode,
		Target.AddressState = Source.AddressState,
		Target.AddressCounty = Source.AddressCounty,
		Target.AddressCountry = Source.AddressCountry,
		Target.Coverage = Source.Coverage,
		Target.ReserveExpense = Source.ReserveExpense,
		Target.ReserveIndemnity = Source.ReserveIndemnity,
		Target.PaidExpense = Source.PaidExpense,
		Target.PaidIndemnity = Source.PaidIndemnity,
		Target.SourceOfFire = Source.SourceOfFire,
		Target.SourceOfWater = Source.SourceOfWater,
		Target.update_ts = GETDATE();

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.claim_renewal_rating_home_collection_api_temp1;
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message
	END CATCH
END
GO
