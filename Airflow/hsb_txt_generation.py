from airflow import DAG
from airflow.models import BaseOperator
from airflow.providers.sftp.hooks.sftp import SFTPHook
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from datetime import datetime
from airflow.models import Variable
import pandas as pd
import time
import os

ENVIRONMENT = Variable.get("environment")

CONN_STR = MsSqlHook(mssql_conn_id="Vault_EDW")
HOME_PATH = os.path.expanduser('~')
TXT_FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/hsb"
QRY_HCP = f"""
    SELECT 
        CAST([company_product_cd] AS NVARCHAR) AS 'Product Code',
        CAST([product_nm] AS NVARCHAR) AS 'Product Name',
        CAST([contract_no] AS NVARCHAR) AS 'ContractNumber',
        CAST([policy_no] AS NVARCHAR) AS 'PolicyNumber',
        CAST([coverage_effective_dt] AS NVARCHAR) AS 'CoverageEffDate',
        CAST([coverage_expiration_dt] AS NVARCHAR) AS 'CoverageExpDate',
        CAST([insured_nm] AS NVARCHAR) AS 'NameofInsured',
        CAST([dwelling_address] AS NVARCHAR) AS 'DwellingAddress',
        CAST([dwelling_city] AS NVARCHAR) AS 'DwellingCity',
        CAST([dwelling_state] AS NVARCHAR) AS 'DwellingState',
        CAST([dwelling_zip_cd] AS NVARCHAR) AS 'DwellingZipCode',
        CAST([hcp_net_premium_amt] AS NVARCHAR) AS 'NetPremiumAmount',
        CAST([hcp_deductible_amt] AS NVARCHAR) AS 'DeductibleAmount',
        CAST([coverage_a_value] AS NVARCHAR) AS 'CoverageAVAlue',
        CAST([hcp_limit_amt] AS NVARCHAR) AS 'HCP Limit Amount',
        CAST([homeowner_policy_form_no] AS NVARCHAR) AS 'HO Policy Number',
        CAST([product_form_no] AS NVARCHAR) AS 'HO Product Form Number',
        CAST([client_product_nm] AS NVARCHAR) AS 'Client Product Name',
        CAST([dwelling_type] AS NVARCHAR) AS 'Dwelling Type',
        CAST([base_homeowner_premium] AS NVARCHAR) AS 'Base HO Premium',
        CAST([final_homeowner_premium] AS NVARCHAR) AS 'Fnal HO Premium',
        CAST([policy_deductible] AS NVARCHAR) AS 'HO Deductible',
        CAST([year_build] AS NVARCHAR) AS 'Contruction Year',
        CAST([total_living_area] AS NVARCHAR) AS 'Square Footage',
        CAST([no_of_units_in_dwelling] AS NVARCHAR) AS 'Number of Units In Building',
        CAST([email_address] AS NVARCHAR) AS 'Email Address',
        CAST([home_business] AS NVARCHAR) AS 'Home Business',
        CAST([previous_policy_number] AS NVARCHAR) AS 'Previous Policy Number'
    FROM [edw_integration].[policy_hsb_cyber_feed]
"""
QRY_HSP = f"""
    SELECT 
        CAST([company_product_cd] AS NVARCHAR) AS 'Company_Product_Code',
        CAST([product_nm] AS NVARCHAR) AS 'Product_Name',
        CAST([contract_no] AS NVARCHAR) AS 'Contract_Number',
        CAST([policy_no] AS NVARCHAR) AS 'Policy_Number',
        CAST([homeowner_policy_effective_dt] AS NVARCHAR) AS 'Homeowner_Policy_Effective_Date',
        CAST([homeowner_policy_expiration_dt] AS NVARCHAR) AS 'Homeowner_Policy_Expiration_Date',
        CAST([coverage_effective_dt] AS NVARCHAR) AS 'HSP_Coverage_Effective_Date',
        CAST([original_homeowner_policy_effective_dt] AS NVARCHAR) AS 'Original_Homeowner_Policy_Effective_Date',
        CAST([prior_homeowner_insurance_ind] AS NVARCHAR) AS 'Prior_Homeowner_Insurance_Indicator',
        CAST([insured_nm] AS NVARCHAR) AS 'Name_Of_Insured',
        CAST([dwelling_address] AS NVARCHAR) AS 'Dwelling_Address',
        CAST([dwelling_city] AS NVARCHAR) AS 'Dwelling_City',
        CAST([dwelling_state] AS NVARCHAR) AS 'Dwelling_State',
        CAST([dwelling_zip_cd] AS NVARCHAR) AS 'Dwelling_Zip_Code',
        CAST([hsp_net_premium_amt] AS NVARCHAR) AS 'HSP_Net_Premium_Amount',
        CAST([hsp_limit_amt] AS NVARCHAR) AS 'HSP_Limit_Amount',
        CAST([hsp_deductible_amt] AS NVARCHAR) AS 'HSP_Deductible_Amount',
        CAST([base_homeowner_premium] AS NVARCHAR) AS 'Base_Homeowner_Premium',
        CAST([final_homeowner_premium] AS NVARCHAR) AS 'Final_Homeowner_Premium',
        CAST([policy_deductible] AS NVARCHAR) AS 'Homeowner_Policy_Deductible',
        CAST([coverage_a_value] AS NVARCHAR) AS 'Coverage_A_Value',
        CAST([coverage_b_value] AS NVARCHAR) AS 'Coverage_B_Value',
        CAST([coverage_c_value] AS NVARCHAR) AS 'Coverage_C_Value',
        CAST([homeowner_policy_form_no] AS NVARCHAR) AS 'Homeowner_Policy_Form_Number',
        CAST([homeowners_or_dwelling_fire_policy_form_type] AS NVARCHAR) AS 'Homeowners_Policy_Form_Type',
        CAST([product_form_no] AS NVARCHAR) AS 'HSP_Product_Form_Number',
        CAST([client_product_nm] AS NVARCHAR) AS 'Client_Product_Name',
        CAST([residence_type] AS NVARCHAR) AS 'Residence_Type',
        CAST([usage_type] AS NVARCHAR) AS 'Usage_Type',
        CAST([occupancy] AS NVARCHAR) AS 'Occupancy',
        CAST([year_build] AS NVARCHAR) AS 'Year_Built',
        CAST([total_living_area] AS NVARCHAR) AS 'Total_Living_Area',
        CAST([no_of_units_in_dwelling] AS NVARCHAR) AS 'Number_Of_Units_In_Dwelling',
        CAST([heating_system_updated_yr] AS NVARCHAR) AS 'Heating_System_Updated_Year',
        CAST([electrical_system_updated_yr] AS NVARCHAR) AS 'Electrical_System_Updated_Year',
        CAST([plumbing_system_updated_yr] AS NVARCHAR) AS 'Plumbing_System_Updated_Year',
        CAST([distance_to_hydrant] AS NVARCHAR) AS 'Distance_To_Hydrant',
        CAST([pricing_tier] AS NVARCHAR) AS 'Pricing_Tier',
        CAST([insurance_score] AS NVARCHAR) AS 'Insurance_Score',
        CAST([rating_territory_cd] AS NVARCHAR) AS 'Rating_Territory_Code',
        CAST([protection_class_cd] AS NVARCHAR) AS 'Protection_Class_Code',
        CAST([previous_policy_number] AS NVARCHAR) AS 'Previous_Policy_Number',
        CAST([agent_code] AS NVARCHAR) AS 'Agent_Code',
        CAST([branch_code] AS NVARCHAR) AS 'Branch_Code'
    FROM [edw_integration].[policy_hsb_hsp_feed]
"""
QRY_SLC = f"""
    SELECT 
        CAST([company_product_cd] AS NVARCHAR) AS 'Company_Product_Code',
        CAST([product_nm] AS NVARCHAR) AS 'Product_Name',
        CAST([contract_no] AS NVARCHAR) AS 'Contract_Number',
        CAST([policy_no] AS NVARCHAR) AS 'Policy_Number',
        CAST([homeowner_policy_effective_dt] AS NVARCHAR) AS 'Homeowner_Policy_Effective_Date',
        CAST([homeowner_policy_expiration_dt] AS NVARCHAR) AS 'Homeowner_Policy_Expiration_Date',
        CAST([coverage_effective_dt] AS NVARCHAR) AS 'HSP_Coverage_Effective_Date',
        CAST([original_homeowner_policy_effective_dt] AS NVARCHAR) AS 'Original_Homeowner_Policy_Effective_Date',
        CAST([prior_homeowner_insurance_ind] AS NVARCHAR) AS 'Prior_Homeowner_Insurance_Indicator',
        CAST([insured_nm] AS NVARCHAR) AS 'Name_Of_Insured',
        CAST([dwelling_address] AS NVARCHAR) AS 'Dwelling_Address',
        CAST([dwelling_city] AS NVARCHAR) AS 'Dwelling_City',
        CAST([dwelling_state] AS NVARCHAR) AS 'Dwelling_State',
        CAST([dwelling_zip_cd] AS NVARCHAR) AS 'Dwelling_Zip_Code',
        CAST([slc_net_premium_amt] AS NVARCHAR) AS 'HSP_Net_Premium_Amount',
        CAST([slc_limit_amt] AS NVARCHAR) AS 'HSP_Limit_Amount',
        CAST([slc_deductible_amt] AS NVARCHAR) AS 'HSP_Deductible_Amount',
        CAST([base_homeowner_premium] AS NVARCHAR) AS 'Base_Homeowner_Premium',
        CAST([final_homeowner_premium] AS NVARCHAR) AS 'Final_Homeowner_Premium',
        CAST([policy_deductible] AS NVARCHAR) AS 'Homeowner_Policy_Deductible',
        CAST([coverage_a_value] AS NVARCHAR) AS 'Coverage_A_Value',
        CAST([coverage_b_value] AS NVARCHAR) AS 'Coverage_B_Value',
        CAST([coverage_c_value] AS NVARCHAR) AS 'Coverage_C_Value',
        CAST([homeowner_policy_form_no] AS NVARCHAR) AS 'Homeowner_Policy_Form_Number',
        CAST([homeowners_or_dwelling_fire_policy_form_type] AS NVARCHAR) AS 'Homeowners_Policy_Form_Type',
        CAST([product_form_no] AS NVARCHAR) AS 'HSP_Product_Form_Number',
        CAST([client_product_nm] AS NVARCHAR) AS 'Client_Product_Name',
        CAST([residence_type] AS NVARCHAR) AS 'Residence_Type',
        CAST([usage_type] AS NVARCHAR) AS 'Usage_Type',
        CAST([occupancy] AS NVARCHAR) AS 'Occupancy',
        CAST([year_build] AS NVARCHAR) AS 'Year_Built',
        CAST([total_living_area] AS NVARCHAR) AS 'Total_Living_Area',
        CAST([no_of_units_in_dwelling] AS NVARCHAR) AS 'Number_Of_Units_In_Dwelling',
        CAST([heating_system_updated_yr] AS NVARCHAR) AS 'Heating_System_Updated_Year',
        CAST([electrical_system_updated_yr] AS NVARCHAR) AS 'Electrical_System_Updated_Year',
        CAST([plumbing_system_updated_yr] AS NVARCHAR) AS 'Plumbing_System_Updated_Year',
        CAST([distance_to_hydrant] AS NVARCHAR) AS 'Distance_To_Hydrant',
        CAST([pricing_tier] AS NVARCHAR) AS 'Pricing_Tier',
        CAST([insurance_score] AS NVARCHAR) AS 'Insurance_Score',
        CAST([rating_territory_cd] AS NVARCHAR) AS 'Rating_Territory_Code',
        CAST([protection_class_cd] AS NVARCHAR) AS 'Protection_Class_Code',
        CAST([previous_policy_number] AS NVARCHAR) AS 'Previous_Policy_Number',
        CAST([agent_code] AS NVARCHAR) AS 'Agent_Code',
        CAST([branch_code] AS NVARCHAR) AS 'Branch_Code'
    FROM [edw_integration].[policy_hsb_slc_feed]
"""



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

