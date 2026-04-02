from shared.id_map_db import get_id_map_connection, ID_MAP_SCHEMA
import shared.timetracking as timetracking
import constants

import pandas as pd



class Association:
    
    # Environment-specific association type IDs
    # These IDs differ between HubSpot sandbox and production environments
    if constants.ENVIRONMENT == 'PRODUCTION':
        association_type_id = {
            "customer-broker": 27,
            "customer-policy": 24,
            "customer-quote": 30,
            "producer-broker": 25,
            "broker-policy": 22,
            "broker-quote": 36,
            "broker-parent-child": 33,
            "parent-child-notes": 190,
            "quote-producer": 37,
            "policy-producer": 39
        }
    else:  # UAT
        association_type_id = {
            "customer-broker": 31,
            "customer-policy": 35,
            "customer-quote": 26,
            "producer-broker": 23,
            "broker-policy": 34,
            "broker-quote": 37,
            "broker-parent-child": 27,
            "parent-child-notes": 190,
            "quote-producer": 22,
            "policy-producer": 30
        }
    # Note: Update sandbox values above if they differ from production


    def get_associations(table1, id1, table2, id2, key_column):
        S = ID_MAP_SCHEMA
        timestamp = timetracking.load_previous_timestamp()
        conn = get_id_map_connection()
        #live query with timestamp parameters below (so as not to associate id map every time but just what was updated since the last run)
        query = f'''
                SELECT CT.{id1}, CM.{id2}
                FROM {S}.{table2} CM
                INNER JOIN {S}.{table1} CT
                ON CT.{key_column} = CM.{key_column} AND
                (CT.updated >= %s OR CM.updated >= %s)
                '''
        results_df = pd.read_sql_query(query, conn, params=(timestamp, timestamp))
        conn.close()
        return results_df
    

    def build_association_payload(from_id, to_id, association_type_id, association_category='USER_DEFINED'):
        payload = {
            'types': [
            {
                    'associationCategory': f'{association_category}',
                    'associationTypeId': f'{association_type_id}',
            },
            ],
            'from': 
            {
                'id': f'{from_id}',
            },
            'to': 
            {
                'id': f'{to_id}',
            },
        }
        return payload


    def route_associations(object_type):
        if object_type == 'customer-broker-association':
            from_object = constants.object_map['customer']
            to_object = constants.object_map['broker']
            association_id = Association.association_type_id['customer-broker']

        elif object_type == 'customer-policy-association':
            from_object = constants.object_map['customer']
            to_object = constants.object_map['policy']
            association_id = Association.association_type_id['customer-policy']

        elif object_type == 'customer-quote-association':
            from_object = constants.object_map['quote']
            to_object = constants.object_map['customer']
            association_id = Association.association_type_id['customer-quote']

        elif object_type == 'producer-broker-association':
            from_object = constants.object_map['producer']
            to_object = constants.object_map['broker']
            association_id = Association.association_type_id['producer-broker']

        elif object_type == 'broker-policy-association':
            from_object = constants.object_map['broker']
            to_object = constants.object_map['policy']
            association_id = Association.association_type_id['broker-policy']

        elif object_type == 'broker-quote-association':
            from_object = constants.object_map['quote']
            to_object = constants.object_map['broker']
            association_id = Association.association_type_id['broker-quote']

        elif object_type == 'broker-parent-child-association':
            from_object = constants.object_map['broker']
            to_object = constants.object_map['broker']
            association_id = Association.association_type_id['broker-parent-child']
            
        elif object_type == 'parent-child-notes-association':
            from_object = constants.object_map['notes']
            to_object = constants.object_map['broker']
            association_id = Association.association_type_id['parent-child-notes']
        
        elif object_type == 'quote-producer-association':
            from_object = constants.object_map['quote']     # 'deal'
            to_object = constants.object_map['producer']    # 'contact'
            association_id = Association.association_type_id['quote-producer']
        
        elif object_type == 'policy-producer-association':
            from_object = constants.object_map['policy']    # custom object ID
            to_object = constants.object_map['producer']    # 'contact'
            association_id = Association.association_type_id['policy-producer']
        
        #### quote notes do not need this because they are associated when they are created


        return from_object, to_object, association_id
