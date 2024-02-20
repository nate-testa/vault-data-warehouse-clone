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
        [company_product_cd] AS 'Product Code',
        [product_nm] AS 'Product Name',
        [contract_no] AS 'ContractNumber',
        [policy_no] AS 'PolicyNumber',
        [coverage_effective_dt] AS 'CoverageEffDate',
        [coverage_expiration_dt] AS 'CoverageExpDate',
        [insured_nm] AS 'NameofInsured',
        [dwelling_address] AS 'DwellingAddress',
        [dwelling_city] AS 'DwellingCity',
        [dwelling_state] AS 'DwellingState',
        [dwelling_zip_cd] AS 'DwellingZipCode',
        [hcp_net_premium_amt] AS 'NetPremiumAmount',
        [hcp_deductible_amt] AS 'DeductibleAmount',
        [coverage_a_value] AS 'CoverageAVAlue',
        [slc_limit_amt] AS 'HCP Limit Amount',
        [homeowner_policy_form_no] AS 'HO Policy Number',
        [product_form_no] AS 'HO Product Form Number',
        [client_product_nm] AS 'Client Product Name',
        [dwelling_type] AS 'Dwelling Type',
        [base_homeowner_premium] AS 'Base HO Premium',
        [final_homeowner_premium] AS 'Fnal HO Premium',
        [policy_deductible] AS 'HO Deductible',
        [year_build] AS 'Contruction Year',
        [total_living_area] AS 'Square Footage',
        [no_of_units_in_dwelling] AS 'Number of Units In Building',
        [email_address] AS 'Email Address',
        [home_business] AS 'Home Business',
        [previous_policy_number] AS 'Previous Policy Number'
    FROM [edw_integration].[policy_hsb_cyber_feed]
"""
QRY_HSP = f"""
    SELECT 
        [company_product_cd] AS 'Company_Product_Code',
        [product_nm] AS 'Product_Name',
        [contract_no] AS 'Contract_Number',
        [policy_no] AS 'Policy_Number',
        [homeowner_policy_effective_dt] AS 'Homeowner_Policy_Effective_Date',
        [homeowner_policy_expiration_dt] AS 'Homeowner_Policy_Expiration_Date',
        [coverage_effective_dt] AS 'HSP_Coverage_Effective_Date',
        [original_homeowner_policy_effective_dt] AS 'Original_Homeowner_Policy_Effective_Date',
        [prior_homeowner_insurance_ind] AS 'Prior_Homeowner_Insurance_Indicator',
        [insured_nm] AS 'Name_Of_Insured',
        [dwelling_address] AS 'Dwelling_Address',
        [dwelling_city] AS 'Dwelling_City',
        [dwelling_state] AS 'Dwelling_State',
        [dwelling_zip_cd] AS 'Dwelling_Zip_Code',
        [hsp_net_premium_amt] AS 'HSP_Net_Premium_Amount',
        [hsp_limit_amt] AS 'HSP_Limit_Amount',
        [hsp_deductible_amt] AS 'HSP_Deductible_Amount',
        [base_homeowner_premium] AS 'Base_Homeowner_Premium',
        [final_homeowner_premium] AS 'Final_Homeowner_Premium',
        [policy_deductible] AS 'Homeowner_Policy_Deductible',
        [coverage_a_value] AS 'Coverage_A_Value',
        [coverage_b_value] AS 'Coverage_B_Value',
        [coverage_c_value] AS 'Coverage_C_Value',
        [homeowner_policy_form_no] AS 'Homeowner_Policy_Form_Number',
        [homeowners_or_dwelling_fire_policy_form_type] AS 'Homeowners_Policy_Form_Type',
        [product_form_no] AS 'HSP_Product_Form_Number',
        [client_product_nm] AS 'Client_Product_Name',
        [residence_type] AS 'Residence_Type',
        [usage_type] AS 'Usage_Type',
        [occupancy] AS 'Occupancy',
        [year_build] AS 'Year_Built',
        [total_living_area] AS 'Total_Living_Area',
        [no_of_units_in_dwelling] AS 'Number_Of_Units_In_Dwelling',
        [heating_system_updated_yr] AS 'Heating_System_Updated_Year',
        [electrical_system_updated_yr] AS 'Electrical_System_Updated_Year',
        [plumbing_system_updated_yr] AS 'Plumbing_System_Updated_Year',
        [distance_to_hydrant] AS 'Distance_To_Hydrant',
        [pricing_tier] AS 'Pricing_Tier',
        [insurance_score] AS 'Insurance_Score',
        [rating_territory_cd] AS 'Rating_Territory_Code',
        [protection_class_cd] AS 'Protection_Class_Code',
        [previous_policy_number] AS 'Previous_Policy_Number',
        [agent_code] AS 'Agent_Code',
        [branch_code] AS 'Branch_Code'
    FROM [edw_integration].[policy_hsb_hsp_feed]