def generate_txt_files(COMPANY_PRODUCTS, DATA_TYPE, QRY):

    for COMPANY_PRODUCT_CD in COMPANY_PRODUCTS:
        print(f"**** Start file generation for HSB-{DATA_TYPE} Data for COMPANY_PRODUCT_CD: {COMPANY_PRODUCT_CD}")
        
        if ENVIRONMENT == 'PRODUCTION':
            TXT_FILE_NAME = f'{DATA_TYPE}{COMPANY_PRODUCT_CD}INF.txt'
        else:
            TXT_FILE_NAME = f'{DATA_TYPE}{COMPANY_PRODUCT_CD}INF_test.txt'

        FINAL_QRY = QRY + f" WHERE [company_product_cd] = '{COMPANY_PRODUCT_CD}'"
        df = CONN_STR.get_pandas_df(FINAL_QRY)
        create_directory_if_not_exists(TXT_FOLDER_PATH)
        txt_path = os.path.join(TXT_FOLDER_PATH, TXT_FILE_NAME)
        df.to_csv(txt_path, sep='~', index=False)

        # Add extra line to the end of the file
        if DATA_TYPE == 'HCP':
            with open(txt_path, 'a') as f:
                f.write(f"{COMPANY_PRODUCT_CD}~{DATA_TYPE}~CONTROL~{df.shape[0]}~{datetime.now().strftime('%Y%m%d')}~1.02\n")
        else:
            with open(txt_path, 'a') as f:
                f.write(f"{COMPANY_PRODUCT_CD}~{DATA_TYPE}~CONTROL~{df.shape[0]}~{datetime.now().strftime('%Y%m%d')}~02.10\n")

        # vacum to tmp folder
        delete_old_files(TXT_FOLDER_PATH,2)

        print(f"**** HSB-{DATA_TYPE} Data for COMPANY_PRODUCT_CD: {COMPANY_PRODUCT_CD}, written to {txt_path}")


