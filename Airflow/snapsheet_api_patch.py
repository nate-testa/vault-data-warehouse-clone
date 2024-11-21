import argparse
import logging
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from snapsheet_api import SnapsheetAPI


logger = logging.getLogger(__name__) 
logger.setLevel("DEBUG")


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

def main():

    update_exposure_adjuster_qry = """
        select 
            exposureReferenceNumber, data
        from edw_stage.migration_update_exposure_adjuster_api
        where api_status  in ('Error', 'pending')
    """

    update_exposure_status_qry = """
        select 
            exposureReferenceNumber, data
        from edw_stage.migration_update_exposure_status_api
        where api_status  in ('Error', 'pending')
    """

    parser = argparse.ArgumentParser(
        description='Execute Snapsheet API functions to update data'
    )
    parser.add_argument(
        'function',
        choices=['exposure_adjuster','exposure_status'],
        help='The function you want to execute.'
    )
    args = parser.parse_args()

    if args.function == 'exposure_adjuster':
        exposure_adjuster(update_exposure_adjuster_qry)
    elif args.function == 'exposure_status':
        exposure_status(update_exposure_status_qry)
    

if __name__ == '__main__':
    main()
