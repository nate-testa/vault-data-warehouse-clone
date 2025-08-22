/****** Object:  StoredProcedure [edw_core].[sp_tvendor_report]    Script Date: 8/20/2025 5:03:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Author:	Architha Gudimalla		
-- Description: This procedures loads vendor reports data
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 07/27/23		Architha Gudimalla				1. Created this procedure  
-- 03/08/23		Architha Gudimalla				2. Updated a label for LC360
-- 10/11/24		Architha Gudimalla				3. Addec cache column
-- 08/22/25		Architha Gudimalla				4. Excluded images category for LC360 
-- ================================================================================================= 

ALTER       PROCEDURE [edw_core].[sp_tvendor_report]
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
		DECLARE @tablename_main NVARCHAR(MAX)=''
		declare @sql nvarchar(max) 

		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		set @parameter_desc = 'Source=' + @in_source + '; '
		SET @parameter_desc= @parameter_desc + 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
				
				
		print @last_source_extract_ts

		set @tablename_main  = 'edw_stage.tvendor_report_field_data'
		--set @tablename_main  = 'edw_stage.tvendor_report_field_data_' + replace(@in_source,' ','_')

				
		/* 
		delete from @tablename_main
		where UpdatedDate > @last_source_extract_ts 
		and source = @in_source;

		select	acc.policynumber, acc.effectivedate, 
				accri.CreatedDate, GREATEST(accri.UpdatedDate,accri.CreatedDate) UpdatedDate ,  
				accr.dateordered, accr.dateTimeRecieved, accr.dateTimeCompleted, accr.TransactionStatus, accr.[source], accr.reporttype, 
				case when accri.Category  = accri.[Group] then concat(accri.Category, ' - ',replace(replace(replace(accri.Label,'[',' - '),']',''),'''',''))
					when accri.Category <> accri.[Group] then concat(accri.Category, ' - ', accri.[Group], ' - ',replace(replace(replace(accri.Label,'[',' - '),']',''),'''',''))
					else ''
				end field_name,accri.[Value] 
		from	edw_stage.[Account] acc, edw_stage.[AccountReport] accr, edw_stage.AccountReportItem accri
		where	accr.AccountId=acc.Id 
		and		accr.Id =accri.ReportId 
		AND		GREATEST(accri.UpdatedDate,accri.CreatedDate)>@last_source_extract_ts
		and 	accr.source = @in_source*/
		
		print 'here'
				 
		
		 -- Get column names to pivot
		DECLARE @source NVARCHAR(MAX)='' 
		DECLARE @reporttype NVARCHAR(MAX)='' 
		DECLARE @tablename NVARCHAR(MAX)=''
		DECLARE @tablename1 NVARCHAR(MAX)=''
		DECLARE @tablename2 NVARCHAR(MAX)=''
		DECLARE @tablename3 NVARCHAR(MAX)=''
		DECLARE @tablename4 NVARCHAR(MAX)=''
		DECLARE @tablename5 NVARCHAR(MAX)=''
		DECLARE @tablename6 NVARCHAR(MAX)=''
		DECLARE @ColumnsToPivot NVARCHAR(MAX)=''  
		DECLARE @ColumnsToPivot1 NVARCHAR(MAX)=''  
		DECLARE @ColumnsToPivot2 NVARCHAR(MAX)='' 
		DECLARE @ColumnsToPivot3 NVARCHAR(MAX)=''  
		DECLARE @ColumnsToPivot4 NVARCHAR(MAX)=''  
		DECLARE @ColumnsToPivot5 NVARCHAR(MAX)=''  
		DECLARE @ColumnsToPivot6 NVARCHAR(MAX)='' 
		DECLARE @ColumnsToPivot7 NVARCHAR(MAX)=''  
		declare @i int = 0 

		DECLARE c1_rec CURSOR
		FOR  
		select DISTINCT reporttype, source
		--select DISTINCT reporttype, case when reporttype = 'LocationProperty' then   source else null end source
		from edw_stage.tvendor_report_field  
		where source = @in_source --'HazardHub'  
		--and reporttype = 'InsuranceScore'  
		order by 1  
		print 'here2'

				SET @rows_affected=0

		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @reporttype, @source; 
		WHILE @@FETCH_STATUS = 0
			BEGIN    

				-- Get last source extract date
				--print 'source'
				--print @source
		print 'here3'

				set @ColumnsToPivot = ''
				set @ColumnsToPivot1 = ''
				set @ColumnsToPivot2 = ''
				set @ColumnsToPivot3 = ''
				set @ColumnsToPivot4 = ''
				set @ColumnsToPivot5 = '' 
				set @ColumnsToPivot6 = '' 
				set @ColumnsToPivot7 = '' 

				SELECT
					/*@ColumnsToPivot = ISNULL( @ColumnsToPivot + ', ', '') +  
									  cast(field_name + '=' +  cast('max(IIF(field_name='''+ replace(replace(field_name,'[',''),']','') + ''',[Value],null))  ' as nvarchar(max))
									  as nvarchar(max)),*/
					@ColumnsToPivot = ISNULL( @ColumnsToPivot + ', ', '') +  
									  cast(case when Row_num between 1 and 500 then field_name else '' end + '=' +  
									  case when Row_num between 1 and 500 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max)),
					@ColumnsToPivot1 = ISNULL( @ColumnsToPivot1 + ', ', '') +  
									  cast(case when Row_num between 501 and 1000 then field_name else '' end + '=' +  
									  case when Row_num between 501 and 1000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max)),
					@ColumnsToPivot2 = ISNULL( @ColumnsToPivot2 + ', ', '') +  
									  cast(case when Row_num between 1001 and 1500 then field_name else '' end + '=' +  
									  case when Row_num between 1001 and 1500 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max)),
					@ColumnsToPivot3 = ISNULL( @ColumnsToPivot3 + ', ', '') +  
									  cast(case when Row_num between 1501 and 2000 then field_name else '' end + '=' +  
									  case when Row_num between 1501 and 2000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max)),
					@ColumnsToPivot4 = ISNULL( @ColumnsToPivot4 + ', ', '') +  
									  cast(case when Row_num between 2001 and 2500 then field_name else '' end + '=' +  
									  case when Row_num between 2001 and 2500 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max)),
					@ColumnsToPivot5 = ISNULL( @ColumnsToPivot5 + ', ', '') +  
									  cast(case when Row_num between 2501 and 3000 then field_name else '' end + '=' +  
									  case when Row_num between 2501 and 3000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max)),
					@ColumnsToPivot6 = ISNULL( @ColumnsToPivot6 + ', ', '') +  
									  cast(case when Row_num between 3000 and 3500 then field_name else '' end + '=' +  
									  case when Row_num between 3000 and 3500 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max)),
					@ColumnsToPivot7 = ISNULL( @ColumnsToPivot7 + ', ', '') +  
									  cast(case when Row_num between 3501 and 4000 then field_name else '' end + '=' +  
									  case when Row_num between 3501 and 4000 then cast('max(IIF(field_name='''+ 
									  replace(replace(field_name,'[',''),']','') + ''',[Value],null)) ' as varchar(max))   else '' end
									  as varchar(max))/*
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
												  when Category <> isnull([Group],'') 
												  then concat('[', cast(Category as nvarchar(max)), ' - ',
												  				   cast(isnull([Group] + ' - ','') as nvarchar(max)), 
																   cast(replace([Label],'(when construction starts on second floor)','(when starts on 2nd fl)') as nvarchar(max)),']'
															 )
												  else ''
												  end 
											 as nvarchar(max)) as field_name 
						FROM  edw_stage.tvendor_report_field 
						where source = @source and reporttype = @reporttype
						and Category not like '%images%'
					) a 
				) as temp 
		print 'here4'

				set @ColumnsToPivot  = REPLACE(@ColumnsToPivot,', =','')
				set @ColumnsToPivot1  = REPLACE(@ColumnsToPivot1,', =','')
				set @ColumnsToPivot2  = REPLACE(@ColumnsToPivot2,', =','') 
				set @ColumnsToPivot3  = REPLACE(@ColumnsToPivot3,', =','')
				set @ColumnsToPivot4  = REPLACE(@ColumnsToPivot4,', =','')
				set @ColumnsToPivot5  = REPLACE(@ColumnsToPivot5,', =','') 
				set @ColumnsToPivot6  = REPLACE(@ColumnsToPivot6,', =','') 
				
				/*
				print 'ColumnsToPivot'  
				print @ColumnsToPivot 
				print 'ColumnsToPivot1' 
				print @ColumnsToPivot1 
				print 'ColumnsToPivot2' 
				print @ColumnsToPivot2 
				*/

				set @tablename  = ''
				set @tablename1  = ''
				set @tablename2  = '' 
				set @tablename3  = ''
				set @tablename4  = ''
				set @tablename5  = '' 
				set @tablename6  = '' 
				
				set @tablename = 'edw_stage.tvendor_report_' + replace(@source,' ','')
				set @tablename1 = case when LEN(@ColumnsToPivot1) > 0 
										then 'edw_stage.tvendor_report_' + replace(@source,' ','') + '_1'
								 end
				set @tablename2 = case when LEN(@ColumnsToPivot2) > 0 
										then 'edw_stage.tvendor_report_' + replace(@source,' ','') + '_2'
								 end
				set @tablename3 = case when LEN(@ColumnsToPivot3) > 0 
										then 'edw_stage.tvendor_report_' + replace(@source,' ','') + '_3'
								 end
				set @tablename4 = case when LEN(@ColumnsToPivot4) > 0 
										then 'edw_stage.tvendor_report_' + replace(@source,' ','') + '_4'
								 end
				set @tablename5 = case when LEN(@ColumnsToPivot5) > 0 
										then 'edw_stage.tvendor_report_' + replace(@source,' ','') + '_5'
								 end 
				set @tablename6 = case when LEN(@ColumnsToPivot6) > 0 
										then 'edw_stage.tvendor_report_' + replace(@source,' ','') + '_5'
								 end  
 

				--print @tablename 
		print 'here5'

				set @i = 0

				while @i <= 6 and @tablename <> ''
				begin
					--print @ColumnsToPivot
					--print @tablename  
					--print @i 

					if    exists (select * from INFORMATION_SCHEMA.TABLES where table_name = replace(@tablename,'edw_stage.','') and table_schema = 'edw_stage')
						begin
						print 'here8'; 
						set @sql = 'drop table if exists ' + @tablename 
						EXECUTE sp_executesql @sql  
						end

						
						select @sql='select policynumber,effectivedate,dateordered,dateTimeRecieved,dateTimeCompleted,TransactionStatus, IsReportFromCache,[source],reporttype'
									+ @ColumnsToPivot  
									+ ' into '
									+  @tablename 

									--print @sql 

						/*
										select *
										from edw_temp.tvendor_report_field_data accr
										where  GREATEST(accr.UpdatedDate,accr.CreatedDate) > ''
										
										select	 acc.policynumber, acc.effectivedate,  
												accr.dateordered, accr.dateTimeRecieved, accr.dateTimeCompleted, accr.TransactionStatus, accr.[source], accr.reporttype, 
												case when accri.Category  = accri.[Group] then concat(accri.Category, '' - '',replace(replace(replace(accri.Label,''['','' - ''),'']'',''''),'''''''',''''))
													when accri.Category <> accri.[Group] then concat(accri.Category, '' - '', accri.[Group], '' - '',replace(replace(replace(accri.Label,''['','' - ''),'']'',''''),'''''''',''''))
													else ''''
												end field_name,accri.[Value] 
										from	edw_stage.[Account] acc, edw_stage.[AccountReport] accr, edw_stage.AccountReportItem accri
										where	accr.AccountId=acc.Id 
										and		accr.Id =accri.ReportId 
										and GREATEST(accr.UpdatedDate,accr.CreatedDate) >
										
										*/
						
					select @sql=cast(@sql 
								+   ' 
									from
									(
										select	 * 
										from	'
								+ @tablename_main 
								+ ' accr
										where	 GREATEST(UpdatedDate,CreatedDate) > '''
								+ cast(@last_source_extract_ts as varchar(255))
								+ ''' and accr.source = '''
								+ @source
								+ '''
										and		accr.reporttype = '''
								 + @reporttype
								 + 
									 '''
									) as temp
									group by policynumber,effectivedate,dateordered,dateTimeRecieved,dateTimeCompleted,TransactionStatus,IsReportFromCache,[source],reporttype
									' as nvarchar(max))  
						
						print len(@sql)
						print 'hereeee'/*
						print substring(@sql,1,2000) 
						print substring(@sql,2001,4000)
						print substring(@sql,4001,6000)
						print substring(@sql,6001,8000)
						print substring(@sql,8001,10000) 
						print substring(@sql,10001,12000)
						print substring(@sql,12001,14000)
						print substring(@sql,14001,16000)
						print substring(@sql,16001,18000)
						print substring(@sql,18001,20000)
						print substring(@sql,20001,22000)
						print substring(@sql,22001,24000)
						print substring(@sql,24001,26000)
						print substring(@sql,26001,28000)
						print substring(@sql,28001,30000)
						print substring(@sql,30001,32000)
						print substring(@sql,32001,34000)
						print substring(@sql,34001,36000)
						print substring(@sql,36001,38000)
						print substring(@sql,38001,40000)
						print substring(@sql,40001,42000)
						print substring(@sql,42001,44000)
						print substring(@sql,44001,46000)
						print substring(@sql,46001,48000)
						print substring(@sql,48001,50000)
						print substring(@sql,50001,52000)
						print substring(@sql,52001,54000)
						print substring(@sql,54001,56000)
						print substring(@sql,56001,58000)
						print substring(@sql,58001,60000)
						print substring(@sql,60001,62000)  */

						EXECUTE sp_executesql @sql 

						SET @rows_affected=@rows_affected + @@ROWCOUNT;
						print 'row-count'
						print @rows_affected
						set @i = @i + 1 
						
						set @tablename = '' 
				
						set @ColumnsToPivot = case when @i = 1 then @ColumnsToPivot1 
											  	   when @i = 2 then @ColumnsToPivot2  
											  	   when @i = 3 then @ColumnsToPivot3  
											  	   when @i = 4 then @ColumnsToPivot4  
											  	   when @i = 5 then @ColumnsToPivot5  
											  	   when @i = 6 then @ColumnsToPivot6  
											  end
						set @tablename	    = case when @i = 1 then @tablename1
											  	   when @i = 2 then @tablename2
											  	   when @i = 3 then @tablename3
											  	   when @i = 4 then @tablename4
											  	   when @i = 5 then @tablename5
											  	   when @i = 6 then @tablename6       
											  end  
					end 
				 
				FETCH NEXT FROM c1_rec INTO @reporttype, @source;
			END; 
		CLOSE c1_rec;
		DEALLOCATE c1_rec;  

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

