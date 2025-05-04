import constants
import pytz

from datetime import datetime, timedelta

timetracking_file_path = constants.path_to_timetracking_file

def get_current_timestamp():
    now = datetime.now()
    formatted = now.strftime("%Y-%m-%d %H:%M:%S")
    return formatted 

def load_previous_timestamp():
    previous_runtime = open(timetracking_file_path, 'r').read()
    return previous_runtime

def stamp_most_recent_runtime(timestamp):
    file = open(timetracking_file_path, 'w')
    file.write(timestamp)
    file.close()

def format_unix_timestamp(datetime_str):
    dt = datetime.strptime(datetime_str, "%Y-%m-%d %H:%M:%S")
    # dt = dt + timedelta(hours=4)
    # utc = pytz.utc.localize(dt)
    timestamp = (int(dt.timestamp()) * 1000)
    return timestamp

def format_timestamp_for_staging_query(previous_runtime_datetime_string):
    dt = datetime.strptime(previous_runtime_datetime_string, '%Y-%m-%d %H:%M:%S')
    formatted_utc_time = dt.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
    return formatted_utc_time

def format_unix_timestamp_for_hs_company_goals_query(datetime_string):
    dt = datetime.strptime(datetime_string, "%Y-%m-%d %H:%M:%S")
    timestamp = (int(dt.timestamp()) * 1000)
    return timestamp