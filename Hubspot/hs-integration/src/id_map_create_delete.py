from shared.id_map import id_map_path

import sqlite3



id_map_tables = {
    'broker': 'CREATE TABLE broker ( hs_company_id text NOT NULL, broker_id text NOT NULL, created text NOT NULL, updated text NOT NULL )',
# broker relation table is not needed
#    'broker_relation': 'CREATE TABLE broker_relation ( parent_hs_company_id text NOT NULL, child_hs_company_id text NOT NULL, parent_broker_id text NOT NULL, child_broker_id text NOT NULL, created text NOT NULL, updated text NOT NULL )',
    'customer': 'CREATE TABLE customer ( hs_contact_id text NOT NULL, customer_id text NOT NULL, broker_id text NOT NULL, email text, created text NOT NULL, updated text NOT NULL )',
    'policy': 'CREATE TABLE policy ( hs_object_id text NOT NULL, policy_no text NOT NULL, customer_id text NOT NULL, broker_id text NOT NULL, email text, created text NOT NULL, updated text NOT NULL )',
    'producer': 'CREATE TABLE producer ( hs_contact_id text NOT NULL, producer_id text NOT NULL, broker_id text NOT NULL, email text, created text NOT NULL, updated text NOT NULL )',
    'quote': 'CREATE TABLE quote ( hs_object_id text NOT NULL, quote_no text NOT NULL, customer_id text NOT NULL, broker_id text NOT NULL, created text NOT NULL, updated text NOT NULL )',
    'quote_note': 'CREATE TABLE quote_note ( hs_note_id text NOT NULL, quote_no text NOT NULL, created text NOT NULL, updated text NOT NULL )'
}



def delete_id_map_records():
    conn = sqlite3.connect(id_map_path)
    cursor = conn.cursor()
    query = f'''
    DELETE FROM customer;
    '''
    cursor.execute(query, conn)
    conn.commit()
    conn.close()
    print('completed')


# conn = sqlite3.connect(id_map_path)