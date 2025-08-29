# CLI APPLICATION
CLI_USAGE_ERROR = "Usage: python run_matlab_script.py <matlab_script_path> <computation_method> <start_marker> <end_marker> [<arg1> ... <argN>]"
MATLAB_BACKEND_START = "Starting MATLAB script execution"
PARALLEL_PROCESSING_PROMPT = "Enter the number of parallel threads: "
PARALLEL_PROCESSING_INIT = "Using {num_threads} parallel threads"
MULTI_PROCESSING_ERROR = "Error processing marker {marker_no}: {e}"
INVALID_COMPUTATION_METHOD_ERROR = "Invalid computation method: {computation_method}"
CRTIICAL_SCRIPT_ERROR = "An unexpected error occurred while executing the MATLAB script."
STATS_SAVED_INFO = "Computation results saved to {filename}"


# UTILS
CONSTRUCTED_MATLAB_COMMAND = "Constructed MATLAB command: {matlab_command}"
MATLAB_OUTPUT = "MATLAB Output:\n"
MATLAB_ERROR = "MATLAB Warnings or Errors:\n"
MATLAB_EXECUTION_FAILED = "MATLAB script execution failed."
MATLAB_SUBPROCESS_ERROR_CODE = "Return Code: "
MATLAB_SUBPROCESS_ERROR_OUTPUT = "Error Output:\n"
CRITICAL_MATLAB_ERROR = "An unexpected error occurred while executing the MATLAB script."
COPIED_TEMP_OUTPUT_FILES = "Successfully Copied Temp Output Folder: {folder_path}"


# PYQT Application
class Messages:
    SELECT_DIR_PROMPT = "Please select a directory."
    SELECT_DIR_SUCCESS = "Selected Directory: {}"
    NO_DIR_SELECTED = "No directory selected."
    ERROR = "An error occurred. Check the logs."
    LOG_DIR_SELECTED = "{} selected: {}"
    LOG_NO_DIR_SELECTED = "No directory selected."
    LOG_ERROR = "Error selecting directory: {}"

class Messages:
    SELECT_DIR_PROMPT = "Select a directory"
    LOG_DIR_SELECTED = "Directory selected: {}"
    LOG_NO_DIR_SELECTED = "No directory selected"
    LOG_ERROR = "Error occurred: {}"
    NO_DIR_SELECTED = "No subdirectories found"
    ERROR = "Error"
