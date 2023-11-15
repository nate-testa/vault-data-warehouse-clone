CREATE TABLE edw_stage.t_clm_case_his 
(
  HIS_ID decimal(19,0) NOT NULL,
  CASE_ID decimal(19,0) DEFAULT NULL,
  OLD_STATUS varchar(20) ,
  NEW_STATUS varchar(20)  NOT NULL,
  CLAIM_TYPE char(3) ,
  CLOSE_TYPE varchar(10) ,
  REJECT_REASON varchar(10) ,
  REOPEN_CAUSE varchar(10) ,
  REMARK text ,
  INSERT_BY decimal(19,0) NOT NULL,
  INSERT_TIME datetime DEFAULT NULL,
  UPDATE_BY decimal(19,0) NOT NULL,
  UPDATE_TIME datetime DEFAULT NULL,
  PRIMARY KEY (HIS_ID)
)
;