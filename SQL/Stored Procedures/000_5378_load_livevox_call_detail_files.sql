-- insert into edw_core.tetl_control (process_nm, last_source_extract_ts, update_ts) values('py_call_detail_report','2024-01-01 00:00:00',null);
SELECT * FROM edw_core.tetl_control WHERE process_nm = 'py_call_detail_report';
-- UPDATE edw_core.tetl_control SET last_source_extract_ts = '1900-04-15 00:00:00' WHERE process_nm = 'py_call_detail_report';

SELECT edw_core.fn_get_last_source_extract_ts('sp_tbroker_relation') as last_date
;

-- TRUNCATE TABLE edw_stage.stage_livevox;

SELECT source_file_name, count(1) FROM edw_stage.stage_livevox GROUP BY source_file_name;

SELECT * FROM edw_stage.stage_livevox;

-- DROP TABLE vault_edw.edw_stage.stage_livevox;
-- CREATE TABLE [edw_stage].[Livevox](
-- 	[Client_ID] [varchar](255) NULL,
-- 	[Call_Center_Name] [varchar](255) NULL,
-- 	[Call_Center_ID] [varchar](255) NULL,
-- 	[LV_Client_Name] [varchar](255) NULL,
-- 	[Service_Name] [varchar](255) NULL,
-- 	[Service_Type] [varchar](255) NULL,
-- 	[Service_ID] [varchar](255) NULL,
-- 	[Transaction_Type] [varchar](255) NULL,
-- 	[Answer_Type] [varchar](255) NULL,
-- 	[Session_ID] [varchar](255) NULL,
-- 	[Transaction_ID] [varchar](255) NULL,
-- 	[Phone_Dialed] [varchar](255) NULL,
-- 	[Account_Number] [varchar](255) NULL,
-- 	[Original_Account_Number] [varchar](255) NULL,
-- 	[Client_Name] [varchar](255) NULL,
-- 	[First_name] [varchar](255) NULL,
-- 	[Last_name] [varchar](255) NULL,
-- 	[CallConnectTimeCT] [varchar](255) NULL,
-- 	[Call_End_Time] [varchar](255) NULL,
-- 	[Call_Duration] [varchar](255) NULL,
--     [IVR_Duration] [varchar](255) NULL,
-- 	[Hold_Time] [varchar](255) NULL,
-- 	[Transfer_Duration] [varchar](255) NULL,
-- 	[Last_Key_Pressed] [varchar](255) NULL,
-- 	[Filename] [varchar](255) NULL,
-- 	[Agent_Logon_Id] [varchar](255) NULL,
-- 	[Agent_Full_Name] [varchar](255) NULL,
-- 	[Agent_Team] [varchar](255) NULL,
-- 	[Talk_Time] [varchar](255) NULL,
-- 	[Wrap_Time] [varchar](255) NULL,
-- 	[Agent_Hold_Time] [varchar](255) NULL,
-- 	[Livevox_Result] [varchar](255) NULL,
-- 	[RESULTCODE] [varchar](255) NULL,
-- 	[RESULTID] [varchar](255) NULL,
-- 	[Agent_Desktop_Outcome] [varchar](255) NULL,
-- 	[Result_Category] [varchar](255) NULL,
-- 	[Custom_outcome_1] [varchar](255) NULL,
-- 	[Custom_outcome_2] [varchar](255) NULL,
-- 	[Custom_outcome_3] [varchar](255) NULL,
-- 	[Input_payment_amount] [varchar](255) NULL,
-- 	[Zip] [varchar](255) NULL,
-- 	[Caller_ID] [varchar](255) NULL,
-- 	[Phone_Number] [varchar](255) NULL,
-- 	[Campaign_Id] [varchar](255) NULL,
-- 	[CampaignType] [varchar](255) NULL,
-- 	[Call_Direction] [varchar](255) NULL,
-- 	[Interaction_Type] [varchar](255) NULL,
-- 	[AgentSkillName] [varchar](255) NULL,
-- 	[create_ts] datetime NULL,
-- 	[source_file_name] [varchar](255) NULL
-- ) ON [PRIMARY]
