import argparse
import logging
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from snapsheet_api import SnapsheetAPI


logger = logging.getLogger(__name__) 
# logger.setLevel("DEBUG")

# -- Q U E R I E S --
update_exposure_adjuster_qry = """
        select 
            exposureReferenceNumber, data
        from edw_stage.migration_update_exposure_adjuster_api
        where api_status  in ('pending')
    """

update_exposure_status_qry = """
        select 
            exposureReferenceNumber, data
        from edw_stage.migration_update_exposure_status_api
        where api_status  in ('pending')
    """

update_claim_status_qry = """
        select 
            id, data
        from edw_stage.migration_create_claim_api_update_status
        where api_status  in ('pending')
    """

update_claim_catastrophe_qry = """
        select 
            claimRerenceNumber, data
        from edw_stage.migration_create_claim_api_update_catastrophe
        where api_status  in ('pending')
    """

update_claim_party_qry = """
        select 
            claimpartyreferencenumber, data
        from edw_stage.migration_create_claim_party_update_api
        where api_status  in ('pending')
    """

def exposure_adjuster(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logger.info(f"Executing SQL query: {qry}")
    update_exposure_adjuster = mssql_hook.get_records(qry)
    logger.info(f"Query returned {len(update_exposure_adjuster)} records")

    for record in update_exposure_adjuster:
        (exposureReferenceNumber, data) = record
        logger.info(f"*************** Start Processing *********************")
        logger.info(f"Processing exposure record: {record}")

        success, result_text = api.update_an_exposure(exposureReferenceNumber, data)

        if success:
            qry_update_result = f"""
                update edw_stage.migration_update_exposure_adjuster_api 
                set update_ts = getdate(), api_status = 'Success', 
                    api_Error_description = NULL, 
                    api_response = '{result_text.replace("'","''")}'
                where exposureReferenceNumber = '{exposureReferenceNumber}'
            """
        else:
            qry_update_result = f"""
                update edw_stage.migration_update_exposure_adjuster_api 
                set update_ts = getdate(), api_status = 'Error', 
                    api_Error_description = '{result_text.replace("'","''")}',
                    api_response = NULL
                where exposureReferenceNumber = '{exposureReferenceNumber}'
            """

        logger.info(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)

def exposure_status(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logger.info(f"Executing SQL query: {qry}")
    update_exposure_status = mssql_hook.get_records(qry)
    logger.info(f"Query returned {len(update_exposure_status)} records")

    for record in update_exposure_status:
        (exposureReferenceNumber, data) = record
        logger.info(f"*************** Start Processing *********************")
        logger.info(f"Processing exposure record: {record}")

        success, result_text = api.update_an_exposure(exposureReferenceNumber, data)

        if success:
            qry_update_result = f"""
                update edw_stage.migration_update_exposure_status_api 
                set update_ts = getdate(), api_status = 'Success', 
                    api_Error_description = NULL, 
                    api_response = '{result_text.replace("'","''")}'
                where exposureReferenceNumber = '{exposureReferenceNumber}'
            """
        else:
            qry_update_result = f"""
                update edw_stage.migration_update_exposure_status_api 
                set update_ts = getdate(), api_status = 'Error', 
                    api_Error_description = '{result_text.replace("'","''")}',
                    api_response = NULL
                where exposureReferenceNumber = '{exposureReferenceNumber}'
            """

        logger.info(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)

def claim_status(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logger.info(f"Executing SQL query: {qry}")
    update_claim_status = mssql_hook.get_records(qry)
    logger.info(f"Query returned {len(update_claim_status)} records")

    for record in update_claim_status:
        (id, data) = record
        logger.info(f"*************** Start Processing *********************")
        logger.info(f"Processing claim record: {record}")

        success, result_text = api.update_a_claim(id, data)

        if success:
            qry_update_result = f"""
                update edw_stage.migration_create_claim_api_update_status 
                set update_ts = getdate(), api_status = 'Success', 
                    api_Error_description = NULL, 
                    api_response = '{result_text.replace("'","''")}'
                where id = '{id}'
            """
        else:
            qry_update_result = f"""
                update edw_stage.migration_create_claim_api_update_status 
                set update_ts = getdate(), api_status = 'Error', 
                    api_Error_description = '{result_text.replace("'","''")}',
                    api_response = NULL
                where id = '{id}'
            """

        logger.info(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)

def claim_catastrophe(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logger.info(f"Executing SQL query: {qry}")
    update_claim_catastrophe = mssql_hook.get_records(qry)
    logger.info(f"Query returned {len(update_claim_catastrophe)} records")

    for record in update_claim_catastrophe:
        (claimReferenceNumber, data) = record
        logger.info(f"*************** Start Processing *********************")
        logger.info(f"Processing claim record: {record}")

        success, result_text = api.update_a_claim(claimReferenceNumber, data)

        if success:
            qry_update_result = f"""
                update edw_stage.migration_create_claim_api_update_catastrophe 
                set update_ts = getdate(), api_status = 'Success', 
                    api_Error_description = NULL, 
                    api_response = '{result_text.replace("'","''")}'
                where claimRerenceNumber = '{claimReferenceNumber}'
            """
        else:
            qry_update_result = f"""
                update edw_stage.migration_create_claim_api_update_catastrophe 
                set update_ts = getdate(), api_status = 'Error', 
                    api_Error_description = '{result_text.replace("'","''")}',
                    api_response = NULL
                where claimRerenceNumber = '{claimReferenceNumber}'
            """

        logger.info(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)

def claim_party(qry):
    api = SnapsheetAPI(logger=logger)
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    logger.info(f"Executing SQL query: {qry}")
    update_claim_party = mssql_hook.get_records(qry)
    logger.info(f"Query returned {len(update_claim_party)} records")

    for record in update_claim_party:
        (claimpartyreferencenumber, data) = record
        logger.info(f"*************** Start Processing *********************")
        logger.info(f"Processing claim party record: {record}")

        success, result_text = api.update_a_claim_party(claimpartyreferencenumber, data)

        if success:
            qry_update_result = f"""
                update edw_stage.migration_create_claim_party_update_api 
                set update_ts = getdate(), api_status = 'Success', 
                    api_error_description = NULL, 
                    api_response = '{result_text.replace("'","''")}'
                where claimpartyreferencenumber = '{claimpartyreferencenumber}'
            """
        else:
            qry_update_result = f"""
                update edw_stage.migration_create_claim_party_update_api 
                set update_ts = getdate(), api_status = 'Error', 
                    api_error_description = '{result_text.replace("'","''")}',
                    api_response = NULL
                where claimpartyreferencenumber = '{claimpartyreferencenumber}'
            """

        logger.info(f"Executing update query: {qry_update_result}")
        mssql_hook.run(qry_update_result)

def main():

    parser = argparse.ArgumentParser(
        description='Execute Snapsheet API functions to update data'
    )
    parser.add_argument(
        'function',
        choices=['exposure_adjuster','exposure_status','claim_status','claim_catastrophe','claim_party'],
        help='The function you want to execute.'
    )
    args = parser.parse_args()

    if args.function == 'exposure_adjuster':
        exposure_adjuster(update_exposure_adjuster_qry)
    elif args.function == 'exposure_status':
        exposure_status(update_exposure_status_qry)
    elif args.function == 'claim_status':
        claim_status(update_claim_status_qry)
    elif args.function == 'claim_catastrophe':
        claim_catastrophe(update_claim_catastrophe_qry)
    elif args.function == 'claim_party':
        claim_party(update_claim_party_qry)
    

if __name__ == '__main__':
    main()
