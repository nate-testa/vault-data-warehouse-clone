import argparse
import json
import logging
import multiprocessing
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.utils.log.logging_mixin import LoggingMixin
from snapsheet_api import SnapsheetAPI



logger = logging.getLogger(__name__) 
# logger.setLevel("DEBUG")

policies_qry = """
        SELECT
            policyNumber, policyType, status, productCode, inceptionDate, policyEntities, transaction_seq_no
        FROM 
        (
            select 
                policyNumber, 
                policyType, 
                status, 
                productCode, 
                inceptionDate, 
                policyEntities, 
                transaction_seq_no,
                ROW_NUMBER() OVER (PARTITION BY policyNumber , inceptionDate ORDER BY transaction_seq_no DESC) AS rank
            from 
                edw_integration.claim_policy_search_snapsheet_api
            where api_status in ('pending')
            and 1=1
        ) a 
        WHERE a.rank = 1
    """

def process_policies(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logger.info(f"Retrieving policy data for processing")
    policy_data = mssql_hook.get_records(qry)
    logger.info(f"Number of records for processing: {len(policy_data)}")

    for record in policy_data:
        (policyNumber, policyType, status, productCode, inceptionDate, policyEntities, transaction_seq_no) = record
        logger.info(f"*************** Start Processing *********************")
        logger.info(f"Processing policy record: {record}")

        inceptionDate = inceptionDate.strftime('%Y-%m-%dT%H:%M:%SZ') if inceptionDate else None
        policyEntities = json.loads(policyEntities) if policyEntities else None

        # call API function
        success, result_text = api.create_policy(policyNumber, policyType, status, productCode, inceptionDate, policyEntities)

        if success:
            qry_update_result = f"""
                update edw_integration.claim_policy_search_snapsheet_api
                set update_ts = getdate(), api_status = 'Success', api_Error_description = NULL
                where policyNumber = '{policyNumber}'
                and inceptionDate = '{inceptionDate}'
            """
        else:
            qry_update_result = f"""
                update edw_integration.claim_policy_search_snapsheet_api
                set update_ts = getdate(), api_status = 'Error',
                api_Error_description = '{result_text.replace("'","''")}'
                where policyNumber = '{policyNumber}'
                and inceptionDate = '{inceptionDate}'
            """

        logger.debug(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)


def process_snapsheet_policies():
    process_policies(policies_qry)

def process_snapsheet_policies_parallel():
    
    process_ls = []

    for i in range(3): # Create 3 processes
        if i == 0:
            policies_qry_1 = policies_qry.replace('and 1=1', 'and id between 1 and 50000')
            p = multiprocessing.Process(target=process_policies, args=(policies_qry_1,))
        elif i == 1:
            policies_qry_2 = policies_qry.replace('and 1=1', 'and id between 50001 and 10000')
            p = multiprocessing.Process(target=process_policies, args=(policies_qry_2,))
        elif i == 2:
            policies_qry_3 = policies_qry.replace('and 1=1', 'and id > 10000')
            p = multiprocessing.Process(target=process_policies, args=(policies_qry_3,))        

        process_ls.append(p)  # save process
        p.start()  # start process

    for p in process_ls:
        p.join()  # wait for all processes to finish

    print("All process have finished.")
    

def main():

    parser = argparse.ArgumentParser(description='Execute a snapsheet API')
    parser.add_argument('function', choices=['policies'], help='The function you want to execute')
    args = parser.parse_args()

    if args.function == 'policies':
        process_policies(policies_qry)


if __name__ == '__main__':
    main()

