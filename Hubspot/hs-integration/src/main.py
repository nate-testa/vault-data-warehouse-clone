import shared.timetracking as timetracking

from objects.customer import Customer
from objects.producer import Producer
from objects.policy import Policy
from objects.broker import Broker
from objects.quote import Quote
from objects.parent_child_note import ParentChildNotes
from objects.quote_note import QuoteNote

def run():

    Producer.sync_to_hubspot()         # contacts
    Customer.sync_to_hubspot()         # contacts
    Policy.sync_to_hubspot()           # policies
    Broker.sync_to_hubspot()           # companies
    Quote.sync_to_hubspot()            # deals
    QuoteNote.sync_to_hubspot()        # notes
    ParentChildNotes.sync_to_hubspot() # notes


    Producer.associate_records()
    Customer.associate_records()
    Broker.associate_records()


    now = timetracking.get_current_timestamp()
    timetracking.stamp_most_recent_runtime(now)


if __name__ == '__main__' :
    run()
