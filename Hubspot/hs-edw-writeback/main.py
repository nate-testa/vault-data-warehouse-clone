from src.company_goal import CompanyGoal
from src.quote_note import QuoteNote
from src.staging import Staging
import src.timetracking as timetracking

import time



def run():

    query_start_time = timetracking.load_previous_timestamp()
    query_end_time = timetracking.get_current_timestamp()

    QuoteNote.sync_to_edw(query_start_time)

    Staging.sync_to_staging_table(query_start_time)
    time.sleep(1)
    CompanyGoal.load_to_edw(query_start_time)

    timetracking.stamp_most_recent_runtime(query_end_time)


if __name__ == '__main__':
    run()