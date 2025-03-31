import shared.timetracking as timetracking
from shared.logger import get_logger
import constants

from datetime import datetime
import pandas as pd
import sqlite3


logger = get_logger(__name__)
id_map_path = constants.id_map_path 



class IDMapFunctions:
    
    def action_router(action_type, batch, response):
        if action_type == 'customer_create':
            IDMapFunctions.customer_id_map_create_record(batch, response)
        elif action_type == 'customer_update':
            IDMapFunctions.customer_id_map_update_record(batch, response)
        elif action_type == 'producer_create':
            IDMapFunctions.producer_id_map_create_record(batch, response)
        elif action_type == 'producer_update':
            IDMapFunctions.customer_id_map_update_record(batch, response)
        elif action_type == 'policy_create':
            IDMapFunctions.policy_id_map_create_record(batch, response)
        elif action_type == 'policy_update':
            IDMapFunctions.policy_id_map_update_record(batch, response)
        elif action_type == 'broker_create':
            IDMapFunctions.broker_id_map_create_record(batch, response)
        elif action_type == 'broker_update':
            IDMapFunctions.broker_id_map_update_record(batch, response)
        elif action_type == 'quote_create':
            IDMapFunctions.quote_id_map_create_record(batch, response)
        elif action_type == 'quote_update':
            IDMapFunctions.quote_id_map_update_record(batch, response)
        elif action_type == 'quote_note_create':
            IDMapFunctions.quote_note_id_map_create_record(batch, response)
        elif action_type == 'quote_note_update':
            IDMapFunctions.quote_note_id_map_update_record(batch, response)

        return

    def customer_id_map_create_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    customer_id = unit_json_response['properties']['customer_id']
                    query = f'''
                    INSERT INTO customer (hs_contact_id, customer_id, broker_id, created, updated)
                    VALUES ('{hs_object_id}', '{customer_id}', '{broker_id}', '{now}', '{now}');
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_object_id = response['properties']['hs_object_id']
                broker_id = response['properties']['broker_id']
                customer_id = response['properties']['customer_id']
                query = f'''
                INSERT INTO customer (hs_contact_id, customer_id, broker_id, created, updated)
                VALUES ('{hs_object_id}', '{customer_id}', '{broker_id}', '{now}', '{now}');
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return
        
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
            

    def customer_id_map_update_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    query = f'''
                    UPDATE customer
                    SET updated = '{now}'
                    WHERE hs_contact_id = '{hs_object_id}'
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_object_id = response['properties']['hs_object_id']
                query = f'''
                UPDATE customer
                SET updated = '{now}'
                WHERE hs_contact_id = '{hs_object_id}'
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return
            
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        

    def producer_id_map_create_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    producer_id = unit_json_response['properties']['producer_id']
                    query = f'''
                    INSERT INTO producer (hs_contact_id, producer_id, broker_id, created, updated)
                    VALUES ('{hs_object_id}', '{producer_id}', '{broker_id}', '{now}', '{now}');
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
                    

            else:
                hs_object_id = response['properties']['hs_object_id']
                broker_id = response['properties']['broker_id']
                producer_id = response['properties']['producer_id']
                query = f'''
                INSERT INTO producer (hs_contact_id, producer_id, broker_id, created, updated)
                VALUES ('{hs_object_id}', '{producer_id}', '{broker_id}', '{now}', '{now}');
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return
            
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")


    def producer_id_map_update_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    query = f'''
                    UPDATE producer
                    SET updated = '{now}'
                    WHERE hs_contact_id = '{hs_object_id}'
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_object_id = response['properties']['hs_object_id']
                query = f'''
                UPDATE producer
                SET updated = '{now}'
                WHERE hs_contact_id = '{hs_object_id}'
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return
            
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")


    def policy_id_map_create_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    policy_no = unit_json_response['properties']['policy_name']
                    customer_id = unit_json_response['properties']['customer_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    query = f'''
                    INSERT INTO policy (hs_object_id, policy_no, customer_id, broker_id, created, updated)
                    VALUES ('{hs_object_id}', '{policy_no}', '{customer_id}', '{broker_id}', '{now}', '{now}');
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_object_id = response['properties']['hs_object_id']
                policy_no = response['properties']['policy_name']
                customer_id = response['properties']['customer_id']
                broker_id = response['properties']['broker_id']
                email = response['properties']['email']
                query = f'''
                INSERT INTO policy (hs_object_id, policy_no, customer_id, broker_id, email, created, updated)
                VALUES ('{hs_object_id}', '{policy_no}', '{customer_id}', '{broker_id}', '{email}', '{now}', '{now}');
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return
            
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")


    def policy_id_map_update_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    query = f'''
                    UPDATE policy
                    SET updated = '{now}'
                    WHERE hs_object_id = '{hs_object_id}'
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_object_id = response['properties']['hs_object_id']
                query = f'''
                UPDATE policy
                SET updated = '{now}'
                WHERE hs_object_id = '{hs_object_id}'
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return
            
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")


    def broker_id_map_create_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_company_id = unit_json_response['properties']['hs_object_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    query = f'''
                    INSERT INTO broker (hs_company_id, broker_id, created, updated)
                    VALUES ('{hs_company_id}', '{broker_id}', '{now}', '{now}');
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_company_id = response['properties']['hs_object_id']
                broker_id = response['properties']['broker_id']
                query = f'''
                INSERT INTO broker (hs_company_id, broker_id, created, updated)
                VALUES ('{hs_company_id}', '{broker_id}', '{now}', '{now}');
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return
            
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")


    def broker_id_map_update_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_company_id = unit_json_response['properties']['hs_object_id']
                    query = f'''
                    UPDATE broker
                    SET updated = '{now}'
                    WHERE hs_company_id = '{hs_company_id}'
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_company_id = response['properties']['hs_object_id']
                query = f'''
                UPDATE broker
                SET updated = '{now}'
                WHERE hs_company_id = '{hs_company_id}'
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return

        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        

    def quote_id_map_create_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    customer_id = unit_json_response['properties']['customer_id']
                    quote_no = unit_json_response['properties']['policy_number']
                    query = f'''
                    INSERT INTO quote (hs_object_id, broker_id, customer_id, quote_no, created, updated)
                    VALUES ('{hs_object_id}', '{broker_id}', '{customer_id}', '{quote_no}', '{now}', '{now}');
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_object_id = response['properties']['hs_object_id']
                broker_id = response['properties']['broker_id']
                customer_id = response['properties']['customer_id']
                quote_no = response['properties']['policy_number']
                query = f'''
                INSERT INTO quote (hs_object_id, broker_id, customer_id, quote_no, created, updated)
                VALUES ('{hs_object_id}', '{broker_id}', '{customer_id}', '{quote_no}', '{now}', '{now}');
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return

        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")


    def quote_id_map_update_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    query = f'''
                    UPDATE quote
                    SET updated = '{now}'
                    WHERE hs_object_id = '{hs_object_id}'
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_object_id = response['properties']['hs_object_id']
                query = f'''
                UPDATE quote
                SET updated = '{now}'
                WHERE hs_object_id = '{hs_object_id}'
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return

        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
       
        
    def quote_note_id_map_create_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['id']#['properties']['hs_object_id']
                    quote_no = unit_json_response['properties']['quote_no']
                    query = f'''
                    INSERT INTO quote_note (hs_note_id, quote_no, created, updated)
                    VALUES ('{hs_object_id}', '{quote_no}', '{now}', '{now}');
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_object_id = response['id']#['properties']['hs_object_id']
                quote_no = response['properties']['quote_no']
                query = f'''
                INSERT INTO quote_note (hs_note_id, quote_no, created, updated)
                VALUES ('{hs_object_id}', '{quote_no}', '{now}', '{now}');
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return

        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")


    def quote_note_id_map_update_record(batch, response):
        now = datetime.now()
        conn = sqlite3.connect(id_map_path)
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    query = f'''
                    UPDATE quote_note
                    SET updated = '{now}'
                    WHERE hs_note_id = '{hs_object_id}'
                    '''
                    conn.execute(query)
                    conn.commit()
                    continue
            else:
                hs_object_id = response['properties']['hs_object_id']
                query = f'''
                UPDATE quote_note
                SET updated = '{now}'
                WHERE hs_note_id = '{hs_object_id}'
                '''
                conn.execute(query)
                conn.commit()
                conn.close()
                return

        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        
