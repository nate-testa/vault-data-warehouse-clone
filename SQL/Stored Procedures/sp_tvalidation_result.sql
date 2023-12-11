-- =================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This procedures loads the vlidation result table
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 08/15/23		Architha Gudimalla				1. Created this procedure 
-- 11/03/23		Architha Gudimalla				2. Added date filter for inforce
-- 12/07/23		Architha Gudimalla				2. Updated var_actual_dt
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tvalidation_result]
@in_process_dt DATE = null
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
		sET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
	
		DECLARE c1_rec CURSOR
		FOR  
		select	validation_sql_sk,source_sql,target_sql,frequency_desc --select *
		from	edw_core.tvalidation_sql 
		WHERE	active_in='Y'
		order by 1;  

		DECLARE @validation_sql_sk int 
		DECLARE @source_ct int 
		DECLARE @target_ct int
		DECLARE @out1 int 
		DECLARE @out2 int 
		DECLARE @source_sql nVARCHAR(max)
		DECLARE @target_sql nVARCHAR(max)
		DECLARE @frequency_desc VARCHAR(255) 
		declare @process_run_start_ts datetime2  
		declare @i int  
		
		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @validation_sql_sk, @source_sql, @target_sql, @frequency_desc; 
		WHILE @@FETCH_STATUS = 0
			BEGIN   

				SET @out1 = 0; 
				SET @out2 = 0; 

				SET @process_run_start_ts = getdate(); 

				set @source_sql = replace(@source_sql , 'select count(','SELECT @source_ct=count(') 
				set @target_sql = replace(@target_sql , 'select count(','SELECT @target_ct=count(')  

				set @source_sql = replace(@source_sql , 'var_actual_dt',cast(getdate() as date)) 
				set @target_sql = replace(@target_sql , 'var_actual_dt',cast(getdate() as date)) 

				--set @source_sql = replace(@source_sql , 'var_actual_dt',@last_source_extract_ts) 
				--set @target_sql = replace(@target_sql , 'var_actual_dt',@last_source_extract_ts)  

				EXECUTE sp_executesql @source_sql, N'@source_ct NVARCHAR(10) OUTPUT', @source_ct=@out1 OUTPUT
				EXECUTE sp_executesql @target_sql, N'@target_ct NVARCHAR(10) OUTPUT', @target_ct=@out2 OUTPUT 

				set @out2 = case when @target_sql = 'select 0' then 0 else @out2 end 

				INSERT INTO edw_core.tvalidation_result
				(
					validation_sql_sk,process_run_start_ts,
					source_sql,target_sql,
					source_value,target_value
				)
				SELECT	@validation_sql_sk,@process_run_start_ts,
						replace(@source_sql,'@source_ct=',''), replace(@target_sql,'@target_ct=',''),
						@out1, @out2
				
				set  @i = @@IDENTITY; 
				
				UPDATE edw_core.tvalidation_result
				SET process_run_end_ts	= getdate(), 
					status_desc			= CASE WHEN source_value = target_value THEN 'Success' ELSE 'Failure' END
				WHERE @@IDENTITY = @i  
				; 
		       
				SET @rows_affected=@@ROWCOUNT;
		
				--Update control table
				SET @new_last_source_extract_ts = COALESCE(dateadd(day,-1,cast(getdate() as date)),@last_source_extract_ts);  
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		
				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) 
				EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;  
				 
				FETCH NEXT FROM c1_rec INTO @validation_sql_sk, @source_sql, @target_sql, @frequency_desc;
			END; 
		CLOSE c1_rec;
		DEALLOCATE c1_rec; 

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
