import argparse
import logging
from airflow.utils.log.logging_mixin import LoggingMixin
from snapsheet_api import SnapsheetAPI


logger = logging.getLogger(__name__) 
# logger.setLevel("DEBUG")

def get_claim_by_id(claim_id):
    
    api = SnapsheetAPI(logger=logger)
    success, claim_data = api.fetch_a_claim(claim_id)

    if success:
        logging.info(f"Claim Data: {claim_data}")
    else:
        logging.error(f"No data found for Claim ID: {claim_id}")

    return claim_data

def get_exposure_by_id(exposure_id):
    
    api = SnapsheetAPI(logger=logger)
    success, exposure_data = api.fetch_an_exposure(exposure_id)

    if success:
        logging.info(f"Exposure Data: {exposure_data}")
    else:
        logging.error(f"No data found for Exposure ID: {exposure_id}")

    return exposure_data

def get_exposures_by_claim_id(claim_id):

    api = SnapsheetAPI(logger=logger)
    success, exposures_data = api.list_exposures(claim_id)

    if success:
        logging.info(f"List of Exposures Data: {exposures_data}")
    else:
        logging.error(f"No Exposures data found for claim ID: {claim_id}")

    return exposures_data


def main():
    parser = argparse.ArgumentParser(
        description='Execute Snapsheet API functions to retrieve data'
    )
    parser.add_argument(
        'function',
        choices=['get_claim_by_id','get_exposure_by_id','get_exposures_by_claim_id'],
        help='The function you want to execute.'
    )
    parser.add_argument(
        'number',
        nargs='?',
        default='1234',
        help='The number related to the function. Defaults to 1234.'
    )
    args = parser.parse_args()

    if args.function == 'get_claim_by_id':
        get_claim_by_id(args.number)
    if args.function == 'get_exposure_by_id':
        get_exposure_by_id(args.number)
    if args.function == 'get_exposures_by_claim_id':
        get_exposures_by_claim_id(args.number)


if __name__ == '__main__':
    main()
