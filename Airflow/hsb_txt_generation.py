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
        hcp.[company_product_cd] AS 'Product Code',
        hcp.[product_nm] AS 'Product Name',
        hcp.[contract_no] AS 'ContractNumber',
        hcp.[policy_no] AS 'PolicyNumber',
        p.[effective_dt] AS 'CoverageEffDate',
        hcp.[coverage_expiration_dt] AS 'CoverageExpDate',
        hcp.[insured_nm] AS 'NameofInsured',
        hcp.[dwelling_address] AS 'DwellingAddress',
        hcp.[dwelling_city] AS 'DwellingCity',
        hcp.[dwelling_state] AS 'DwellingState',
        hcp.[dwelling_zip_cd] AS 'DwellingZipCode',
        hcp.[hcp_net_premium_amt] AS 'NetPremiumAmount',
        hcp.[hcp_deductible_amt] AS 'DeductibleAmount',
        hcp.[coverage_a_value] AS 'CoverageAVAlue',
        hcp.[slc_limit_amt] AS 'HCP Limit Amount',
        hcp.[homeowner_policy_form_no] AS 'HO Policy Number',
        hcp.[product_form_no] AS 'HO Product Form Number',
        hcp.[client_product_nm] AS 'Client Product Name',
        hcp.[dwelling_type] AS 'Dwelling Type',
        hcp.[base_homeowner_premium] AS 'Base HO Premium',
        hcp.[final_homeowner_premium] AS 'Fnal HO Premium',
        hcp.[policy_deductible] AS 'HO Deductible',
        hcp.[year_build] AS 'Contruction Year',
        hcp.[total_living_area] AS 'Square Footage',
        hcp.[no_of_units_in_dwelling] AS 'Number of Units In Building',
        hcp.[email_address] AS 'Email Address',
        hcp.[home_business] AS 'Home Business',
        hcp.[previous_policy_number] AS 'Previous Policy Number'
    FROM [edw_integration].[policy_hsb_cyber_feed] AS hcp
    INNER JOIN edw_core.tpolicy AS p ON hcp.policy_no = p.policy_no
"""
QRY_HSP = f"""
    SELECT 
        hsp.[company_product_cd] AS 'Company_Product_Code',
        hsp.[product_nm] AS 'Product_Name',
        hsp.[contract_no] AS 'Contract_Number',
        hsp.[policy_no] AS 'Policy_Number',
        hsp.[homeowner_policy_effective_dt] AS 'Homeowner_Policy_Effective_Date',
        hsp.[homeowner_policy_expiration_dt] AS 'Homeowner_Policy_Expiration_Date',
        p.[effective_dt] AS 'HSP_Coverage_Effective_Date',
        p.[effective_dt] AS 'Original_Homeowner_Policy_Effective_Date',
        hsp.[prior_homeowner_insurance_ind] AS 'Prior_Homeowner_Insurance_Indicator',
        hsp.[insured_nm] AS 'Name_Of_Insured',
        hsp.[dwelling_address] AS 'Dwelling_Address',
        hsp.[dwelling_city] AS 'Dwelling_City',
        hsp.[dwelling_state] AS 'Dwelling_State',
        hsp.[dwelling_zip_cd] AS 'Dwelling_Zip_Code',
        hsp.[hsp_net_premium_amt] AS 'HSP_Net_Premium_Amount',
        hsp.[hsp_limit_amt] AS 'HSP_Limit_Amount',
        '500' AS 'HSP_Deductible_Amount',
        hsp.[base_homeowner_premium] AS 'Base_Homeowner_Premium',
        hsp.[final_homeowner_premium] AS 'Final_Homeowner_Premium',
        hsp.[policy_deductible] AS 'Homeowner_Policy_Deductible',
        hsp.[coverage_a_value] AS 'Coverage_A_Value',
        hsp.[coverage_b_value] AS 'Coverage_B_Value',
        hsp.[coverage_c_value] AS 'Coverage_C_Value',
        hsp.[homeowner_policy_form_no] AS 'Homeowner_Policy_Form_Number',
        hsp.[homeowners_or_dwelling_fire_policy_form_type] AS 'Homeowners_Policy_Form_Type',
        hsp.[product_form_no] AS 'HSP_Product_Form_Number',
        hsp.[client_product_nm] AS 'Client_Product_Name',
        CASE 
            WHEN p.product_cd = 'HO' THEN 'Dwelling'
            WHEN p.product_cd = 'CO' THEN 'Condo'
        END AS 'Residence_Type',
        CASE 
            WHEN hsp.occupancy IN ('Primary','Vacant') THEN 'Primary'
            WHEN hsp.occupancy IN ('Rented to others','Partially Rented to Others') THEN 'Secondary'
            WHEN hsp.occupancy LIKE 'Seasonal%' THEN 'Season'
        END AS 'Usage_Type',
        CASE 
            WHEN hsp.residence_type = 'Tenant' THEN 'Tenant'
            WHEN hsp.occupancy = 'Vacant' THEN 'Vacant'
            WHEN hsp.occupancy IN ('Primary','Rented to Others','Partially Rented to Others') THEN 'Owner'
            WHEN hsp.occupancy LIKE 'Seasonal%' THEN 'Seasonal'
        END AS 'Occupancy',
        hsp.[year_build] AS 'Year_Built',
        hsp.[total_living_area] AS 'Total_Living_Area',
        hsp.[no_of_units_in_dwelling] AS 'Number_Of_Units_In_Dwelling',
        hsp.[heating_system_updated_yr] AS 'Heating_System_Updated_Year',
        hsp.[electrical_system_updated_yr] AS 'Electrical_System_Updated_Year',
        hsp.[plumbing_system_updated_yr] AS 'Plumbing_System_Updated_Year',
        hsp.[distance_to_hydrant] AS 'Distance_To_Hydrant',
        hsp.[pricing_tier] AS 'Pricing_Tier',
        hsp.[insurance_score] AS 'Insurance_Score',
        hsp.[rating_territory_cd] AS 'Rating_Territory_Code',
        hsp.[protection_class_cd] AS 'Protection_Class_Code',
        hsp.[previous_policy_number] AS 'Previous_Policy_Number',
        hsp.[agent_code] AS 'Agent_Code',
        hsp.[branch_code] AS 'Branch_Code'
    FROM [edw_integration].[policy_hsb_hsp_feed] AS hsp
    INNER JOIN edw_core.tpolicy AS p ON hsp.policy_no = p.policy_no
