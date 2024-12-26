
ALTER TABLE edw_core.tclaim ADD source_of_fire varchar(255);
ALTER TABLE edw_core.tclaim ADD source_of_water varchar(255);
ALTER TABLE edw_core.tclaim ADD first_party_driver_nm varchar(255);

ALTER TABLE edw_core.tclaim ADD fault_decision varchar(255);
ALTER TABLE edw_core.tclaim ADD responsible_party varchar(255);
ALTER TABLE edw_core.tclaim ADD at_fault_pct varchar(255);