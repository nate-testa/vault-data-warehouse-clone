select 
    -- distinct g.garage_address_line1 , g.garage_address_line2 , g.garage_address_city_nm , g.garage_address_state_cd , g.garage_address_zip_code , count(*) 
    p.policy_no, tif.*, g.garage_address_line1 , g.garage_address_line2 , g.garage_address_city_nm , g.garage_address_state_cd , g.garage_address_zip_code
FROM edw_core.titem_inforce tif 
JOIN edw_core.tdate d ON d.date_sk = tif.month_sk 
JOIN edw_core.tpolicy p ON tif.policy_sk = p.policy_sk 
LEFT JOIN edw_core.tauto_vehicle v ON v.auto_vehicle_sk = tif.item_sk 
LEFT JOIN edw_core.tauto_vehicle_coverage  avc ON avc.auto_vehicle_coverage_sk  = tif.vehicle_coverage_sk  -- vehicle level covs 
LEFT JOIN edw_core.tauto_garage_location g on avc.auto_garage_location_sk = g.auto_garage_location_sk  and avc.policy_history_sk = g.policy_history_sk 
WHERE 1=1
    AND p.policy_no = 'AU100138560-01'
    AND tif.item_sk = 47577
    -- AND d.actual_dt = '2023-12-31'     
    -- AND p.product_cd = 'AU'     
    -- AND annual_premium_amt <> 0     
    -- AND g.garage_address_line1 is not null 
-- group by g.garage_address_line1 , g.garage_address_line2 , g.garage_address_city_nm , g.garage_address_state_cd , g.garage_address_zip_code
;

select top 10 * from edw_core.titem_inforce;
select * from edw_core.tdate where date_sk = 334 ; 
select * from edw_core.tpolicy  where policy_sk = 111164;

SELECT * FROM edw_core.tpolicy WHERE policy_no = 'AU100138560-01';
SELECT * FROM edw_core.tpolicy_history WHERE policy_no = 'AU100138560-01';
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 150;
SELECT * FROM edw_core.titem_inforce WHERE policy_sk = 150;
SELECT * FROM edw_core.tauto_vehicle WHERE auto_vehicle_sk = 43018;
SELECT * FROM edw_core.tauto_vehicle_coverage WHERE auto_vehicle_coverage_sk = 124488;
SELECT * FROM edw_core.tauto_garage_location WHERE auto_garage_location_sk = 44472; 

SELECT * FROM edw_core.tauto_vehicle WHERE policy_no = 'AU100138560-01';
SELECT * FROM edw_core.tauto_vehicle_coverage WHERE policy_no = 'AU100138560-01';
SELECT * FROM edw_core.tauto_garage_location WHERE policy_no = 'AU100138560-01';


--policy_no AU100138560-01
SELECT item_sk, COUNT(1) FROM edw_core.titem_inforce WHERE policy_sk = 150 GROUP BY item_sk;
SELECT * FROM edw_core.tauto_vehicle WHERE auto_vehicle_sk IN (0,43018,46794,47577,61937);
SELECT vehicle_coverage_sk, COUNT(1) FROM edw_core.titem_inforce WHERE policy_sk = 150 GROUP BY vehicle_coverage_sk;
SELECT * FROM edw_core.tauto_vehicle_coverage WHERE auto_vehicle_coverage_sk IN (0,85085,124488,124489);
SELECT auto_garage_location_sk, policy_history_sk, COUNT(1) FROM edw_core.tauto_vehicle_coverage WHERE auto_vehicle_coverage_sk IN (0,85085,124488,124489) GROUP BY auto_garage_location_sk, policy_history_sk;
SELECT * FROM edw_core.tauto_garage_location WHERE auto_garage_location_sk IN (44472,39861);

--policy_no AU100138560-01 AND item_sk 47577
SELECT * FROM edw_core.titem_inforce WHERE policy_sk = 150 AND item_sk = 47577;

SELECT * FROM edw_core.tauto_vehicle WHERE auto_vehicle_sk IN (47577);
SELECT vehicle_coverage_sk, COUNT(1) FROM edw_core.titem_inforce WHERE policy_sk = 150 AND item_sk = 47577 GROUP BY vehicle_coverage_sk;
SELECT * FROM edw_core.tauto_vehicle_coverage WHERE auto_vehicle_coverage_sk IN (0,85085,124488,124489);
SELECT auto_garage_location_sk, policy_history_sk, COUNT(1) FROM edw_core.tauto_vehicle_coverage WHERE auto_vehicle_coverage_sk IN (0,85085,124488,124489) GROUP BY auto_garage_location_sk, policy_history_sk;
SELECT * FROM edw_core.tauto_garage_location WHERE auto_garage_location_sk IN (44472,39861);

SELECT * FROM edw_core.titem_inforce;