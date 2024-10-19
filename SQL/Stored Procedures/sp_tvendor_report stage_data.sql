/****** Object:  StoredProcedure [edw_core].[sp_tvendor_report_stage_data]    Script Date: 5/8/2024 11:56:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =======================================================================================================================
-- Author:	Architha Gudimalla		
-- Description: This procedures loads vendor reports data
------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
------------------------------------------------------------------------------------------------------------------------
-- 11/28/23		Architha Gudimalla				1. Created this procedure  
-- 03/10/23		Architha Gudimalla				2. Updated the label in merge
-- 03/10/24		Architha Gudimalla				3. Updated the label with replace for some too long labels for LC360
-- 05/08/24		Architha Gudimalla				4. Updated the label for another long label for LC360
-- 05/20/24		Architha Gudimalla				5. Added accri.Label = accri.[Group] to table main case statement
-- 05/28/24		Architha Gudimalla				6. Updated the label for another long label for LC360
-- 06/11/24		Architha Gudimalla				7. Updated the label for another long label for LC360
-- 06/12/24		Architha Gudimalla				8. Excluded null label for LC360
-- 09/21/24		Architha Gudimalla				9. Updated the label for another long label for LC360
-- 10/09/24		Architha Gudimalla				10. Updated to left join for insert into @tablename_main
-- 10/09/24		Architha Gudimalla				11. Added new column - IsReportFromCache
-- 10/17/24		Architha Gudimalla				12. Updated logic for IsReportFromCache
-- ======================================================================================================================= 

CREATE OR ALTER       PROCEDURE [edw_core].[sp_tvendor_report_stage_data]
@in_source varchar(255) = null
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
	SET ANSI_WARNINGS OFF
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) 
		DECLARE @tablename_main NVARCHAR(MAX)=''
		declare @sql nvarchar(max) 

		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		set @parameter_desc = 'Source=' + @in_source + '; '
		SET @parameter_desc= @parameter_desc + 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
				
				
		print @last_source_extract_ts

		SET @rows_affected=0; 

		/*delete from edw_stage.tvendor_report_field
		where UpdatedDate > @last_source_extract_ts 
		--and source = @in_source
		;

		insert into edw_stage.tvendor_report_field
				(source, reporttype, Category, [Group], Label, CreatedDate, UpdatedDate) 
		select  accr.source, accr.reporttype, accri.Category, accri.[Group], accri.Label, 
					max(accri.CreatedDate) CreatedDate, max(GREATEST(accri.UpdatedDate,accri.CreatedDate)) UpdatedDate 
		from	edw_stage.Account acc, edw_stage.AccountReport accr, edw_stage.AccountReportItem accri
		where	accr.AccountId=acc.Id  
		and		accr.Id =accri.ReportId 
		AND		GREATEST(accri.UpdatedDate,accri.CreatedDate)>@last_source_extract_ts
		--and 	accr.source = @in_source
		group by accr.source, accr.reporttype, accri.Category, accri.[Group], accri.Label;*/

		merge into edw_stage.tvendor_report_field as target
		using
		(
			select a.source, a.reporttype, a.Category, a.[Group], a.Label, 
					max(a.CreatedDate) CreatedDate, max(a.UpdatedDate) UpdatedDate 
			from
			(
				select  accr.source, accr.reporttype, accri.Category, accri.[Group], 
						replace(replace(replace(replace(replace(replace(replace(replace(replace(label,
						',',''),
						'Activate Leak Defense Automatic Water Shut Off Device (if the occupancy of the house is not primary)','Activate Leak Defense Auto Water Shut Off Device (if the occupancy of the house is not primary)'),
						' Toilet Supply Lines That Have Plastic B-nut Connectors and',' Toilet Lines having Plastic B-nut Conn and'),
						'when construction starts on second floor','construction on 2nd fl'),
						'Water Leak Detection Alarm Systems','Water Leak Detectn Alarm Sys'),
						'Bar sink cabinet next to icemaker. Water in and under cab. Client called plumber while I was there.','Bar sink cab next to icemaker. Water in, under cab. Client called plumber while I was there.'),
						'[',' - '),
						']',''),
						'''','') Label, 
						accri.CreatedDate, GREATEST(accri.UpdatedDate,accri.CreatedDate) UpdatedDate 
				from	edw_stage.Account acc, edw_stage.AccountReport accr, edw_stage.AccountReportItem accri
				where	accr.AccountId=acc.Id  and source <> 'HazardHub'
				and		accr.Id =accri.ReportId  
				AND		GREATEST(accri.UpdatedDate,accri.CreatedDate)>@last_source_extract_ts
			) a
			where isnull(label,'') <> ''
			group by a.source, a.reporttype, a.Category, a.[Group], a.label
		) as source 
		on source.source = target.source 
		and source.reporttype = target.reporttype 
		and source.Category = target.Category 
		and source.[Group] = target.[Group] 
		and source.Label = target.Label
		when not matched by target then
			insert (source, reporttype, Category, [Group], Label, CreatedDate, UpdatedDate)
			values (source.source, source.reporttype, source.Category, source.[Group], source.Label, getdate(), getdate())
		WHEN MATCHED THEN UPDATE 
		SET
			Target.source		= Source.source,
			Target.reporttype	= Source.reporttype,
			Target.Category		= Source.Category,
			Target.[Group]		= Source.[Group],
			Target.Label		= Source.Label,
			Target.UpdatedDate 	= getdate()
		;
				
		update edw_stage.tvendor_report_field
		set [label] = replace(replace(replace(replace(Label,'[',' - '),']',''),'''',''),',','');

		SET @rows_affected=@rows_affected + @@ROWCOUNT; 

		set @tablename_main  = 'edw_stage.tvendor_report_field_data' --+ replace(@in_source,' ','_')

		select @sql='delete from ' 
					+  @tablename_main 
					+ ' where UpdatedDate > '''
					+  cast(@last_source_extract_ts as varchar(255)) 
					--+ ''' and source = '''
					--+  @in_source 
					+ ''''

		--print @sql
		EXECUTE sp_executesql @sql  

		select @sql='insert into ' 
					+  @tablename_main 
					+ ' select	 acc.policynumber, acc.effectivedate, 
												GREATEST(accr.UpdatedDate,accri.CreatedDate) UpdatedDate ,  accr.CreatedDate, 
												accr.dateordered, accr.dateTimeRecieved, accr.dateTimeCompleted, accr.TransactionStatus, accr.[source], accr.reporttype, 
												case when accri.Category = accri.[Group] or accri.Label = accri.[Group] then concat(accri.Category, '' - '',replace(replace(replace(replace(replace(replace(replace(replace(accri.label,''Water Leak Detection Alarm Systems'',''Water Leak Detectn Alarm Sys''),''Activate Leak Defense Automatic Water Shut Off Device (if the occupancy of the house is not primary)'',''Activate Leak Defense Auto Water Shut Off Device (if the occupancy of the house is not primary)''),'' Toilet Supply Lines That Have Plastic B-nut Connectors and'','' Toilet Lines having Plastic B-nut Conn and''),''when construction starts on second floor'',''construction on 2nd fl''),''Bar sink cabinet next to icemaker. Water in and under cab. Client called plumber while I was there.'',''Bar sink cab next to icemaker. Water in, under cab. Client called plumber while I was there.''),''['','' - ''),'']'',''''),'''''''',''''))
													when accri.Category <> accri.[Group] then concat(accri.Category, '' - '', accri.[Group], '' - '',replace(replace(replace(replace(replace(replace(replace(replace(accri.label,''Water Leak Detection Alarm Systems'',''Water Leak Detectn Alarm Sys''),''Activate Leak Defense Automatic Water Shut Off Device (if the occupancy of the house is not primary)'',''Activate Leak Defense Auto Water Shut Off Device (if the occupancy of the house is not primary)''),'' Toilet Supply Lines That Have Plastic B-nut Connectors and'','' Toilet Lines having Plastic B-nut Conn and''),''when construction starts on second floor'',''construction on 2nd fl''),''Bar sink cabinet next to icemaker. Water in and under cab. Client called plumber while I was there.'',''Bar sink cab next to icemaker. Water in, under cab. Client called plumber while I was there.''),''['','' - ''),'']'',''''),'''''''',''''))
													else ''''
												end field_name,accri.[Value], case when accr.IsReportFromCache = 1 then ''Yes'' else ''No'' end IsReportFromCache
										from	edw_stage.[Account] acc
										inner join edw_stage.[AccountReport] accr on accr.AccountId=acc.Id 
										left join edw_stage.AccountReportItem accri on accr.Id =accri.ReportId 
										where source <> ''HazardHub'' 
										AND GREATEST(accr.UpdatedDate,accr.CreatedDate) > '''
					+  cast(@last_source_extract_ts as varchar(255))
					--+ ''' and source = '''
					--+  @in_source 
					+ ''''

		print @sql
		EXECUTE sp_executesql @sql 

		SET @rows_affected=@rows_affected + @@ROWCOUNT;  

		SET @sql = N'UPDATE STATISTICS ' + @tablename_main;
    	EXEC sp_executesql @sql;
		
		update edw_stage.tvendor_report_field
		set [label] = replace(replace(replace(replace(Label,'[',' - '),']',''),'''',''),',','');
		--print 'here1'
		 
		-- Update control table 
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(UpdatedDate,CreatedDate)) 
														FROM edw_stage.tvendor_report_field),@last_source_extract_ts) 
					
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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

