from shared.id_map_db import get_id_map_connection, ID_MAP_SCHEMA


S = ID_MAP_SCHEMA

id_map_tables = {
    'broker': f'CREATE TABLE {S}.broker ( hs_company_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'customer': f'CREATE TABLE {S}.customer ( hs_contact_id NVARCHAR(50) NOT NULL, customer_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, email NVARCHAR(255), created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'policy': f'CREATE TABLE {S}.policy ( hs_object_id NVARCHAR(50) NOT NULL, policy_no NVARCHAR(100) NOT NULL, customer_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, producer_id NVARCHAR(50), email NVARCHAR(255), created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'producer': f'CREATE TABLE {S}.producer ( hs_contact_id NVARCHAR(50) NOT NULL, producer_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, email NVARCHAR(255), created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'quote': f'CREATE TABLE {S}.quote ( hs_object_id NVARCHAR(50) NOT NULL, quote_no NVARCHAR(100) NOT NULL, customer_id NVARCHAR(50) NOT NULL, broker_id NVARCHAR(50) NOT NULL, producer_id NVARCHAR(50), created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )',
    'quote_note': f'CREATE TABLE {S}.quote_note ( hs_note_id NVARCHAR(50) NOT NULL, quote_no NVARCHAR(100) NOT NULL, created NVARCHAR(50) NOT NULL, updated NVARCHAR(50) NOT NULL )'
}



def delete_id_map_records():
    conn = get_id_map_connection()
    cursor = conn.cursor()
    cursor.execute(f'DELETE FROM {S}.customer')
    conn.commit()
    conn.close()
    print('completed')