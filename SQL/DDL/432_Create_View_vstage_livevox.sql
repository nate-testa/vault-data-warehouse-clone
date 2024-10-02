IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vstage_livevox' 
)  
DROP VIEW edw_core.vstage_livevox;

GO

CREATE VIEW edw_core.vstage_livevox 
AS 
SELECT
    [Client_ID]
    ,[Call_Center_Name]
    ,[Call_Center_ID]
    ,[LV_Client_Name]
    ,[Service_Name]
    ,[Service_Type]
    ,[Service_ID]
    ,[Transaction_Type]
    ,[Answer_Type]
    ,[Session_ID]
    ,[Transaction_ID]
    ,[Phone_Dialed]
    ,[Account_Number]
    ,[Original_Account_Number]
    ,[Client_Name]
    ,[First_name]
    ,[Last_name]
    ,[CallConnectTimeCT]
    ,[Call_End_Time]
    ,[Call_Duration]
    ,[IVR_Duration]
    ,[Hold_Time]
    ,[Transfer_Duration]
    ,[Last_Key_Pressed]
    ,[Filename]
    ,[Agent_Logon_Id]
    ,[Agent_Full_Name]
    ,[Agent_Team]
    ,[Talk_Time]
    ,[Wrap_Time]
    ,[Agent_Hold_Time]
    ,[Livevox_Result]
    ,[RESULTCODE]
    ,[RESULTID]
    ,[Agent_Desktop_Outcome]
    ,[Result_Category]
    ,[Custom_outcome_1]
    ,[Custom_outcome_2]
    ,[Custom_outcome_3]
    ,[Input_payment_amount]
    ,[Zip]
    ,[Caller_ID]
    ,[Phone_Number]
    ,[Campaign_Id]
    ,[CampaignType]
    ,[Call_Direction]
    ,[Interaction_Type]
    ,[AgentSkillName]
    ,[create_ts]
    ,[source_file_name]
FROM edw_stage.stage_livevox
;