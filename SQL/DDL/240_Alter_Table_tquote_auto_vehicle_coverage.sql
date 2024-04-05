IF EXISTS (SELECT * FROM sys.columns
               WHERE Name = N'antilock_brakes' AND Object_ID = Object_ID(N'edw_core.tquote_auto_vehicle_coverage'))
BEGIN
    ALTER TABLE edw_core.tquote_auto_vehicle_coverage
    DROP COLUMN antilock_brakes;
END