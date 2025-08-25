import os
import time
import gnupg
from datetime import datetime
from airflow.models import Variable
from airflow.models import BaseOperator
from airflow.providers.sftp.hooks.sftp import SFTPHook
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.exceptions import AirflowException


ENVIRONMENT = Variable.get("environment")

CONN_STR = MsSqlHook(mssql_conn_id="Vault_EDW")
HOME_PATH = os.path.expanduser('~')
GPG_HOME_PATH   = HOME_PATH + "/.gnupg"
TXT_FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/clue"
PGP_PUBKEY_FILE = HOME_PATH + "/airflow/key_files/CLUE_pubkey.asc"

QRY_CLUE = f"""
    WITH filter_table AS (
        SELECT distinct policy_no
        FROM edw_integration.policy_current_carrier_auto_np01_feed
        WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
    )
    ,np AS (
        SELECT 
            RecordCode
            ,policy_no
            ,policy_history_sk
            ,null as auto_driver_sk
            ,null as auto_vehicle_sk
            ,create_ts
            ,(
                RecordCode
                + ContribCompanyAMBestNumber
                + PolicyNumber
                + InsuranceType
                + ChangeEffectiveDate
                + ContribCompanyName
                + RiskType
                + PolicyType
                + NAICCode
                + PolicyInceptionDate
                + PolicyPeriodEndDate
                + PolicyPeriodBeginDate
                + PolicyCancellationDate
                + PolicyPremium
                + PremiumPaymentPlan
                + PremiumMethodPayment
                + Reserved1
                + PolicyHolderMailAddressHouseNum
                + PolicyHolderMailAddressStreetName
                + PolicyHolderMailAddressAptNum
                + PolicyHolderMailAddressCity
                + PolicyHolderMailAddressState
                + PolicyHolderMailAddressZip
                + PolicyHolderMailAddressZipPlus4
                + PolicyHolderTelephoneAreaCode
                + PolicyHolderTelephoneNumber
                + PolicyHolderTelephoneExtension
                + Reserved2
                + Reserved3
                + AgentIdentifier
                + PolicyState
            ) AS FinalData
        FROM edw_integration.policy_current_carrier_auto_np01_feed
        WHERE policy_no IN (select policy_no from filter_table)
    )
    ,sj as (
        SELECT 
            RecordCode
            ,policy_no
            ,policy_history_sk
            ,auto_driver_sk
            ,null as auto_vehicle_sk
            ,create_ts
            ,(
                RecordCode
                + ContribCompanyAMBestNumber
                + PolicyNumber
                + InsuranceType
                + ChangeEffectiveDate
                + RelationshipToPolicyHolder
                + NameLast
                + NameFirst
                + NameMiddle
                + NameSuffix
                + DOB
                + SSN
                + Gender
                + DLNumber
                + DLState
                + InternalQouteback
                + Reserved1
                + SpecialProjectsIdentifier
                + SequenceNumber
                + ClientIdentifier
                + EmailAddress
                + IndividualOrBusinessType
                + BusinessOrTrustName
                + FEINNumber
                + BusinessOrTrustNameAddressType
                + BusinessOrTrustNameMailingAddressStreetNumber
                + BusinessOrTrustNameMailingAddressStreetName
                + BusinessOrTrustNameMailingAddressSuiteNumber
                + BusinessOrTrustNameMailingAddressCity
                + BusinessOrTrustNameMailingAddressState
                + BusinessOrTrustNameMailingAddressZipCode
                + BusinessOrTrustNameMailingAddressZipCodePlus4
                + BusinessOrTrustNamePhoneAreaCode
                + BusinessOrTrustNamePhoneNumber
                + BusinessOrTrustNamePhoneNumberExtension
                + MaritalStatus
                + Filler1
            ) AS FinalData
        FROM edw_integration.policy_current_carrier_auto_sj01_feed
        WHERE policy_no IN (select policy_no from filter_table)
    )
    ,pr as (
        SELECT 
            RecordCode
            ,policy_no
            ,policy_history_sk
            ,null as auto_driver_sk
            ,auto_vehicle_sk
            ,create_ts
            ,(
                RecordCode
                + ContribCompanyAMBestNumber
                + PolicyNumber
                + InsuranceType
                + ChangeEffectiveDate
                + VIN
                + VehicleModelYear
                + VehicleMake
                + VehicleModel
                + LocationAddressHouseNumber
                + LocationAddressStreetName
                + LocationAddressAptNumber
                + LocationAddressCity
                + LocationAddressState
                + LocationAddressZIPCode
                + LocationAddressZIPCodePlus4
                + Reserved1
                + BusinessUseIndicator
                + Reserved2
                + CoverageType1
                + IndividualLimit1
                + OccurrenceLimit1
                + CSL1
                + CoverageType2
                + IndividualLimit2
                + OccurrenceLimit2
                + CSL2
                + CoverageType3
                + IndividualLimit3
                + OccurrenceLimit3
                + CSL3
                + CoverageType4
                + IndividualLimit4
                + OccurrenceLimit4
                + CSL4
                + CoverageType5
                + IndividualLimit5
                + OccurrenceLimit5
                + CSL5
                + CoverageType6
                + IndividualLimit6
                + OccurrenceLimit6
                + CSL6
                + CoverageType7
                + IndividualLimit7
                + OccurrenceLimit7
                + CSL7
                + CoverageType8
                + IndividualLimit8
                + OccurrenceLimit8
                + CSL8
                + CoverageType9
                + IndividualLimit9
                + OccurrenceLimit9
                + CSL9
                + CoverageType10
                + IndividualLimit10
                + OccurrenceLimit10
                + CSL10
                + CoverageType11
                + IndividualLimit11
                + OccurrenceLimit11
                + CSL11
                + CoverageType12
                + IndividualLimit12
                + OccurrenceLimit12
                + CSL12
                + CoverageType13
                + IndividualLimit13
                + OccurrenceLimit13
                + CSL13
                + CoverageType14
                + IndividualLimit14
                + OccurrenceLimit14
                + CSL14
                + CoverageType15
                + IndividualLimit15
                + OccurrenceLimit15
                + CSL15
                + Reserved3
                + PropertyIdentifier
                + Reserved4
                + Leasedvehicle
                + PropertyCancellationIndicator
                + PropertyCancellationDate
                + Filler1
                + PropertyType
                + Deductible1Perc
                + Deductible1Amount
                + Deductible2Perc
                + Deductible2Amount
                + Deductible3Perc
                + Deductible3Amount
                + Deductible4Perc
                + Deductible4Amount
                + Deductible5Perc
                + Deductible5Amount
                + Deductible6Perc
                + Deductible6Amount
                + Deductible7Perc
                + Deductible7Amount
                + Deductible8Perc
                + Deductible8Amount
                + Deductible9Perc
                + Deductible9Amount
                + Deductible10Perc
                + Deductible10Amount
                + Deductible11Perc
                + Deductible11Amount
                + Deductible12Perc
                + Deductible12Amount
                + Deductible13Perc
                + Deductible13Amount
                + Deductible14Perc
                + Deductible14Amount
                + Deductible15Perc
                + Deductible15Amount
                + FormNumber
                + OtherSerialNumber
                + OtherMake
                + OtherModel
                + OtherYear
                + Filler2
            ) AS FinalData
        FROM edw_integration.policy_current_carrier_auto_pr01_feed
        WHERE policy_no IN (select policy_no from filter_table)
    )
    ,vr as (
        SELECT
            RecordCode
            ,policy_no
            ,policy_history_sk
            ,null as auto_driver_sk
            ,auto_vehicle_sk
            ,create_ts
            ,( 
                RecordCode
                + ContribCompanyAMBestNumber
                + PolicyNumber
                + InsuranceType
                + ChangeEffectiveDate
                + VIN
                + VehicleRegisteredState
                + VehicleType
                + VehicleStatus
                + VehicleStatusDate
                + vehicleCancellationReason
                + NonCoverageReasonCode
                + LicensePlateNumber
                + StateTrackingNumber
                + Reserved1
                + VehicleAddDate
                + InsuredRegistrantSequenceNumber
                + VehicleMileage
                + ALIRtSActivityCode
                + TelematicsIndicator
                + TownshipCode
                + RegistrationPlateType
                + RegistrationPlateColor
                + RideShareIndicator
                + Reserved2
                + CellphoneNumberCountryCode
                + CellphoneAreaCode
                + CellphoneNumber
                + Filler1
            ) AS FinalData
        FROM edw_integration.policy_current_carrier_auto_vr01_feed
        WHERE policy_no IN (select policy_no from filter_table)
    )
    ,final_table AS (
        SELECT policy_no, policy_history_sk, auto_vehicle_sk, auto_driver_sk, RecordCode, CAST(FinalData AS varchar(215)) AS FinalData FROM np UNION ALL
        SELECT policy_no, policy_history_sk, auto_vehicle_sk, auto_driver_sk, RecordCode, CAST(FinalData AS varchar(999)) AS FinalData FROM sj UNION ALL
        SELECT policy_no, policy_history_sk, auto_vehicle_sk, auto_driver_sk, RecordCode, CAST(FinalData AS varchar(999)) AS FinalData FROM pr UNION ALL
        SELECT policy_no, policy_history_sk, auto_vehicle_sk, auto_driver_sk, RecordCode, CAST(FinalData AS varchar(999)) AS FinalData FROM vr 
    )
    SELECT FinalData FROM final_table
    ORDER BY policy_no, policy_history_sk, auto_vehicle_sk, auto_driver_sk, RecordCode
"""

