import argparse
import json
import logging
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.utils.log.logging_mixin import LoggingMixin
from snapsheet_api import SnapsheetAPI



logger = logging.getLogger(__name__) 
logger.setLevel("DEBUG")


def process_policies(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logger.info(f"Retrieving policy data for processing")
    policy_data = mssql_hook.get_records(qry)
    logger.info(f"Number of records for processing: {len(policy_data)}")

    for record in policy_data:
        (policyNumber, policyType, status, productCode, inceptionDate, policyEntities, transaction_seq_no) = record
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
                and transaction_seq_no = '{transaction_seq_no}'
            """
        else:
            qry_update_result = f"""
                update edw_integration.claim_policy_search_snapsheet_api 
                set update_ts = getdate(), api_status = 'Error', 
                api_Error_description = '{result_text.replace("'","''")}' 
                where policyNumber = '{policyNumber}'
                and inceptionDate = '{inceptionDate}'
                and transaction_seq_no = '{transaction_seq_no}'
            """

        logger.debug(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)



def main():
    
    policies_qry = """
        select 
            policyNumber, policyType, status, productCode, inceptionDate, policyEntities, transaction_seq_no
        from edw_integration.claim_policy_search_snapsheet_api
        where api_status in ('Error','pending') and policyNumber = 'HO200030328' 
        order by policyNumber, inceptionDate, transaction_seq_no
    """

    parser = argparse.ArgumentParser(description='Execute a snapsheet API')
    parser.add_argument('function', choices=['policies'], help='The function you want to execute')
    args = parser.parse_args()

    if args.function == 'policies':
        process_policies(policies_qry)


if __name__ == '__main__':
    main()

