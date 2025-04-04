import shared.timetracking as timetracking
import constants

import pandas as pd
import pymssql
import re


class DatabaseFunctions:

    table_name = {
        'broker': 'edw_integration.broker_hubspot_feed',
        'customer': 'edw_integration.customer_hubspot_feed',
        'producer': 'edw_integration.producer_hubspot_feed',
        'quote': 'edw_integration.quote_hubspot_feed',
        'quote_note': 'edw_integration.quote_note_hubspot_feed',
        'broker_relation': 'edw_integration.broker_relation_hubspot_feed',
        'policy': 'edw_integration.customer_hubspot_feed'
    }

    def get_data_from_db(table_name):
        timestamp = timetracking.load_previous_timestamp()
        conn = pymssql.connect(
        host=rf'{constants.HOST}',
        user=rf'{constants.USERNAME}',
        password=rf'{constants.PASS}',
        database='vault_edw'
        )
        sql = f'''
        SELECT * FROM {table_name}
        WHERE update_ts >= '{timestamp}'
        '''
        df = pd.read_sql_query(sql, conn, dtype=object)
        conn.close()
        df = df.fillna('') # replace null values with blank strings
        return df
    
    def strip_html_tags(text):
        clean = re.compile('<.*?>')
        return re.sub(clean, '', text)