QRY_CLUE_START_END_DATE = """
    SELECT TOP 1  
        CONVERT(VARCHAR(8), reporting_period_begin_dt, 112) + CONVERT(VARCHAR(8), reporting_period_end_dt, 112) AS start_end_date
    FROM edw_integration.policy_current_carrier_auto_np01_feed
    WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
"""

def get_start_end_date():
    df = CONN_STR.get_pandas_df(QRY_CLUE_START_END_DATE)
    start_end_date = df['start_end_date'].iloc[0]
    return start_end_date

def create_directory_if_not_exists(directory_path):
    if not os.path.exists(directory_path):
        os.makedirs(directory_path)
        return f"The directory {directory_path} was created."
    else:
        return f"The directory {directory_path} already exists."


def delete_old_files(folder_path, retention_days=5):
    now = time.time()
    days = retention_days * 24 * 60 * 60

    files_removed = 0
    # List all files in the directory
    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        # Check if it's a file and not a directory
        if os.path.isfile(file_path):
            # Check the file's last modified time
            if now - os.path.getmtime(file_path) > days:
                # If it's greater than retention_days parameter, remove it
                os.remove(file_path)
                files_removed += 1

    return files_removed


def PGP_encrypt_file(file_to_encrypt, recipient_public_key):

    gpg=gnupg.GPG(gnupghome=GPG_HOME_PATH)
    gpg.encoding = 'utf-8'    

    # Read and import public key
    key_data = open(recipient_public_key).read()
    import_result = gpg.import_keys(key_data)

    # Add trust keys
    gpg.trust_keys(import_result.fingerprints,'TRUST_ULTIMATE')

    # print keys
    # mykeys = gpg.list_keys()
    # for key in mykeys:
    #     print(key)

    # Read file content
    with open(file_to_encrypt, 'rb') as file:
        status = gpg.encrypt_file(
            file, 
            recipients=['PGP.BatchEncryption@lexisnexisrisk.com'], 
            output=file_to_encrypt + ".pgp",
            )
    print(status.ok)
    print(status.stderr)

    if not status.ok:
        raise AirflowException(f"PGP encryption failed: {status.stderr}")


