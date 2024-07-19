-- =================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This procedure summarizes data at the customer level for each month
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/22/23		Architha Gudimalla				1. Created this procedure 
-- 10/17/23		Architha Gudimalla				2. Removed group by on source system 
-- 07/18/24		Architha Gudimalla				3. Updated logic for @last_source_extract_ts
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcustomer_summary] 
@in_end_dt date = null 
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
		
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm); 

		DECLARE c1_rec CURSOR
		FOR  
		select	yearmonth, max(calendar_year) year, max(date_sk), max(actual_dt)
		from	edw_core.tdate
		where	actual_dt = @in_end_dt --in_yearmonth
		group by yearmonth
		union 
		select	yearmonth, max(calendar_year) year, max(date_sk), max(actual_dt)
		from	edw_core.tdate 
		where	actual_dt >= case when @in_end_dt is not null then @in_end_dt else @last_source_extract_ts end
		  and   actual_dt <  case when @in_end_dt is not null then @in_end_dt else cast(getdate() as date) end
		group by yearmonth
		order by 1;  
	
		DECLARE @parameter_desc VARCHAR(255)  
		DECLARE @year INT  
		DECLARE @yearmonth INT  
		DECLARE @end_dt_sk INT
		DECLARE @end_dt date  
		DECLARE @month_end_dt_sk INT
		DECLARE @month_end_dt date  

		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @yearmonth, @year, @end_dt_sk, @end_dt; 
		WHILE @@FETCH_STATUS = 0
			BEGIN 
		 
				SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
				EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT; 
			
				SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) 

				select 	@month_end_dt_sk = max(datE_sk),
						@month_end_dt = max(actual_dt) 
				from edw_core.tdate
				where yearmonth = @yearmonth;  
			
				delete from edw_core.tcustomer_summary
				where month_sk = @month_end_dt_sk;
			
				with prm as
				(
				 SELECT customer_sk, max(source_system_sk) source_system_sk,
						sum(inforce_ct) total_inforce_ct,
						count(distinct summ.product_sk) total_line_ct,
				 		sum(inforce_premium_amt) total_premium_amt,
				 		sum(annual_premium_amt) total_annual_premium_amt, 
				 		sum(iif(pr.product_nm='Homeowners',inforce_premium_amt,0)) homeowners_premium_amt,
				 		sum(iif(pr.product_nm='Collections',inforce_premium_amt,0)) collections_premium_amt,
				 		sum(iif(pr.product_nm='Auto',inforce_premium_amt,0)) auto_premium_amt,
				 		sum(iif(pr.product_nm='Excess Liability',inforce_premium_amt,0)) excess_liability_premium_amt, 
				 		sum(iif(pr.product_nm='Condo',inforce_premium_amt,0)) condo_premium_amt 
				 FROM edw_core.tpolicy_summary summ, edw_core.tproduct pr 
				 where month_sk = @month_end_dt_sk 
				 and pr.product_sk = summ.product_sk
				 group by customer_sk 
				)
				INSERT INTO edw_core.tcustomer_summary
					( 
						month_sk, customer_sk, 
						total_premium_amt, total_annual_premium_amt, total_inforce_ct, total_line_ct, 
						homeowners_premium_amt, collections_premium_amt, auto_premium_amt, excess_liability_premium_amt, condo_premium_amt,
						update_ts, etl_audit_sk
			        )
			    select 	@month_end_dt_sk, prm.customer_sk,
				 		total_premium_amt, total_annual_premium_amt, total_inforce_ct, total_line_ct  , 
				 		homeowners_premium_amt, collections_premium_amt, auto_premium_amt, excess_liability_premium_amt, condo_premium_amt,
						getdate(), @etl_audit_sk
				from prm 
				where total_premium_amt > 0;
		       
				SET @rows_affected=@@ROWCOUNT; 
				SET @new_last_source_extract_ts = COALESCE(@end_dt,@last_source_extract_ts);	
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		
				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 
				 
				FETCH NEXT FROM c1_rec INTO @yearmonth, @year, @end_dt_sk, @end_dt;  
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

