from datetime import datetime
import constants


timetimetracking_file_path = constants.time_tracking_file_path


def get_current_timestamp():
    now = datetime.now()
    formatted = now.strftime("%Y-%m-%d %H:%M:%S")
    return formatted 


def load_previous_timestamp():
    previous_runtime = open(timetimetracking_file_path, 'r').read()
    dt = datetime.strptime(previous_runtime, "%Y-%m-%d %H:%M:%S").date()
    return dt


def stamp_most_recent_runtime(timestamp):
    file = open(timetimetracking_file_path, 'w')
    file.write(timestamp)
    file.close()