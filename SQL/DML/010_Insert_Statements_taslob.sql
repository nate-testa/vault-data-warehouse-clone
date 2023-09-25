INSERT INTO edw_core.taslob
(aslob_cd,aslob_desc,product_cd,coverage_cd,update_ts)
SELECT '192' AS aslob_cd,'Auto Other Liability' AS aslob_desc,'Automobile' AS product_cd,'Property Protection (MI Only)' AS coverage_cd,getdate() UNION
SELECT '040' AS aslob_cd,'Homeowners' AS aslob_desc,'Homeowners' AS product_cd,'Loss Assessment' AS coverage_cd,getdate() UNION
SELECT '171' AS aslob_cd,'Other Liability' AS aslob_desc,'Excess Liability' AS product_cd,'Directors & Officers' AS coverage_cd,getdate() UNION
SELECT '171' AS aslob_cd,'Other Liability' AS aslob_desc,'Excess Liability' AS product_cd,'Automobile Liability' AS coverage_cd,getdate() UNION
SELECT '171' AS aslob_cd,'Other Liability' AS aslob_desc,'Excess Liability' AS product_cd,'Uninsured General Liability' AS coverage_cd,getdate() UNION
SELECT '171' AS aslob_cd,'Other Liability' AS aslob_desc,'Excess Liability' AS product_cd,'Employment Liability' AS coverage_cd,getdate() UNION
SELECT '171' AS aslob_cd,'Other Liability' AS aslob_desc,'Excess Liability' AS product_cd,'Underinsured Motorist' AS coverage_cd,getdate() UNION
SELECT '171' AS aslob_cd,'Other Liability' AS aslob_desc,'Excess Liability' AS product_cd,'Underinsured General Liability' AS coverage_cd,getdate() UNION
SELECT '090' AS aslob_cd,'Inland Marine' AS aslob_desc,'Collections' AS product_cd,'Valualbe Articles Coverage - Wine Scheduled' AS coverage_cd,getdate() UNION
SELECT '090' AS aslob_cd,'Inland Marine' AS aslob_desc,'Homeowners' AS product_cd,'Valualbe Articles Coverage - Wine Scheduled' AS coverage_cd,getdate() UNION
SELECT '090' AS aslob_cd,'Inland Marine' AS aslob_desc,'Collections' AS product_cd,'Valuable Articles Coverage - Guns Scheduled' AS coverage_cd,getdate() UNION
SELECT '090' AS aslob_cd,'Inland Marine' AS aslob_desc,'Homeowners' AS product_cd,'Valuable Articles Coverage - Guns Scheduled' AS coverage_cd,getdate() UNION
SELECT '090' AS aslob_cd,'Inland Marine' AS aslob_desc,'Collections' AS product_cd,'Valuable Articles Coverage - Bank Vaulted Jewelry Scheduled' AS coverage_cd,getdate() UNION
SELECT '090' AS aslob_cd,'Inland Marine' AS aslob_desc,'Homeowners' AS product_cd,'Valuable Articles Coverage - Bank Vaulted Jewelry Scheduled' AS coverage_cd,getdate() UNION
SELECT '040' AS aslob_cd,'Homeowners' AS aslob_desc,'Homeowners' AS product_cd,'Thoroughbred Horse Liability Extension' AS coverage_cd,getdate() UNION
SELECT '040' AS aslob_cd,'Homeowners' AS aslob_desc,'Homeowners' AS product_cd,'Other Permanent Structures - Off Premises' AS coverage_cd,getdate() UNION
SELECT '040' AS aslob_cd,'Homeowners' AS aslob_desc,'Homeowners' AS product_cd,'Mine Subsidence' AS coverage_cd,getdate() UNION
SELECT '040' AS aslob_cd,'Homeowners' AS aslob_desc,'Homeowners' AS product_cd,'Flood' AS coverage_cd,getdate() UNION
SELECT '040' AS aslob_cd,'Homeowners' AS aslob_desc,'Homeowners' AS product_cd,'Additions and Alterations' AS coverage_cd,getdate()
;
