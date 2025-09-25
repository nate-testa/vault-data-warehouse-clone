-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This proceudre generates marine boat and yatch commission feed
---------------------------------------------------------------------------------------------------
-- Change date 			|Author									 |	Change Description
---------------------------------------------------------------------------------------------------
-- 09/24/25				Yunus Mohammed				1. Created this procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_policy_yacht_commission_feed]
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
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

    DECLARE cur_main CURSOR FOR	
		SELECT td.yearmonth, MAX(td.actual_dt) AS end_dt
		FROM edw_core.tdate as td
		WHERE yearmonth in ( SELECT distinct yearmonth 
								FROM edw_core.tdate
								WHERE actual_dt >= @last_source_extract_ts and actual_dt <= EOMONTH(@current_date)
							) 
		GROUP BY td.yearmonth
		ORDER BY td.yearmonth;

    DECLARE @yearmonth  INT
    DECLARE @end_dt DATE

  	OPEN cur_main
		FETCH NEXT FROM cur_main INTO @yearmonth,@end_dt

		WHILE @@FETCH_STATUS = 0
		BEGIN
      EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  

      SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
    
      DELETE FROM edw_integration.policy_yacht_commission_feed  WHERE accounting_month= cast(@yearmonth as varchar(255))

      INSERT INTO edw_integration.policy_yacht_commission_feed 
      (
        accounting_month ,  insured_nm ,  policy_number,  risk_state,  company,  policy_term,
        payment_collected,  commission_premium_collected,  commission_pct,  commission_paid_this_period,  commission_paid_to_date,
        create_ts ,  update_ts ,  etl_audit_sk 
      )
      select 
          pay.accounting_month,  p.insured_nm,p.policy_no,p.risk_state_cd as risk_state,p.uw_company_nm,
          concat_ws('-',cast(p.effective_dt as varchar(20)),cast(p.expiration_dt as varchar(20))) as policy_term,
          sum(cast( replace(pay.amount,'$','') as decimal(18,2)))*-1 as payment_collected,
          sum(case when pay.receivable_type = 'Premium' then cast(replace(pay.amount,'$','') as decimal(18,2)) else 0 end)*-1 as commission_premium_collected,
          '20' as [commission_pct],
          sum(case when pay.receivable_type = 'Premium' then cast(replace(pay.amount,'$','') as decimal(18,2)) else 0 end)*0.20*-1 as commission_paid_this_period,
          (
          
            select sum(case when pay1.receivable_type = 'Premium' then cast(replace(pay1.amount,'$','') as decimal(18,2)) else 0 end)*0.20*-1
            from
            edw_core.vmajescocashactivity pay1
            where
            pay1.policy_no = p.policy_no
            and cast(pay1.policy_effective_date as date) = p.effective_dt
          ) as commission_paid_to_date,
          getdate() as create_ts,getdate() as update_ts,@etl_audit_sk asetl_audit_sk
          from
          edw_core.tpolicy p
          inner join edw_core.vmajescocashactivity pay on pay.policy_no = p.policy_no
            and cast(pay.policy_effective_date as date) = p.effective_dt
          where
          p.product_cd = 'BY'
          and pay.accounting_month  = cast(@yearmonth as varchar(255))
          group by p.policy_no,p.effective_dt,p.expiration_dt,p.insured_nm,p.risk_state_cd,p.uw_company_nm,policy_term,pay.accounting_month

          SET @rows_affected  = @@ROWCOUNT

     -- Update control table
        IF @yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,'0','') ,datepart(mm,getdate()) )
        BEGIN
          select 	@end_dt = max(actual_dt)
          from edw_core.tdate
          where yearmonth = @yearmonth and actual_dt <= cast(getdate() as date); 
        END
        SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

        -- Update audit table
        SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
        EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;		

        SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
        FETCH NEXT FROM cur_main INTO @yearmonth,@end_dt;
      END
	
		CLOSE cur_main;

		DEALLOCATE cur_main;
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
GO
