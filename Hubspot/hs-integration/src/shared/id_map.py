import shared.timetracking as timetracking
from shared.logger import get_logger
from shared.id_map_db import get_id_map_connection, ID_MAP_SCHEMA

from datetime import datetime
import pandas as pd


logger = get_logger(__name__)

S = ID_MAP_SCHEMA  # short alias for schema prefix



class IDMapFunctions:
    
    def action_router(action_type, batch, response, request_data=None):
        if action_type == 'customer_create':
            IDMapFunctions.customer_id_map_create_record(batch, response)
        elif action_type == 'customer_update':
            IDMapFunctions.customer_id_map_update_record(batch, response)
        elif action_type == 'producer_create':
            IDMapFunctions.producer_id_map_create_record(batch, response)
        elif action_type == 'producer_update':
            IDMapFunctions.customer_id_map_update_record(batch, response)
        elif action_type == 'policy_create':
            IDMapFunctions.policy_id_map_create_record(batch, response, request_data)
        elif action_type == 'policy_update':
            IDMapFunctions.policy_id_map_update_record(batch, response, request_data)
        elif action_type == 'broker_create':
            IDMapFunctions.broker_id_map_create_record(batch, response)
        elif action_type == 'broker_update':
            IDMapFunctions.broker_id_map_update_record(batch, response)
        elif action_type == 'quote_create':
            IDMapFunctions.quote_id_map_create_record(batch, response, request_data)
        elif action_type == 'quote_update':
            IDMapFunctions.quote_id_map_update_record(batch, response, request_data)
        elif action_type == 'quote_note_create':
            IDMapFunctions.quote_note_id_map_create_record(batch, response)
        elif action_type == 'quote_note_update':
            IDMapFunctions.quote_note_id_map_update_record(batch, response)

        return


    def customer_id_map_create_record(batch, response):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    customer_id = unit_json_response['properties']['customer_id']
                    conn.cursor().execute(
                        f"INSERT INTO {S}.customer (hs_contact_id, customer_id, broker_id, created, updated) VALUES (%s, %s, %s, %s, %s)",
                        (hs_object_id, customer_id, broker_id, now, now)
                    )
                    conn.commit()
            else:
                hs_object_id = response['properties']['hs_object_id']
                broker_id = response['properties']['broker_id']
                customer_id = response['properties']['customer_id']
                conn.cursor().execute(
                    f"INSERT INTO {S}.customer (hs_contact_id, customer_id, broker_id, created, updated) VALUES (%s, %s, %s, %s, %s)",
                    (hs_object_id, customer_id, broker_id, now, now)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()


    def customer_id_map_update_record(batch, response):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    conn.cursor().execute(
                        f"UPDATE {S}.customer SET updated = %s WHERE hs_contact_id = %s",
                        (now, hs_object_id)
                    )
                    conn.commit()
            else:
                hs_object_id = response['properties']['hs_object_id']
                conn.cursor().execute(
                    f"UPDATE {S}.customer SET updated = %s WHERE hs_contact_id = %s",
                    (now, hs_object_id)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()
        

    def producer_id_map_create_record(batch, response):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    producer_id = unit_json_response['properties']['producer_id']
                    conn.cursor().execute(
                        f"INSERT INTO {S}.producer (hs_contact_id, producer_id, broker_id, created, updated) VALUES (%s, %s, %s, %s, %s)",
                        (hs_object_id, producer_id, broker_id, now, now)
                    )
                    conn.commit()
            else:
                hs_object_id = response['properties']['hs_object_id']
                broker_id = response['properties']['broker_id']
                producer_id = response['properties']['producer_id']
                conn.cursor().execute(
                    f"INSERT INTO {S}.producer (hs_contact_id, producer_id, broker_id, created, updated) VALUES (%s, %s, %s, %s, %s)",
                    (hs_object_id, producer_id, broker_id, now, now)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()


    def producer_id_map_update_record(batch, response):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    conn.cursor().execute(
                        f"UPDATE {S}.producer SET updated = %s WHERE hs_contact_id = %s",
                        (now, hs_object_id)
                    )
                    conn.commit()
            else:
                hs_object_id = response['properties']['hs_object_id']
                conn.cursor().execute(
                    f"UPDATE {S}.producer SET updated = %s WHERE hs_contact_id = %s",
                    (now, hs_object_id)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()


    def policy_id_map_create_record(batch, response, request_data=None):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                request_inputs = request_data.get('inputs', []) if request_data else []
                for idx, unit_json_response in enumerate(response['results']):
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    policy_no = unit_json_response['properties']['policy_name']
                    customer_id = unit_json_response['properties']['customer_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    # Get producer_id from original request data
                    producer_id = request_inputs[idx]['properties'].get('producer_id', '') if idx < len(request_inputs) else ''
                    conn.cursor().execute(
                        f"INSERT INTO {S}.policy (hs_object_id, policy_no, customer_id, broker_id, producer_id, created, updated) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                        (hs_object_id, policy_no, customer_id, broker_id, producer_id, now, now)
                    )
                    conn.commit()
            else:
                hs_object_id = response['properties']['hs_object_id']
                policy_no = response['properties']['policy_name']
                customer_id = response['properties']['customer_id']
                broker_id = response['properties']['broker_id']
                producer_id = response['properties'].get('producer_id', '')
                email = response['properties']['email']
                conn.cursor().execute(
                    f"INSERT INTO {S}.policy (hs_object_id, policy_no, customer_id, broker_id, producer_id, email, created, updated) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                    (hs_object_id, policy_no, customer_id, broker_id, producer_id, email, now, now)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()


    def policy_id_map_update_record(batch, response, request_data=None):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                request_inputs = request_data.get('inputs', []) if request_data else []
                # Create a mapping from hs_object_id to producer_id from request data
                producer_id_map = {
                    inp.get('id'): inp['properties'].get('producer_id', '')
                    for inp in request_inputs
                    if inp.get('id')
                }
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    # Look up producer_id by matching hs_object_id, not by index
                    producer_id = producer_id_map.get(hs_object_id, '')
                    conn.cursor().execute(
                        f"UPDATE {S}.policy SET updated = %s, producer_id = %s WHERE hs_object_id = %s",
                        (now, producer_id, hs_object_id)
                    )
                    conn.commit()
            else:
                hs_object_id = response['properties']['hs_object_id']
                conn.cursor().execute(
                    f"UPDATE {S}.policy SET updated = %s WHERE hs_object_id = %s",
                    (now, hs_object_id)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()


    def broker_id_map_create_record(batch, response):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_company_id = unit_json_response['properties']['hs_object_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    conn.cursor().execute(
                        f"INSERT INTO {S}.broker (hs_company_id, broker_id, created, updated) VALUES (%s, %s, %s, %s)",
                        (hs_company_id, broker_id, now, now)
                    )
                    conn.commit()
            else:
                hs_company_id = response['properties']['hs_object_id']
                broker_id = response['properties']['broker_id']
                conn.cursor().execute(
                    f"INSERT INTO {S}.broker (hs_company_id, broker_id, created, updated) VALUES (%s, %s, %s, %s)",
                    (hs_company_id, broker_id, now, now)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()


    def broker_id_map_update_record(batch, response):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_company_id = unit_json_response['properties']['hs_object_id']
                    conn.cursor().execute(
                        f"UPDATE {S}.broker SET updated = %s WHERE hs_company_id = %s",
                        (now, hs_company_id)
                    )
                    conn.commit()
            else:
                hs_company_id = response['properties']['hs_object_id']
                conn.cursor().execute(
                    f"UPDATE {S}.broker SET updated = %s WHERE hs_company_id = %s",
                    (now, hs_company_id)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()
        

    def quote_id_map_create_record(batch, response, request_data=None):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                request_inputs = request_data.get('inputs', []) if request_data else []
                for idx, unit_json_response in enumerate(response['results']):
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    broker_id = unit_json_response['properties']['broker_id']
                    customer_id = unit_json_response['properties']['customer_id']
                    # Get producer_id from original request data
                    producer_id = request_inputs[idx]['properties'].get('producer_id', '') if idx < len(request_inputs) else ''
                    quote_no = unit_json_response['properties']['policy_number']
                    conn.cursor().execute(
                        f"INSERT INTO {S}.quote (hs_object_id, broker_id, customer_id, producer_id, quote_no, created, updated) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                        (hs_object_id, broker_id, customer_id, producer_id, quote_no, now, now)
                    )
                    conn.commit()
            else:
                hs_object_id = response['properties']['hs_object_id']
                broker_id = response['properties']['broker_id']
                customer_id = response['properties']['customer_id']
                producer_id = response['properties'].get('producer_id', '')
                quote_no = response['properties']['policy_number']
                conn.cursor().execute(
                    f"INSERT INTO {S}.quote (hs_object_id, broker_id, customer_id, producer_id, quote_no, created, updated) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                    (hs_object_id, broker_id, customer_id, producer_id, quote_no, now, now)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()


    def quote_id_map_update_record(batch, response, request_data=None):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                request_inputs = request_data.get('inputs', []) if request_data else []
                # Create a mapping from hs_object_id to producer_id from request data
                producer_id_map = {
                    inp.get('id'): inp['properties'].get('producer_id', '')
                    for inp in request_inputs
                    if inp.get('id')
                }
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    # Look up producer_id by matching hs_object_id, not by index
                    producer_id = producer_id_map.get(hs_object_id, '')
                    conn.cursor().execute(
                        f"UPDATE {S}.quote SET updated = %s, producer_id = %s WHERE hs_object_id = %s",
                        (now, producer_id, hs_object_id)
                    )
                    conn.commit()
            else:
                hs_object_id = response['properties']['hs_object_id']
                conn.cursor().execute(
                    f"UPDATE {S}.quote SET updated = %s WHERE hs_object_id = %s",
                    (now, hs_object_id)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()
       
        
    def quote_note_id_map_create_record(batch, response):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['id']#['properties']['hs_object_id']
                    quote_no = unit_json_response['properties']['quote_no']
                    conn.cursor().execute(
                        f"INSERT INTO {S}.quote_note (hs_note_id, quote_no, created, updated) VALUES (%s, %s, %s, %s)",
                        (hs_object_id, quote_no, now, now)
                    )
                    conn.commit()
            else:
                hs_object_id = response['id']#['properties']['hs_object_id']
                quote_no = response['properties']['quote_no']
                conn.cursor().execute(
                    f"INSERT INTO {S}.quote_note (hs_note_id, quote_no, created, updated) VALUES (%s, %s, %s, %s)",
                    (hs_object_id, quote_no, now, now)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()


    def quote_note_id_map_update_record(batch, response):
        now = str(datetime.now())
        conn = get_id_map_connection()
        try:
            if batch:
                for unit_json_response in response['results']:
                    hs_object_id = unit_json_response['properties']['hs_object_id']
                    conn.cursor().execute(
                        f"UPDATE {S}.quote_note SET updated = %s WHERE hs_note_id = %s",
                        (now, hs_object_id)
                    )
                    conn.commit()
            else:
                hs_object_id = response['properties']['hs_object_id']
                conn.cursor().execute(
                    f"UPDATE {S}.quote_note SET updated = %s WHERE hs_note_id = %s",
                    (now, hs_object_id)
                )
                conn.commit()
        except Exception as e:
            logger.error(f"Error creating ID Map entry: {e}")
        finally:
            conn.close()
        