"""
QRY_SLC = f"""
    SELECT 
        [company_product_cd] AS 'Company_Product_Code',
        [product_nm] AS 'Product_Name',
        [contract_no] AS 'Contract_Number',
        [policy_no] AS 'Policy_Number',
        [homeowner_policy_effective_dt] AS 'Homeowner_Policy_Effective_Date',
        [homeowner_policy_expiration_dt] AS 'Homeowner_Policy_Expiration_Date',
        [coverage_effective_dt] AS 'HSP_Coverage_Effective_Date',
        [original_homeowner_policy_effective_dt] AS 'Original_Homeowner_Policy_Effective_Date',
        [prior_homeowner_insurance_ind] AS 'Prior_Homeowner_Insurance_Indicator',
        [insured_nm] AS 'Name_Of_Insured',
        [dwelling_address] AS 'Dwelling_Address',
        [dwelling_city] AS 'Dwelling_City',
        [dwelling_state] AS 'Dwelling_State',
        [dwelling_zip_cd] AS 'Dwelling_Zip_Code',
        [slc_net_premium_amt] AS 'HSP_Net_Premium_Amount',
        [slc_limit_amt] AS 'HSP_Limit_Amount',
        [slc_deductible_amt] AS 'HSP_Deductible_Amount',
        [base_homeowner_premium] AS 'Base_Homeowner_Premium',
        [final_homeowner_premium] AS 'Final_Homeowner_Premium',
        [policy_deductible] AS 'Homeowner_Policy_Deductible',
        [coverage_a_value] AS 'Coverage_A_Value',
        [coverage_b_value] AS 'Coverage_B_Value',
        [coverage_c_value] AS 'Coverage_C_Value',
        [homeowner_policy_form_no] AS 'Homeowner_Policy_Form_Number',
        [homeowners_or_dwelling_fire_policy_form_type] AS 'Homeowners_Policy_Form_Type',
        [product_form_no] AS 'HSP_Product_Form_Number',
        [client_product_nm] AS 'Client_Product_Name',
        [residence_type] AS 'Residence_Type',
        [usage_type] AS 'Usage_Type',
        [occupancy] AS 'Occupancy',
        [year_build] AS 'Year_Built',
        [total_living_area] AS 'Total_Living_Area',
        [no_of_units_in_dwelling] AS 'Number_Of_Units_In_Dwelling',
        [heating_system_updated_yr] AS 'Heating_System_Updated_Year',
        [electrical_system_updated_yr] AS 'Electrical_System_Updated_Year',
        [plumbing_system_updated_yr] AS 'Plumbing_System_Updated_Year',
        [distance_to_hydrant] AS 'Distance_To_Hydrant',
        [pricing_tier] AS 'Pricing_Tier',
        [insurance_score] AS 'Insurance_Score',
        [rating_territory_cd] AS 'Rating_Territory_Code',
        [protection_class_cd] AS 'Protection_Class_Code',
        [previous_policy_number] AS 'Previous_Policy_Number',
        [agent_code] AS 'Agent_Code',
        [branch_code] AS 'Branch_Code'
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


