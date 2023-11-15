-- =================================================================================================
-- Author:	Architha Gudimalla		
-- Description: This procedures loads vendor reports data
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 07/27/23		Architha Gudimalla				1. Created this procedure  
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tvendor_reports_3]
@in_source varchar(255)
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
		 
		merge into edw_stage.tvendor_report_field as target
		using
		(
			select  accr.source, accr.reporttype, accri.Category, accri.[Group], accri.Label, 
					max(accri.CreatedDate) CreatedDate, max(accri.UpdatedDate) UpdatedDate 
			from	edw_stage.Account acc, edw_stage.AccountReport accr, edw_stage.AccountReportItem accri
			where	accr.AccountId=acc.Id  and source is not null
			and		accr.Id =accri.ReportId 
			AND		GREATEST(accri.UpdatedDate,accri.CreatedDate)>@last_source_extract_ts
			group by accr.source, accr.reporttype, accri.Category, accri.[Group], accri.Label
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
		
		 -- Get column names to pivot
		DECLARE @source NVARCHAR(MAX)='' 
		DECLARE @reporttype NVARCHAR(MAX)='' 
		DECLARE @tablename NVARCHAR(MAX)=''
		DECLARE @tablename1 NVARCHAR(MAX)=''
		DECLARE @tablename2 NVARCHAR(MAX)=''
		DECLARE @ColumnsToPivot NVARCHAR(MAX)=''  
		DECLARE @ColumnsToPivot1 NVARCHAR(MAX)=''  
		DECLARE @ColumnsToPivot2 NVARCHAR(MAX)=''  
		declare @sql nvarchar(max) 
		declare @i int = 0

		DECLARE c1_rec CURSOR
		FOR  
		select DISTINCT reporttype, source
		--select DISTINCT reporttype, case when reporttype = 'LocationProperty' then   source else null end source
		from edw_stage.tvendor_report_field  
		where source = @in_source --'HazardHub'  
		--and reporttype = 'InsuranceScore'  
		order by 1 

		SET @rows_affected=0

		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @reporttype, @source; 
		WHILE @@FETCH_STATUS = 0
			BEGIN  

				-- Get last source extract date
				SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
				EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
				set @parameter_desc = 'ReportType=' + @reporttype +'; Source=' + @source + '; '
				SET @parameter_desc= @parameter_desc + 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

				print 'source'
				print @source

				set @ColumnsToPivot = ''
				set @ColumnsToPivot1 = ''
				set @ColumnsToPivot2 = ''

				SELECT
					/*@ColumnsToPivot = ISNULL( @ColumnsToPivot + ', ', '') +  
									  cast(field_name + '=' +  cast('max(IIF(field_name='''+ replace(replace(field_name,'[',''),']','') + ''',[Value],null))  ' as nvarchar(max))
									  as nvarchar(max)),*/
					@ColumnsToPivot = ISNULL( @ColumnsToPivot + ', ', '') +  
									  cast(case when Row_num between 1 and 1000 then field_name else '' end + '=' +  
									  case when Row_num between 1 and 1000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max)),
					@ColumnsToPivot1 = ISNULL( @ColumnsToPivot1 + ', ', '') +  
									  cast(case when Row_num between 1001 and 2000 then field_name else '' end + '=' +  
									  case when Row_num between 1001 and 2000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max)),
					@ColumnsToPivot2 = ISNULL( @ColumnsToPivot2 + ', ', '') +  
									  cast(case when Row_num between 2001 and 3000 then field_name else '' end + '=' +  
									  case when Row_num between 2001 and 3000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max))/*
					@ColumnsToPivot = case when @ColumnsToPivot = '' then @ColumnsToPivot else ISNULL( @ColumnsToPivot + ', ', '') end  +  
									  cast(case when Row_num between 1 and 1000 then field_name + '=' else '' end  +  
									  case when Row_num between 1 and 1000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as nvarchar(max))   else '' end
									  as nvarchar(max)),
					@ColumnsToPivot1 = case when @ColumnsToPivot1 = '' then @ColumnsToPivot1 else ISNULL( @ColumnsToPivot1 + ', ', '') end +  
									  cast(case when Row_num between 1001 and 2000 then field_name + '=' else '' end +  
									  case when Row_num between 1001 and 2000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as nvarchar(max))   else '' end
									  as nvarchar(max)) ,
					@ColumnsToPivot2 = case when @ColumnsToPivot2 = '' then @ColumnsToPivot2 else ISNULL( @ColumnsToPivot2 + ', ', '') end  +  
									  cast(case when Row_num between 2001 and 3000 then field_name + '=' else '' end +  
									  case when Row_num between 2001 and 3000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as nvarchar(max))   else '' end
									  as nvarchar(max))*/
				FROM
				(
					select field_name, ROW_NUMBER() OVER(ORDER BY field_name ASC) AS Row_num
					from
					(
						SELECT distinct cast(case when  Category  = [Group]  or [Label]  = [Group] then concat('[', cast(Category as nvarchar(max)), ' - ',cast([Label] as nvarchar(max)),']')
												  when Category <> isnull([Group],'') then concat('[', cast(Category as nvarchar(max)), ' - ',cast(isnull([Group] + ' - ','') as nvarchar(max)), cast([Label] as nvarchar(max)),']')
												  else ''
												  end 
											 as nvarchar(max)) as field_name 
						FROM  edw_stage.tvendor_report_field 
						where source = @source and reporttype = @reporttype
					) a 
				) as temp 

				set @ColumnsToPivot  = REPLACE(@ColumnsToPivot,', =','')
				set @ColumnsToPivot1  = REPLACE(@ColumnsToPivot1,', =','')
				set @ColumnsToPivot2  = REPLACE(@ColumnsToPivot2,', =','') 
				
				print 'ColumnsToPivot'  
				print @ColumnsToPivot 
				print 'ColumnsToPivot1' 
				print @ColumnsToPivot1 
				print 'ColumnsToPivot2' 
				print @ColumnsToPivot2  

				set @tablename = 'edw_stage.tvendor_reports_' + replace(@source,' ','')
				set @tablename1 = case when LEN(@ColumnsToPivot1) > 0 
										then 'edw_stage.tvendor_reports_' + replace(@source,' ','') + '_1'
								 end
				set @tablename2 = case when LEN(@ColumnsToPivot2) > 0 
										then 'edw_stage.tvendor_reports_' + replace(@source,' ','') + '_2'
								 end

				set @sql = 'drop table if exists ' + @tablename 
				EXECUTE sp_executesql @sql
				print @sql

				set @sql = 'drop table if exists ' + @tablename1 
				EXECUTE sp_executesql @sql
				print @sql

				set @sql = 'drop table if exists ' + @tablename2 
				EXECUTE sp_executesql @sql
				print @sql 

				set @i = 0

				while @i <= 2
				begin
					print @ColumnsToPivot
					print @tablename
					
						
					select @sql=cast('select policynumber,effectivedate,dateordered,dateTimeRecieved,dateTimeCompleted,TransactionStatus,[source],reporttype'
								+ @ColumnsToPivot
								+ ' into '
								+  @tablename
								+	'
									from
									(
										/*select	 acc.policynumber, acc.effectivedate,  
												accr.dateordered, accr.dateTimeRecieved, accr.dateTimeCompleted, accr.TransactionStatus, accr.[source], accr.reporttype, 
												case when accri.Category  = accri.[Group] then concat(accri.Category, '' - '',replace(replace(replace(accri.Label,''['','' - ''),'']'',''''),'''''''',''''))
													when accri.Category <> accri.[Group] then concat(accri.Category, '' - '', accri.[Group], '' - '',replace(replace(replace(accri.Label,''['','' - ''),'']'',''''),'''''''',''''))
													else ''''
												end field_name,accri.[Value] 
										from	edw_stage.[Account] acc, edw_stage.[AccountReport] accr, edw_stage.AccountReportItem accri
										where	accr.AccountId=acc.Id 
										and		accr.Id =accri.ReportId */
										select *
										from edw_temp.tvendor_report_field_data accr
										where accr.source = '''
								+ @source
								+ '''
										and		accr.reporttype = '''
								 + @reporttype
								 +
									 '''
									) as temp
									group by policynumber,effectivedate,dateordered,dateTimeRecieved,dateTimeCompleted,TransactionStatus,[source],reporttype
									' as nvarchar(max))  
						
						print len(@sql)
						print @sql

						EXECUTE sp_executesql @sql
				
						SET @rows_affected=@rows_affected + @@ROWCOUNT;
						set @i = @i + 1
						set @ColumnsToPivot = case when @i = 1 then @ColumnsToPivot1 else @ColumnsToPivot2 end
						set @tablename	    = case when @i = 1 then @tablename1      else @tablename2      end
					end 

					-- Update control table 
						SET @new_last_source_extract_ts=case when @source = 'HazardHub' 
															 then COALESCE((SELECT MAX(GREATEST(UpdatedDate,CreatedDate)) 
																			FROM edw_stage.tvendor_report_field),@last_source_extract_ts)
															 else @last_source_extract_ts
													    end 
					
					EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
					-- Update audit table
					SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
					EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
				 
				FETCH NEXT FROM c1_rec INTO @reporttype, @source;
			END; 
		CLOSE c1_rec;
		DEALLOCATE c1_rec;  
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