def generate_Current_Carrier_txt_file_and_encrypt(**kwargs):

    print(f"**** Start file generation for CLUE Current_Carrier Data")
    
    kwargs['ti'].xcom_push(key='clue_Current_Carrier_data_present', value=True)

    FILE_DATE = datetime.now().strftime('%Y%m%d%H%M%S')
    if ENVIRONMENT == 'PRODUCTION':
        TXT_FILE_NAME = f'cc_history_vaulthd1_{FILE_DATE}.txt'
    else:
        TXT_FILE_NAME = f'cc_history_test_vaulthd1_{FILE_DATE}.txt'

    df = CONN_STR.get_pandas_df(QRY_CLUE)
    if df.empty:
        kwargs['ti'].xcom_push(key='clue_Current_Carrier_data_present', value=False)
        print("**** !!!There is no data to send. File generation will not proceed.!!!")
        return

    create_directory_if_not_exists(TXT_FOLDER_PATH)
    TXT_FILE_PATH = os.path.join(TXT_FOLDER_PATH, TXT_FILE_NAME)
    
    # write into txt file - write each row directly to preserve exact formatting
    with open(TXT_FILE_PATH, 'w') as f:
        for index, row in df.iterrows():
            # Get the FinalData value exactly as returned from SQL - preserve all spaces and exact length
            final_data = str(row['FinalData'])
            if index < len(df) - 1:
                f.write(final_data + '\n')
            else:
                f.write(final_data)

    # Parameter to be included into the file
    record_count = str(df.shape[0]).zfill(6) #should be 6 digits, like 002578
    start_end_date = get_start_end_date()
    yydddhhmm = datetime.now().strftime('%y%j%H%M')
    header = f"##!!SAC#{yydddhhmm}CARR          E10736FTPE11967000Vault Insurance                                          CC_HISTORY                    {start_end_date}01                                                                                                      "
    footer = f"##!!SAT#{yydddhhmm}CARR          E10736FTP{record_count}                                                                                                                                                                                                                  "

    # Read all rows
    with open(TXT_FILE_PATH, 'r') as f:
        file_content = f.read()

    # Add extra line to the begin and end of the file
    file_new_content = header + "\n" + file_content + "\n" + footer + "\n"

    # Write all rows
    with open(TXT_FILE_PATH, 'w') as f:
        f.write(file_new_content)

    # vacum to tmp folder
    delete_old_files(TXT_FOLDER_PATH,5)

    # ******************
    # ****Encryption****
    # ******************
    print(f"**** CLUE Current_Carrier Data, written to {TXT_FILE_PATH}")
    
    # Encrypt file
    print(f"**** Start file encryption")
    PGP_encrypt_file(TXT_FILE_PATH, PGP_PUBKEY_FILE)
    print(f"**** ENd file encryption")

    # set xcom parameters
    file_local_clue_file_name = TXT_FILE_PATH + '.pgp'
    file_remote_clue_file_name = f'/vaulthd1/{TXT_FILE_NAME}.pgp'

    kwargs['ti'].xcom_push(key='file_local_clue_Current_Carrier_file_name', value=file_local_clue_file_name)
    kwargs['ti'].xcom_push(key='file_remote_clue_Current_Carrier_file_name', value=file_remote_clue_file_name)