def generate_hsb_hcp_txt_files():
    COMPANY_PRODUCTS = ['4404','4854']
    generate_txt_files(COMPANY_PRODUCTS, 'HCP', QRY_HCP)


def generate_hsb_hsp_txt_files():
    COMPANY_PRODUCTS = ['4271','4850']
    generate_txt_files(COMPANY_PRODUCTS, 'HSP', QRY_HSP)


def generate_hsb_slc_txt_files():    
    COMPANY_PRODUCTS = ['4280','4852']
    generate_txt_files(COMPANY_PRODUCTS, 'SLC', QRY_SLC)


class SFTPUploadAllHsbFilesOperator(BaseOperator):

    def __init__(self, sftp_conn_id, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.sftp_conn_id = sftp_conn_id

    def execute(self, context):
        if ENVIRONMENT == 'PRODUCTION':
            REMOTE_PATH = '/prod'
            FILES_TO_LOAD = [
                'HSP4271INF.txt',
                'HSP4850INF.txt',
                'SLC4280INF.txt',
                'SLC4852INF.txt',
                'HCP4404INF.txt',
                'HCP4854INF.txt',
            ]
        else:
            REMOTE_PATH = '/test/uat'
            FILES_TO_LOAD = [
                'HSP4271INF_test.txt',
                'HSP4850INF_test.txt',
                'SLC4280INF_test.txt',
                'SLC4852INF_test.txt',
                'HCP4404INF_test.txt',
                'HCP4854INF_test.txt',
            ]

        for FILE_NAME in FILES_TO_LOAD:

            local_filepath = os.path.join(TXT_FOLDER_PATH, FILE_NAME)
            remote_filepath = f'{REMOTE_PATH}/{FILE_NAME}'
            
            hook = SFTPHook(ftp_conn_id=self.sftp_conn_id)
            self.log.info(f"**** Starting to transfer {local_filepath} to {remote_filepath}")
            hook.store_file(remote_filepath, local_filepath)
            self.log.info(f"**** Finished transferring {local_filepath} to {remote_filepath}")


