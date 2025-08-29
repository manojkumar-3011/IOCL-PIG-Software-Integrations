import os

# CLI
MINIMUM_REQUIRED_ARGS = 5
COMPUTATION_SHEET_PATH = os.path.join('stats', 'computation_sheet_{timestamp}.csv')

# UI APPLICATION
APP_MIN_THREADS = 1
APP_MAX_THREADS = 10
APP_MIN_CHECKPOINT_STEPS = 1
APP_DEFAULT_CHECKPOINT_STEPS = 2
APP_MAX_CHECKPOINT_STEPS = 10000000
APP_DEFAULT_END_MARKER = 2
APP_MAX_END_MARKER = 10000000
APP_RESULT_SHEET_COLS = ["Status", "Start Marker", "End Marker", "Method", "Result Folder", "Time"]
APP_RESULT_SHEET_PATH = os.path.join('logs', 'temp_result_sheet.csv')
APP_RESULT_POLLING_TIME = 5000

# DESIGN
INPUT_FIELD_STYLE_SHEET = """
    QComboBox, QSpinBox, QLineEdit, QLabel {
        border: 2px solid #DDDDDD; /* Gray border */
        border-radius: 14px; /* Rounded corners */
        padding: 2px; /* Internal padding */
    }
"""

# UTILS
MATLAB_RELATIVE_PATH = os.path.join('MATLAB')
MATLAB_SCRIPT_PATH = os.path.join('Estimator', 'master_exec.m')
CSV2MAT_SCRIPT_PATH = os.path.join('Estimator', 'convert_csv2mat.m')
ALL_ODO_GEN_SCRIPT_PATH = os.path.join('Estimator', 'auto_gen_all_estimates.m')
MATLAB_PATCH_FILE_NAME = 'patch.m'
MATLAB_PATCH_PATH = os.path.join('PATCH')
MATLAB_PATCH_FILE_PATH = os.path.join(MATLAB_PATCH_PATH, MATLAB_PATCH_FILE_NAME)
MATLAB_INPUT_FOLDERS = ["INPUT", "OPTIONAL_INPUT"]
MATLAB_TEMP_OUTPUT_FOLDERS = [os.path.join(MATLAB_RELATIVE_PATH, 'OUTPUT'), os.path.join(MATLAB_RELATIVE_PATH, 'CSV_OUTPUT')]
COMPUTATION_SHEET_COLS = ['start_marker', 'end_marker', 'compute_method', 'time', 'args']
MAT_DB_RELATIVE_PATH = os.path.join('MAT INPUT DB')
MATLAB_RESULT_FILE_NAME = os.path.join('all_estimates')
MATLAB_CSV_FILE_NAME = 'all_estimates.csv'
APP_RESULT_FOLDER_PATH = os.path.join('logs', 'result_folders.csv')



# LOGGER
LOG_FILE_PATH = os.path.join("logs", "application.log")