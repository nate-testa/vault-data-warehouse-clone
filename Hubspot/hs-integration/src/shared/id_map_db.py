import pymssql
import constants
from shared.logger import get_logger

logger = get_logger(__name__)

ID_MAP_SCHEMA = 'edw_hubspot'
STAGING_SCHEMA = 'edw_stage'


def get_id_map_connection():
    """Get a pymssql connection to the SQL Server id_map database."""
    return pymssql.connect(
        host=constants.HOST,
        user=constants.USERNAME,
        password=constants.PASS,
        database=constants.DB
    )
