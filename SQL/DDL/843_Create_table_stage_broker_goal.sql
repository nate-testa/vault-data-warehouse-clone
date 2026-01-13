if not exists (select 1 from sys.tables where name = 'stage_broker_goal' and schema_id = schema_id('edw_stage'))
begin
    create table edw_stage.stage_broker_goal
    (
        broker_id         varchar(255)    not null,
        broker_nm        varchar(255)    not null,
        goal_year        int             not null,
        ho_new_business_premium_amt     decimal(15,2)   not null,
        create_ts datetime2(7) not null,
        update_ts datetime2(7) not null
    )
end