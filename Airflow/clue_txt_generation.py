from airflow.models import BaseOperator
from airflow.providers.sftp.hooks.sftp import SFTPHook
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from datetime import datetime
from airflow.models import Variable
import gnupg
import pandas as pd
import time
import os
import platform

ENVIRONMENT = Variable.get("environment")

CONN_STR = MsSqlHook(mssql_conn_id="Vault_EDW")
HOME_PATH = os.path.expanduser('~')
GPG_HOME_PATH   = HOME_PATH + "/.gnupg"
TXT_FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/clue"
PGP_PUBKEY_FILE = HOME_PATH + "/airflow/key_files/CLUE_pubkey.asc"
QRY_CLUE = f"""
    SELECT 
        [contribCompany] + 
        [claimNumber] + 
        [policyNumber] + 
        [policyType] + 
        [claimDate] + 
        [causeOfLoss] + 
        [locationOfLoss] + 
        [claimAmount] + 
        [claimReportingStatus] + 
        [claimDisposition] + 
        [catastropheRelated] + 
        [mortgageName] + 
        [mortgageLoanNumber] + 
        [filler_reservedforFutureUse] + 
        [riskAddressHseNum] + 
        [riskAddressStreetName] + 
        [riskAddressAptNum] + 
        [riskAddressCity] + 
        [riskAddressState] + 
        [riskAddressZip] + 
        [riskAddressZipPlus4] + 
        [policyHolderMailAddrHseNum] + 
        [policyHolderMailAddressStreetName] + 
        [policyHolderMailAddressAptNum] + 
        [policyHolderMailAddressCity] + 
        [policyHolderMailAddressState] + 
        [policyHolderMailAddressZip] + 
        [policyHolderMailAddressZipPlus4] + 
        [policyHolderTelNumber] + 
        [filler_reservedforFutureUse1] + 
        [policyHolderNamePrefix] + 
        [policyHolderNameLast] + 
        [policyHolderNameFirst] + 
        [policyHolderNameMiddle] + 
        [policyHolderNameSuffix] + 
        [policyHolderSSN] + 
        [policyHolderDOB] + 
        [policyHolderSex] + 
        [filler_reservedforFutureUse2] + 
        [policyHolder2NamePrefix] + 
        [policyHolder2NameLast] + 
        [policyHolder2NameFirst] + 
        [policyHolder2NameMiddle] + 
        [policyHolder2NameSuffix] + 
        [policyHolder2SSN] + 
        [policyHolder2DOB] + 
        [policyHolder2Sex] + 
        [filler_reservedforFutureUse3] + 
        [claimantNamePrefix] + 
        [claimantNameLast] + 
        [claimantNameFirst] + 
        [claimantNameMiddle] + 
        [claimantNameSuffix] + 
        [claimantSSN] + 
        [claimantDOB] + 
        [claimantSex] + 
        [claimantAddressHseNum] + 
        [claimantAddressStreetName] + 
        [claimantAddressAptNum] + 
        [claimantAddressCity] + 
        [claimantAddressState] + 
        [claimantAddressZip] + 
        [claimantAddressZipPlus4] + 
        [claimantTelephoneAreaCode] + 
        [claimantTelephoneNumber] + 
        [filler_reservedforFutureUse4] + 
        [clueControlArea] + 
        [filler_reservedforFutureUse5] + 
        [recordVersionNumber] AS FinalData
    FROM 
        [edw_integration].[claim_clue_property_feed]
    WHERE 
        create_ts = (SELECT MAX(create_ts) AS create_ts FROM [edw_integration].[claim_clue_property_feed])
"""

QRY_CLUE_START_END_DATE = """
    SELECT TOP 1  
        CONVERT(VARCHAR(8), report_start_date, 112) + CONVERT(VARCHAR(8), report_end_date, 112) AS start_end_date
    FROM [edw_integration].[claim_clue_property_feed]
    WHERE create_ts = (SELECT MAX(create_ts) AS create_ts FROM [edw_integration].[claim_clue_property_feed])
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


def generate_txt_file_and_encrypt(**kwargs):

    print(f"**** Start file generation for CLUE Data")

    FILE_DATE = datetime.now().strftime('%Y%m%d%H%M%S')
    if ENVIRONMENT == 'PRODUCTION':
        TXT_FILE_NAME = f'clup_history_vaulthd1_{FILE_DATE}.txt'
    else:
        TXT_FILE_NAME = f'clup_history_test_vaulthd1_{FILE_DATE}.txt'

    df = CONN_STR.get_pandas_df(QRY_CLUE)
    create_directory_if_not_exists(TXT_FOLDER_PATH)
    TXT_FILE_PATH = os.path.join(TXT_FOLDER_PATH, TXT_FILE_NAME)
    # df.to_csv(TXT_FILE_PATH, sep=None, index=False, header=False)
    df_string = df.to_string(index=False, header=False)

    # write into txt file
    with open(TXT_FILE_PATH, 'w') as f:
        f.write(df_string)

    # Parameter to be included into the file
    record_count = str(df.shape[0]).zfill(6) #should be 6 digits, like 002578
    start_end_date = get_start_end_date()
    header = f"##!!SAC#231740906CLUP          E10736FTPE11967000Vault Insurance                                          CLUP_HISTORY                  {start_end_date}                                                                                                        "
    triler = f"##!!SAT#231740906CLUP          E10736FTP{record_count}                                                                                                                                                                                                                  "

    # Read all rows
    with open(TXT_FILE_PATH, 'r') as f:
        file_content = f.read()

    # Add extra line to the begin and end of the file
    file_new_content = header + "\n" + file_content + "\n" + triler + "\n"

    # Write all rows
    with open(TXT_FILE_PATH, 'w') as f:
        f.write(file_new_content)

    # vacum to tmp folder
    delete_old_files(TXT_FOLDER_PATH,2)


    # ******************
    # ****Encryption****
    # ******************
    print(f"**** CLUE Data, written to {TXT_FILE_PATH}")
    
    # Encrypt file
    print(f"**** Start file encryption")
    PGP_encrypt_file(TXT_FILE_PATH, PGP_PUBKEY_FILE)
    print(f"**** ENd file encryption")

    # set xcom parameters
    file_local_clue_file_name = TXT_FILE_PATH + '.pgp'
    file_remote_clue_file_name = f'/vaulthd1/{TXT_FILE_NAME}.pgp'

    kwargs['ti'].xcom_push(key='file_local_clue_file_name', value=file_local_clue_file_name)
    kwargs['ti'].xcom_push(key='file_remote_clue_file_name', value=file_remote_clue_file_name)


class SFTPUploadClueFileOperator(BaseOperator):

    def __init__(self, sftp_conn_id, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.sftp_conn_id = sftp_conn_id

    def execute(self, context):
        if ENVIRONMENT == 'PRODUCTION':
            local_filepath = context['ti'].xcom_pull(task_ids='integration_group.generate_clue_txt_file', key='file_local_clue_file_name')
            remote_filepath = context['ti'].xcom_pull(task_ids='integration_group.generate_clue_txt_file', key='file_remote_clue_file_name')
            
            hook = SFTPHook(ftp_conn_id=self.sftp_conn_id)
            self.log.info(f"**** Starting to transfer {local_filepath} to {remote_filepath}")
            hook.store_file(remote_filepath, local_filepath)
            self.log.info(f"**** Finished transferring {local_filepath} to {remote_filepath}")
        else:
            print(f"**** Environment: [{ENVIRONMENT}] is not authorized to send Clue files.")

