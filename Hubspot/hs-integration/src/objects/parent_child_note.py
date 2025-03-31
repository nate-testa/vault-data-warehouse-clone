from shared.database import DatabaseFunctions
from shared.id_map import id_map_path
from shared.association import Association
from objects.broker import Broker as Broker
from shared.logger import get_logger
import shared.hubspot as hubspot


logger = get_logger(__name__)



class ParentChildNotes:

    def sync_to_hubspot():
        broker_relation_df = DatabaseFunctions.get_data_from_db(DatabaseFunctions.table_name['broker_relation'])
        
        if not broker_relation_df.empty:
            batch_payload = {"inputs": []}

            for index, row in broker_relation_df.iterrows():
                try:
                    from_id = Broker.return_broker_hs_id_for_update(row['parent_broker_id'])
                    related_notes = hubspot.RecordsDispatcher.get_related_notes(from_id)

                    if related_notes:
                        to_id = Broker.return_broker_hs_id_for_update(row['child_broker_id'])
                        association_type_id = Association.association_type_id['broker-parent-child']
                        record_payload = Association.build_association_payload(from_id, to_id, association_type_id, association_category='HUBSPOT_DEFINED')
                        batch_payload['inputs'].append(record_payload)
        
                except Exception as e:
                    logger.error(f'error while syncing parent child notes: {e}')

            parent_child_notes_associations = hubspot.AssociationHandler('parent-child-notes-association', 'parent-child-notes-associations')
            parent_child_notes_associations.dispatch(batch_payload)

            

    # def process_row(row):
    #         parent_id = row['parent_broker_id'] or ''
    #         child_id = row['child_broker_id'] or ''
    #         association_type_id = association_type_id['']

    #         if parent_id is not None and child_id is not None: # prevents API errors that would occur if we try to pass a blank ID. blank IDs will need to be addressed
    #             record_payload = Association.build_association_payload(parent_id, child_id, association_type_id, association_category='HUBSPOT_DEFINED')
    #             return record_payload
                      
    #         else:
    #             return ''




        


          

