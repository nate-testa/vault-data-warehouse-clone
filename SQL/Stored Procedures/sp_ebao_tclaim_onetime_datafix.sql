-- =============================================
-- Author:		Yunus Mohammed
-- Description: This procedures update ebao claims into tclaim table (company and loss state cd)
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/23/23		Yunus Mohammed				1. Created this procedure 
-- 11/27/23		Yunus Mohammed				2. Added update stmt to update company nm
-- 01/03/24		Yunus Mohammed				3. Updated VRE and VES in update statement
-- 01/24/24		Yunus Mohammed				4. Updated policy no and policy_sk for given claims in task-4480
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_ebao_tclaim_onetime_datafix]

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

		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= ''

		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C20HOA00085'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21AUA00167'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21HOA00167'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21HOA00284'
		Update edw_core.tclaim set underwriting_company_nm='Vault E&S Insurance Company' where claim_no='C22XLA00007'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C20AUA00061'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21AUA00129'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C20AUA00058'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21AUA00240'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21HOA00376'
		Update edw_core.tclaim set underwriting_company_nm='Vault E&S Insurance Company' where claim_no='C21HOA00377'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21AUA00226'
		Update edw_core.tclaim set underwriting_company_nm='Vault Reciprocal Exchange' where claim_no='C21HOA00416'

		UPDATE edw_core.tclaim
		SET
		underwriting_company_nm = CASE underwriting_company_nm
									WHEN 'Vault Reciprocal Exchange' THEN 'VRE'
									WHEN 'Vault E&S Insurance Company' THEN 'VES'
									ELSE
										underwriting_company_nm
									END
		WHERE
		source_system_sk=3

		UPDATE tc set tc.loss_state_cd= src.loss_state_cd
		-- select tc.claim_sk,tc.claim_no,tc.loss_state_cd,src.loss_state_cd
		from
		edw_core.tclaim tc
		inner join 
		(
			select
			ts.claim_sk,st.state_cd,
			case when st.state_sk is not null then st.state_cd
			else
			case ts.loss_state_cd
				when 'GA-GEORGIA' then 'GA'
				when 'WASHINGTON D.C.' then 'DC' 
				when 'TOMBALL' then 'TX'
				when '29466' then 'SC'
				when 'CT-CONNECTICUT' then 'CT'
				when 'TX-TEXAS' then 'TX'
				when 'MALVERN' then 'PA'
				when 'NJ-NEW JERSEY' then 'NJ'
				when '77057' then 'TX'
				when 'MOUNT PLEASANT' then 'SC'
				when 'PENNSYLVIANIA' then 'PA'
				when '33140' then 'FL'
				when 'S.C.' then 'SC'
				when 'TAMPA' then 'FL'
				when '33609' then 'FL'
				when 'Austin' then 'TX'
				when 'HOBOKEN' then 'NJ'
				when '75068' then 'TX'
				when 'DE/PA' then 'DE'
				when ', FL' then 'FL'
				when ', TX' then 'TX'
			end 
			end as loss_state_cd
		from
		(
			select distinct claim_sk, loss_state_cd from edw_core.tclaim 
			where datalength(loss_state_cd)>2
		) AS ts
		LEFT JOIN
		edw_core.tstate st
		on st.state_nm=ts.loss_state_cd
		) as src on tc.claim_sk = src.claim_sk
		where
		src.loss_state_cd is not null

		-- Task-4480
		UPDATE edw_core.tclaim SET policy_no = '9102103 215801A' WHERE claim_no = 'C20HOA00085'
		UPDATE edw_core.tclaim SET policy_no = '9100155 176001B' WHERE claim_no = 'C21AUA00129'
		UPDATE edw_core.tclaim SET policy_no = '9100834 123701A' WHERE claim_no = 'C21AUA00169'
		UPDATE edw_core.tclaim SET policy_no = '9102980 363901A' WHERE claim_no = 'C21AUA00277'
		UPDATE edw_core.tclaim SET policy_no = '9103318 415901A' WHERE claim_no = 'C21AUA00288'
		UPDATE edw_core.tclaim SET policy_no = '9102975 363101A' WHERE claim_no = 'C21AUA00303'
		UPDATE edw_core.tclaim SET policy_no = '9102922 355101A' WHERE claim_no = 'C21AUA00339'
		UPDATE edw_core.tclaim SET policy_no = '9103298 412901A' WHERE claim_no = 'C21AUA00410'
		UPDATE edw_core.tclaim SET policy_no = '9102307 256901A' WHERE claim_no = 'C21AUA00416'
		UPDATE edw_core.tclaim SET policy_no = '9100587 802001B' WHERE claim_no = 'C21AUA00461'
		UPDATE edw_core.tclaim SET policy_no = 'AUX10000860' WHERE claim_no = 'C21AUA00240'
		UPDATE edw_core.tclaim SET policy_no = '9103250 406001A' WHERE claim_no = 'C21AUA00532'
		UPDATE edw_core.tclaim SET policy_no = '9100833 123601B' WHERE claim_no = 'C21AUA00645'
		UPDATE edw_core.tclaim SET policy_no = 'AUX10003952-01' WHERE claim_no = 'C21AUA00717'
		UPDATE edw_core.tclaim SET policy_no = 'AUX10001740' WHERE claim_no = 'C21AUA00721'
		UPDATE edw_core.tclaim SET policy_no = 'HO100009103' WHERE claim_no = 'C21HOA00135'
		UPDATE edw_core.tclaim SET policy_no = 'HO100033995-01' WHERE claim_no = 'C21HOA00284'
		UPDATE edw_core.tclaim SET policy_no = 'AUX10001238' WHERE claim_no = 'C22AUA00263'
		UPDATE edw_core.tclaim SET policy_no = 'HO37788288836-03' WHERE claim_no = 'C22HOA00025'

		-- Update policy_sk for the above claims
		UPDATE tc
		SET
			tc.policy_sk = tph.policy_sk,
			tc.policy_history_sk=tph.policy_history_sk
		FROM
			edw_core.tclaim tc
			LEFT JOIN edw_core.tpolicy_history tph ON 
				tph.policy_history_sk = (
								SELECT TOP 1 policy_history_sk
								FROM
									edw_core.tpolicy_history tph1
								WHERE
									tph1.policy_no = tc.policy_no
									AND CAST(tph1.transaction_effective_dt AS DATE) <= tc.loss_dt
								ORDER BY transaction_seq_no DESC
								)
		where
			tc.claim_no in 
		(
		'C20HOA00085','C21AUA00129','C21AUA00169','C21AUA00277','C21AUA00288','C21AUA00303','C21AUA00339',
		'C21AUA00410','C21AUA00416','C21AUA00461','C21AUA00240','C21AUA00532','C21AUA00645',
		'C21AUA00717','C21AUA00721','C21HOA00135','C21HOA00284','C22AUA00263','C22HOA00025'
		)

		-- For below claims there are some special character in policy_no field in tcase table and we have to remove them.
		UPDATE tc
		SET
			tc.policy_sk = tph.policy_sk,
			tc.policy_no = tph.policy_no,
			tc.policy_history_sk=tph.policy_history_sk
		FROM
			edw_stage.t_clm_case tcase
			INNER JOIN edw_core.tclaim tc on tcase.CLAIM_NO = tc.claim_no
			LEFT JOIN edw_core.tpolicy_history tph ON 
				tph.policy_history_sk = (
								SELECT TOP 1 policy_history_sk
								FROM
									edw_core.tpolicy_history tph1
								WHERE
									tph1.policy_no = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(tcase.policy_no, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32))))
									AND CAST(tph1.transaction_effective_dt AS DATE) <= CAST(tcase.accident_time AS DATE)
								ORDER BY transaction_seq_no DESC
								)
		where
			tcase.claim_no  in 
			(
			'C20AUA00029','C21AUA00133','C21AUA00136','C21AUA00149','C21AUA00490','C21AUA00247','C21AUA00535','C21HOA00585',
			'C22AUA00156','C22AUA00620','C22AUA00650','C22AUA00661','C22AUA00997','C22HOA00192','C22HOA00245','C22HOA00456'
			)


		UPDATE [tctxn]
		SET
			[tctxn].policy_sk = [tc].policy_sk
		FROM
			edw_core.tclaim [tc]
			INNER JOIN edw_core.tclaim_transaction [tctxn] ON [tc].claim_sk = [tctxn].claim_sk
		WHERE
			tc.claim_no in
			(
			'C20AUA00029','C21AUA00133','C21AUA00136','C21AUA00149','C21AUA00490','C21AUA00247','C21AUA00535','C21HOA00585',
			'C22AUA00156','C22AUA00620','C22AUA00650','C22AUA00661','C22AUA00997','C22HOA00192','C22HOA00245','C22HOA00456',
			'C20HOA00085','C21AUA00129','C21AUA00169','C21AUA00277','C21AUA00288','C21AUA00303','C21AUA00339',
			'C21AUA00410','C21AUA00416','C21AUA00461','C21AUA00240','C21AUA00532','C21AUA00645',
			'C21AUA00717','C21AUA00721','C21HOA00135','C21HOA00284','C22AUA00263','C22HOA00025'
			)
		SET @rows_affected=@@ROWCOUNT;	

		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tclaim_update_temp1

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