class SFTPUploadClueCurrent_CarrierFileOperator(BaseOperator):

    def __init__(self, sftp_conn_id, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.sftp_conn_id = sftp_conn_id

    def execute(self, context):
        if ENVIRONMENT == 'PRODUCTION':
            ti = context.get('ti')
            clue_data_present = ti.xcom_pull(task_ids='CLUE_Current_Carrier_group.generate_clue_Current_Carrier_txt_file', key='clue_Current_Carrier_data_present') if ti else None

            if clue_data_present == True:
                ti = context.get('ti')
                local_filepath = ti.xcom_pull(task_ids='CLUE_Current_Carrier_group.generate_clue_Current_Carrier_txt_file', key='file_local_clue_Current_Carrier_file_name') if ti else None
                remote_filepath = ti.xcom_pull(task_ids='CLUE_Current_Carrier_group.generate_clue_Current_Carrier_txt_file', key='file_remote_clue_Current_Carrier_file_name') if ti else None
                
                hook = SFTPHook(ftp_conn_id=self.sftp_conn_id)
                self.log.info(f"**** Starting to transfer {local_filepath} to {remote_filepath}")
                if local_filepath is None or remote_filepath is None:
                    raise AirflowException("Local or remote file path is None. Cannot transfer file.")
                hook.store_file(remote_filepath, local_filepath)
                self.log.info(f"**** Finished transferring {local_filepath} to {remote_filepath}")
            else:
                print("**** !!!There is no data to send. no files to transfer into SFTP!!!")
        else:
            print(f"**** Environment: [{ENVIRONMENT}] is not authorized to send Clue files.")

