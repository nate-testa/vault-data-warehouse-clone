import argparse
import logging
from airflow.utils.log.logging_mixin import LoggingMixin
from snapsheet_api import SnapsheetAPI


logger = logging.getLogger(__name__) 
# logger.setLevel("DEBUG")


def update_exposure_data(exposure_id=1043736, claim_handler_data_id="1n0xxQznkLnllgDsL5TwEg"):
    api = SnapsheetAPI(logger=logger)
    data_json = {
        "data": {
            "id": str(exposure_id),
            "type": "exposure",
            "relationships": {
                "claim_handler": {
                    "data": {
                        "id": claim_handler_data_id,
                        "type": "user"
                    }
                }
            }
        }
    }
    
    success, result = api.update_an_exposure(exposure_id, data_json)

    if success:
        logger.info(f"Exposure Data Updated")
    else:
        logger.error(f"Error on update exposure data for exposure_id: {exposure_id}")


def main():
    parser = argparse.ArgumentParser(
        description='Execute Snapsheet API functions to update data'
    )
    parser.add_argument(
        'function',
        choices=['update_exposure_by_id'],
        help='The function you want to execute.'
    )
    parser.add_argument(
        'exposure_id',
        nargs='?',
        default='1234',
        help='The exposure_id. Defaults to 1234.'
    )
    parser.add_argument(
        'claim_handler_data_id',
        nargs='?',
        default='1234',
        help='The claim_handler_data_id. Defaults to 1234.'
    )
    args = parser.parse_args()

    if args.function == 'update_exposure_by_id':
        update_exposure_data(args.exposure_id, args.claim_handler_data_id)
    

if __name__ == '__main__':
    main()