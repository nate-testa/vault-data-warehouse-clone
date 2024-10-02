import argparse
import json
import logging
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.utils.log.logging_mixin import LoggingMixin
from snapsheet_api import SnapsheetAPI



logger = logging.getLogger(__name__) 
# logger.setLevel("DEBUG")


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


def process_claims(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logging.info(f"Executing SQL query: {qry}")
    claims_data = mssql_hook.get_records(qry)
    logging.info(f"Query returned {len(claims_data)} records")

    for record in claims_data:
        (claim_api_sk, claimNumber, claimType, status, policyNumber, datetimeOfLoss, datetimeOfNotification,
         accountCode, lossType, claimIncidentDetails, exposures, vehicles, claimParties) = record
        logging.info(f"Processing claim record: {record}")

        datetimeOfLoss = datetimeOfLoss.strftime('%Y-%m-%dT%H:%M:%SZ') if datetimeOfLoss else None
        datetimeOfNotification = datetimeOfNotification.strftime('%Y-%m-%dT%H:%M:%SZ') if datetimeOfNotification else None

        claimIncidentDetails = json.loads(claimIncidentDetails) if claimIncidentDetails else None
        exposures = json.loads(exposures) if exposures else None
        vehicles = json.loads(vehicles) if vehicles else None
        claimParties = json.loads(claimParties) if claimParties else None

        success, result_text = api.create_claim(claimNumber, claimType, status, policyNumber, datetimeOfLoss,
                                               datetimeOfNotification, accountCode, lossType, claimIncidentDetails,
                                               exposures, vehicles, claimParties)

        if success:
            json_response_claims = json.loads(result_text)
            qry_update_result = f"""
                update edw_stage.migration_create_claim_api 
                set api_process_date = getdate(), api_status = 'Success', 
                    api_Error_description = NULL, 
                    claimReferenceNumber = '{json_response_claims.get("claimReferenceNumber")}'
                where claim_api_sk = '{claim_api_sk}'
            """
        else:
            qry_update_result = f"""
                update edw_stage.migration_create_claim_api 
                set api_process_date = getdate(), api_status = 'Error', 
                    api_Error_description = '{result_text.replace("'","''")}',
                    claimReferenceNumber = NULL
                where claim_api_sk = '{claim_api_sk}'
            """

        logging.info(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)

def process_notes(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logging.info(f"Executing SQL query: {qry}")
    notes_data = mssql_hook.get_records(qry)
    logging.info(f"Query returned {len(notes_data)} records")

    for record in notes_data:
        (note_api_sk, data_json) = record
        logging.info(f"Processing note record: {record}")

        success, result_text = api.create_note(data_json)

        if success:
            json_response_notes = json.loads(result_text)
            qry_update_result = f"""
                update edw_stage.migration_create_a_note_api 
                set api_process_date = getdate(), api_status = 'Success', 
                    api_Error_description = NULL, 
                    id = '{json_response_notes.get("data").get("id")}',
                    api_response = '{result_text.replace("'","''")}'
                where note_api_sk = '{note_api_sk}'
            """
        else:
            qry_update_result = f"""
                update edw_stage.migration_create_a_note_api 
                set api_process_date = getdate(), api_status = 'Error', 
                api_Error_description = '{result_text.replace("'","''")}',
                id = NULL,
                api_response = NULL
                where note_api_sk = '{note_api_sk}'
            """

        logging.info(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)

def process_financial_transactions(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logging.info(f"Executing SQL query: {qry}")
    financial_transaction_data = mssql_hook.get_records(qry)
    logging.info(f"Query returned {len(financial_transaction_data)} records")

    for record in financial_transaction_data:
        (financial_transaction_id, data_json) = record
        logging.info(f"Processing note record: {record}")

        success, result_text = api.create_financial_transaction(data_json)

        if success:
            json_response_notes = json.loads(result_text)
            qry_update_result = f"""
                update edw_stage.migration_create_financial_transaction_api 
                set api_process_date = getdate(), api_status = 'Success', 
                    api_Error_description = NULL, 
                    id = '{json_response_notes.get("data").get("id")}',
                    api_response = '{result_text.replace("'","''")}'
                where financial_transaction_id = '{financial_transaction_id}'
            """
        else:
            qry_update_result = f"""
                update edw_stage.migration_create_financial_transaction_api 
                set api_process_date = getdate(), api_status = 'Error', 
                api_Error_description = '{result_text.replace("'","''")}',
                id = NULL,
                api_response = NULL
                where financial_transaction_id = '{financial_transaction_id}'
            """

        logging.info(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)

def main():
    
    policies_qry = """
        select 
            policyNumber, policyType, status, productCode, inceptionDate, policyEntities, transaction_seq_no
        from edw_integration.claim_policy_search_snapsheet_api
        where api_status = 'pending'
        order by policyNumber, inceptionDate, transaction_seq_no
    """

    claims_qry = """
        select 
            claim_api_sk, claimNumber, claimType, status, policyNumber, datetimeOfLoss, datetimeOfNotification,
            accountCode, lossType, claimIncidentDetails, exposures, vehicles, claimParties
        from edw_stage.migration_create_claim_api
        where api_status = 'pending'
    """

    notes_qry = """
        select 
            note_api_sk, note_json as data
        from edw_stage.migration_create_a_note_api
        where api_status = 'pending'
    """

    financial_transactions_qry = """
        select 
            financial_transaction_id, data
        from edw_stage.migration_create_financial_transaction_api
        where api_status = 'pending'
    """

    parser = argparse.ArgumentParser(description='Execute a snapsheet API')
    parser.add_argument('function', choices=['policies', 'claims', 'notes', 'financial_transactions'], help='The function you want to execute')
    args = parser.parse_args()

    if args.function == 'policies':
        process_policies(policies_qry)
    elif args.function == 'claims':
        process_claims(claims_qry)
    elif args.function == 'notes':
        process_notes(notes_qry)
    elif args.function == 'financial_transactions':
        process_notes(financial_transactions_qry)


if __name__ == '__main__':
    main()