"""
QRY_SLC = f"""
    SELECT 
        slc.[company_product_cd] AS 'Company_Product_Code',
        slc.[product_nm] AS 'Product_Name',
        slc.[contract_no] AS 'Contract_Number',
        slc.[policy_no] AS 'Policy_Number',
        slc.[homeowner_policy_effective_dt] AS 'Homeowner_Policy_Effective_Date',
        slc.[homeowner_policy_expiration_dt] AS 'Homeowner_Policy_Expiration_Date',
        p.[effective_dt] AS 'HSP_Coverage_Effective_Date',
        p.[effective_dt] AS 'Original_Homeowner_Policy_Effective_Date',
        slc.[prior_homeowner_insurance_ind] AS 'Prior_Homeowner_Insurance_Indicator',
        slc.[insured_nm] AS 'Name_Of_Insured',
        slc.[dwelling_address] AS 'Dwelling_Address',
        slc.[dwelling_city] AS 'Dwelling_City',
        slc.[dwelling_state] AS 'Dwelling_State',
        slc.[dwelling_zip_cd] AS 'Dwelling_Zip_Code',
        slc.[slc_net_premium_amt] AS 'HSP_Net_Premium_Amount',
        slc.[slc_limit_amt] AS 'HSP_Limit_Amount',
        slc.[slc_deductible_amt] AS 'HSP_Deductible_Amount',
        slc.[base_homeowner_premium] AS 'Base_Homeowner_Premium',
        slc.[final_homeowner_premium] AS 'Final_Homeowner_Premium',
        slc.[policy_deductible] AS 'Homeowner_Policy_Deductible',
        slc.[coverage_a_value] AS 'Coverage_A_Value',
        slc.[coverage_b_value] AS 'Coverage_B_Value',
        slc.[coverage_c_value] AS 'Coverage_C_Value',
        slc.[homeowner_policy_form_no] AS 'Homeowner_Policy_Form_Number',
        slc.[homeowners_or_dwelling_fire_policy_form_type] AS 'Homeowners_Policy_Form_Type',
        slc.[product_form_no] AS 'HSP_Product_Form_Number',
        slc.[client_product_nm] AS 'Client_Product_Name',
        CASE 
            WHEN p.product_cd = 'HO' THEN 'Dwelling'
            WHEN p.product_cd = 'CO' THEN 'Condo'
        END AS 'Residence_Type',
        CASE 
            WHEN slc.occupancy IN ('Primary','Vacant') THEN 'Primary'
            WHEN slc.occupancy IN ('Rented to others','Partially Rented to Others') THEN 'Secondary'
            WHEN slc.occupancy LIKE 'Seasonal%' THEN 'Season'
        END AS 'Usage_Type',
        CASE 
            WHEN slc.residence_type = 'Tenant' THEN 'Tenant'
            WHEN slc.occupancy = 'Vacant' THEN 'Vacant'
            WHEN slc.occupancy IN ('Primary','Rented to Others','Partially Rented to Others') THEN 'Owner'
            WHEN slc.occupancy LIKE 'Seasonal%' THEN 'Seasonal'
        END AS 'Occupancy',
        slc.[year_build] AS 'Year_Built',
        slc.[total_living_area] AS 'Total_Living_Area',
        slc.[no_of_units_in_dwelling] AS 'Number_Of_Units_In_Dwelling',
        slc.[heating_system_updated_yr] AS 'Heating_System_Updated_Year',
        slc.[electrical_system_updated_yr] AS 'Electrical_System_Updated_Year',
        slc.[plumbing_system_updated_yr] AS 'Plumbing_System_Updated_Year',
        slc.[distance_to_hydrant] AS 'Distance_To_Hydrant',
        slc.[pricing_tier] AS 'Pricing_Tier',
        slc.[insurance_score] AS 'Insurance_Score',
        slc.[rating_territory_cd] AS 'Rating_Territory_Code',
        slc.[protection_class_cd] AS 'Protection_Class_Code',
        slc.[previous_policy_number] AS 'Previous_Policy_Number',
        slc.[agent_code] AS 'Agent_Code',
        slc.[branch_code] AS 'Branch_Code'
    FROM [edw_integration].[policy_hsb_slc_feed] AS slc
    INNER JOIN edw_core.tpolicy AS p ON slc.policy_no = p.policy_no
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


