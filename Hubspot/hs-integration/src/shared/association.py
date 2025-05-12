from shared.id_map import id_map_path
import shared.timetracking as timetracking
import constants

import pandas as pd
import sqlite3



class Association:
    
    association_type_id = {
        "customer-broker": 27, #21
        "customer-policy": 24, #25
        "customer-quote": 30, #28
        "producer-broker": 25, #23
        "broker-policy": 22, #37
        "broker-quote": 36, #34
        "broker-parent-child": 33, #41
        "parent-child-notes": 189 
    }


    def get_associations(table1, id1, table2, id2, key_column):
        timestamp = timetracking.load_previous_timestamp()
        conn = sqlite3.connect(id_map_path)
        # query = f'''                
        # SELECT CT.{id1}, CM.{id2}
        # FROM {table2} CM
        # INNER JOIN {table1} CT
        # ON CT.{key_column} = CM.{key_column}
        # '''
        #live query with timestamp parameters below (so as not to associate id map every time but just what was updated since the last run)
        query = f'''
                SELECT CT.{id1}, CM.{id2}
                FROM {table2} CM
                INNER JOIN {table1} CT
                ON CT.{key_column} = CM.{key_column} AND
                (CT.updated >= '{timestamp}' OR CM.updated >= '{timestamp}')
                '''
        results_df = pd.read_sql_query(query, conn)
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
        
        #### quote notes do not need this because they are associated when they are created


        return from_object, to_object, association_id