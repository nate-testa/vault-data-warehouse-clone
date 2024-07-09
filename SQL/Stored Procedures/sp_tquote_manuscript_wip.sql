-- ========================================================================================================================================
-- Description: This procedures insert and update info related to Quote Manuscript
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date 				|Author							|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 10/05/2024				Hernando Gonzalez Garcia		1. Created this procedure 
-- 05/16/2024				Architha Gudimalla 				2. Updated after errors 
-- 09/07/24					Yunus Mohammed					3. Use ValueBlob if Value field is null for manuscript_title an desc
-- ======================================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_manuscript_wip]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_manuscript_wip_temp1];
		SELECT 
			PolicyNumber as quote_no, EffectiveDate, ExpirationDate
			--,[Number] as transaction_seq_no
			,0 as transaction_seq_no
			,quote_history_sk
			,ManuscriptTitle, ManuscriptNumber, ManuscriptDescription
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
			,[Index] as manuscript_seq_no
		INTO [edw_temp].[tquote_manuscript_wip_temp1]
		FROM
			(
			SELECT
				acc.PolicyNumber, acc.EffectiveDate, acc.ExpirationDate, acc.[Number]
				,tqh.[quote_history_sk]
				,accof.[Field]
				,case
					when Field in ('ManuscriptDescription','ManuscriptTitle') and len(accto.[Value])= 0 then NULLIF(accto.[ValueBlob],'')
				else NULLIF(accto.[Value], '') end as [Value]
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
				,acc.CreatedDate,acc.UpdatedDate
				,acco.[Index]
			FROM
				(
				    SELECT *
				    FROM [edw_stage].[Account] AS a
				    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
				    AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
					AND a.PolicyNumber IS NOT NULL
				) acc
				INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
				inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
				inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
				INNER JOIN [edw_core].[tquote_history] tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = acc.number
			WHERE
				acco.ObjectType = 'Manuscript'
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN (ManuscriptTitle, ManuscriptNumber, ManuscriptDescription)
			) pivottable
			
		MERGE INTO [edw_core].[tquote_manuscript] AS TARGET
		USING (
		    SELECT
		        [quote_no],
		        [EffectiveDate] AS effective_dt,
		        [ExpirationDate] AS expiration_dt,
		        [transaction_seq_no],
		        [quote_history_sk],
		        [ManuscriptNumber] AS manuscript_no,
		        [ManuscriptTitle] AS manuscript_title,
		        [ManuscriptDescription] AS manuscript_desc,
		        [source_system_sk],
		        GETDATE() AS create_ts,
		        GETDATE() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk,
		        [manuscript_seq_no]
		    FROM
		        [edw_temp].[tquote_manuscript_wip_temp1]
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.expiration_dt = SOURCE.expiration_dt AND
		    TARGET.quote_history_sk = SOURCE.quote_history_sk

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.transaction_seq_no = SOURCE.transaction_seq_no,
		        TARGET.manuscript_no = SOURCE.manuscript_no,
		        TARGET.manuscript_title = SOURCE.manuscript_title,
		        TARGET.manuscript_desc = SOURCE.manuscript_desc,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.create_ts = SOURCE.create_ts,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk,
		        TARGET.manuscript_seq_no = SOURCE.manuscript_seq_no

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no,
		        effective_dt,
		        expiration_dt,
		        transaction_seq_no,
		        quote_history_sk,
		        manuscript_no,
		        manuscript_title,
		        manuscript_desc,
		        source_system_sk,
		        create_ts,
		        update_ts,
		        etl_audit_sk,
		        manuscript_seq_no
		    )
		    VALUES (
		        SOURCE.quote_no,
		        SOURCE.effective_dt,
		        SOURCE.expiration_dt,
		        SOURCE.transaction_seq_no,
		        SOURCE.quote_history_sk,
		        SOURCE.manuscript_no,
		        SOURCE.manuscript_title,
		        SOURCE.manuscript_desc,
		        SOURCE.source_system_sk,
		        SOURCE.create_ts,
		        SOURCE.update_ts,
		        SOURCE.etl_audit_sk,
		        SOURCE.manuscript_seq_no
		);

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(t1.CreatedDate, t1.UpdatedDate)) FROM edw_temp.[tquote_manuscript_wip_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_manuscript_wip_temp1];
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
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
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END