import subprocess
from queue import Queue
from threading import Thread, Event
import os, shutil, sys
import time
import re, math
import csv
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import pandas as pd
import messages, schema, constants
from logger import logger

result_folders = []

def resource_path(relative_path):
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.dirname(os.path.abspath(__file__))

    return os.path.join(base_path, relative_path)

# Thread-safe logging queue
log_queue = Queue()

# shutdown flag
shutdown_flag = Event()

# time compuration decorator
def timeit(func):
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        logger.info(f"Execution time of {func.__name__}: {end_time - start_time:.4f} seconds")
        return result, end_time - start_time
    return wrapper

def validate(func):
    """
    A decorator to handle validation and return None if a validation function fails.
    """
    def wrapper(*args, **kwargs):
        result = func(*args, **kwargs)
        if not result:  # Return None if validation fails
            return None
        return result
    return wrapper

def extract_numbers_from_text(input_string, opt=None):
    # Regular expression to find all integers and floats
    numbers = re.findall(r'-?\d*\.\d+|-?\d+', input_string)
    
    if opt==int:
        # Convert the found numbers to the appropriate type (int or float)
        return [math.floor(float(num)) for num in numbers]
    elif opt==float:
        # Convert the found numbers to the appropriate type (int or float)
        return [float(num) for num in numbers]
    else:
        # Convert the found numbers to the appropriate type (int or float)
        return [float(num) if '.' in num else int(num) for num in numbers]

def copy_temp_output_files(source_path):
    # Get the temporary folder where PyInstaller has extracted resources
    temp_output_path = resource_path(source_path)

    # Get the directory where the executable is running from (dist folder)
    exe_dir = os.path.dirname(sys.argv[0])

    # Define the target directory where you want to copy the files
    target_dir = os.path.join(exe_dir, source_path)

    # Check if the source directory (MATLAB/OUTPUT) exists
    if os.path.exists(temp_output_path):
        # Walk through all subdirectories and files in the OUTPUT folder
        for root, dirs, files in os.walk(temp_output_path):
            # Determine the relative path of the current folder
            relative_path = os.path.relpath(root, temp_output_path)
            target_folder = os.path.join(target_dir, relative_path)

            # Create the target subfolder if it doesn't exist
            if not os.path.exists(target_folder):
                os.makedirs(target_folder)

            # Copy each file to the corresponding target subfolder
            for file_name in files:
                source_file = os.path.join(root, file_name)
                target_file = os.path.join(target_folder, file_name)
                
                # Copy the file
                shutil.copy2(source_file, target_file)  # copy2 preserves metadata (timestamps, etc.)

        logger.info(f"Files copied from {temp_output_path} to {target_dir}")
    else:
        logger.info(f"Output directory {temp_output_path} does not exist!")


@timeit
def run_matlab_script(matlab_script_path, *args, nodisplay=True):
    """
    Runs a MATLAB script with any number of arguments.
    
    Parameters:
    - matlab_script_path (str): Path to the MATLAB script file (without the .m extension).
    - *args (str): Arguments to pass to the MATLAB script.
    """
    if not shutdown_flag.is_set():
        # Extract directory and script name, ensuring OS compatibility
        script_dir = os.path.dirname(matlab_script_path) or '.'
        print(matlab_script_path)
        script_name = os.path.splitext(os.path.basename(matlab_script_path))[0]  # Remove .m if present
        print(script_name)

        # Convert Python arguments to MATLAB format
        matlab_args = ", ".join([arg for arg in args])
        print(matlab_args)
        # Construct MATLAB command to add path and call the script as a function
        matlab_command = f"addpath('{script_dir}'); {script_name}({matlab_args}); exit;"
        logger.debug(messages.CONSTRUCTED_MATLAB_COMMAND.format(matlab_command=matlab_command))
        # return
        # Select the command option based on the OS
        if len(args) >= 3 and args[3] != '0':
            matlab_options = ["-batch", matlab_command] if os.name != "nt" else ["-wait", "-nosplash", "-nodesktop", "-r", matlab_command]
        elif not nodisplay:
            matlab_options = ["-batch", matlab_command] if os.name != "nt" else ["-wait", "-nosplash", "-nodesktop", "-r", matlab_command]
        else:
            matlab_options = [
                "-batch", 
                matlab_command, 
                "-nodisplay", 
                "-nosplash", 
                "-nodesktop", 
            ] if os.name != "nt" else [
                "-wait", 
                "-nosplash", 
                "-nodesktop", 
                "-noFigureWindows",  # Prevent figure windows from opening
                "-r", 
                matlab_command
            ]
        logger.info(f'MATLAB OPTIONS: {matlab_options}')
        try:
            # Run MATLAB from the command line with the constructed command
            if os.name == "nt":
                result = subprocess.run(["matlab"] + matlab_options, capture_output=True, text=True, check=True, creationflags=subprocess.CREATE_NO_WINDOW)
            else:
                result = subprocess.run(["matlab"] + matlab_options, capture_output=True, text=True, check=True)
            # Log MATLAB output
            if result.stdout:
                logger.info(messages.MATLAB_OUTPUT + result.stdout)
            if result.stderr:
                logger.warning(messages.MATLAB_ERROR + result.stderr)

        except subprocess.CalledProcessError as e:
            # Log error if MATLAB command fails
            logger.error(messages.MATLAB_EXECUTION_FAILED)
            logger.error(messages.MATLAB_SUBPROCESS_ERROR_CODE + e.returncode)
            logger.error(messages.MATLAB_SUBPROCESS_ERROR_OUTPUT + e.stderr)
            
        except Exception as e:
            # Catch-all for any other exceptions
            logger.critical(messages.CRITICAL_MATLAB_ERROR, exc_info=True)
    
    else:
        logger.info("Task stopped. Exiting MATLAB script processing.")
    
    return args[-1]

def copy_input_folders(source_dir, destination_dir, replace_existing=False, folders_to_copy = constants.MATLAB_INPUT_FOLDERS):
    """
    Copies 'INPUT' and 'OPTIONAL_INPUT' folders from source to destination.

    Args:
        source_dir (str): Path to the source directory.
        destination_dir (str): Path to the destination directory.
        replace_existing (bool): If True, existing 'INPUT' and 'OPTIONAL_INPUT'
            folders in the destination will be deleted before copying.

    Returns:
        bool: True if at least one folder was copied, False otherwise.
    """

    copied_any = False

    if not os.path.isdir(source_dir):
        logger.error(f"Source directory '{source_dir}' does not exist.")
        return False

    try:
        os.makedirs(destination_dir, exist_ok=True)
    except OSError as e:
        logger.error(f"Error creating destination directory '{destination_dir}': {e}")
        return False

    for folder_name in folders_to_copy:
        source_folder_path = os.path.join(source_dir, folder_name)
        destination_folder_path = os.path.join(destination_dir, folder_name)

        if os.path.exists(source_folder_path):
            logger.info(f"Found '{folder_name}' folder in source.")

            # removing existing inputs
            if replace_existing:
                dest_folder_path = os.path.join(destination_dir, folder_name)
                if os.path.exists(dest_folder_path):
                    try:
                        shutil.rmtree(dest_folder_path)  # Remove existing folder
                        logger.info(f"Removed existing '{folder_name}' in destination.")
                    except OSError as e:
                        logger.error(f"Error removing existing '{folder_name}' in destination: {e}")
                        return False  # Stop if removal fails
            # copy new files        
            try:
                shutil.copytree(source_folder_path, destination_folder_path, dirs_exist_ok=True)
                copied_any = True
                logger.info(f"Successfully copied '{folder_name}' to destination.")
            except shutil.Error as e:
                logger.error(f"Error copying '{folder_name}': {e}")
            except OSError as e:
                logger.error(f"Error during file operations '{folder_name}': {e}")

        else:
            logger.info(f"'{folder_name}' folder not found in source.")

    return copied_any

def init_matlab_with_options(matlab_script_path, computation_method, start_marker, end_marker, script_args):
    '''
    changes the input format for the respective computation methods

    SEQUENTIAL = converts to start:end format one at a time
    MULTI = starts parallel start:end threads with the given batch size
    JOINT = converts to [start, end] format to give multiple markers at a time (WIP)
    '''
    
    computation_sheet = pd.DataFrame(columns=constants.COMPUTATION_SHEET_COLS)

    try:
        
        if computation_method == schema.ComputationMethod.SEQUENTIAL.short_name():
            # Sequential computation
            for marker_no in range(start_marker, end_marker):
                marker_str = f'{marker_no}:{marker_no+1}'
                _, elapsed_time = run_matlab_script(matlab_script_path, marker_str, *script_args)
                computation_sheet.loc[len(computation_sheet)] = [marker_no, marker_no + 1, computation_method, elapsed_time, script_args]
        
        elif computation_method == schema.ComputationMethod.MULTI.short_name():
            # Parallel computation
            num_threads = int(input(messages.PARALLEL_PROCESSING_PROMPT))
            logger.info(messages.PARALLEL_PROCESSING_INIT.format(num_threads=num_threads))
            with ThreadPoolExecutor(max_workers=num_threads) as executor:
                future_to_marker = {
                    executor.submit(run_matlab_script, matlab_script_path, f'{marker_no}:{marker_no+1}', *script_args): marker_no
                    for marker_no in range(start_marker, end_marker)
                }
                for future in as_completed(future_to_marker):
                    marker_no = future_to_marker[future]
                    try:
                        _, elapsed_time = future.result()
                        computation_sheet.loc[len(computation_sheet)] = [marker_no, marker_no + 1, computation_method, elapsed_time, script_args]
                    except Exception as e:
                        logger.error(messages.MULTI_PROCESSING_ERROR.format(marker_no=marker_no, e=e), exc_info=True)
        
        else:
            logger.error(messages.INVALID_COMPUTATION_METHOD_ERROR.format(computation_method=computation_method))
    
    except Exception as e:
        logger.critical(messages.CRTIICAL_SCRIPT_ERROR, exc_info=True)
    finally:
        # Save the computation sheet to a CSV file
        timestamp = datetime.now().strftime('%Y%m%d_%H%M')
        filename = resource_path(constants.COMPUTATION_SHEET_PATH.format(timestamp=timestamp))
        computation_sheet.to_csv(filename, index=False)
        logger.info(messages.STATS_SAVED_INFO.format(filename=filename))

def init_matlab_from_app(input_directory, computation_method, start_marker, end_marker, accuracy_mode, odo_gain, manual_gains=[], num_threads=1, checkpoints=[], plot_frequency=None, admin_input={}):
    '''
    initializes the matlab application from UI

    SEQUENTIAL = converts to start:end format one at a time
    MULTI = starts parallel start:end threads with the given batch size
    JOINT = converts to [start, end] format to give multiple markers at a time (WIP)
    '''
    
    computation_sheet = pd.DataFrame(columns=constants.COMPUTATION_SHEET_COLS)

    try:
        results_sheet = pd.DataFrame(columns=constants.APP_RESULT_SHEET_COLS)
        results_sheet.to_csv(constants.APP_RESULT_SHEET_PATH, index=False)
    except Exception as e:
        logger.critical(messages.CRTIICAL_SCRIPT_ERROR, exc_info=True)
      
    try:
        matlab_script_path = resource_path(os.path.join(constants.MATLAB_RELATIVE_PATH, constants.MATLAB_SCRIPT_PATH))
        matlab_input_destination_path = resource_path(constants.MATLAB_RELATIVE_PATH)
        
        if os.path.isdir(input_directory):
            logger.info(f"Processing directory: {input_directory}")
            copy_input_folders(input_directory, matlab_input_destination_path, replace_existing=True)
        
        else:
            logger.info(f"Invalid input: {input_directory} is not a directory.")
            raise Exception(f"Invalid input: {input_directory} is not a directory.")
        
        odo_gain = schema.GainSetting.from_string(odo_gain).short_name()
        accuracy_mode = schema.AccuracyMethod.from_string(accuracy_mode).short_name()
        admin_input = 1
        if admin_input:
            adm_str = 'adm'
        else:
            adm_str = ''
        if not manual_gains:
            gain_strs = [odo_gain] * len(checkpoints)
        else:
            gain_strs = [str(odo_gain)+', '+ str(gain) for gain in manual_gains]
        if not plot_frequency:
            plot_frequency = '0' # set 0 to make infinite in MATLAB code
        
        if computation_method != schema.ComputationMethod.JOINT.long_name():
            # Parallel computation
            if computation_method == schema.ComputationMethod.MULTI.long_name():
                logger.info(messages.PARALLEL_PROCESSING_INIT.format(num_threads=num_threads))
            marker_format = '{start_marker}:{end_marker}'
            execute_parallel_threads(matlab_script_path, computation_method, num_threads, accuracy_mode, plot_frequency, checkpoints, gain_strs, marker_format, computation_sheet, admin_input)
        
        elif computation_method == schema.ComputationMethod.JOINT.long_name() and checkpoints:
            marker_format = '[{start_marker}, {end_marker}]' 
            execute_parallel_threads(matlab_script_path, computation_method, num_threads, accuracy_mode, plot_frequency, checkpoints, gain_strs, marker_format, computation_sheet, admin_input)
        else:
            logger.error(messages.INVALID_COMPUTATION_METHOD_ERROR.format(computation_method=computation_method))
    
    except Exception as e:
        logger.critical(messages.CRTIICAL_SCRIPT_ERROR, exc_info=True)
    finally:
        all_odo_gen_script_path = resource_path(os.path.join(constants.MATLAB_RELATIVE_PATH, constants.ALL_ODO_GEN_SCRIPT_PATH))
        _, elapsed_time = run_matlab_script(all_odo_gen_script_path, "", nodisplay=True)
        for path in constants.MATLAB_TEMP_OUTPUT_FOLDERS:
            copy_temp_output_files(path)
            logger.info(messages.COPIED_TEMP_OUTPUT_FILES.format(folder_path=path))



def execute_parallel_threads(matlab_script_path, computation_method, num_threads, accuracy_mode, plot_frequency, checkpoints, gain_strs, marker_format, computation_sheet, admin_input):
    global ResultFilePath, ResultfilePaths
    with ThreadPoolExecutor(max_workers=num_threads) as executor:
                # Start the logging worker thread
                logging_thread = Thread(target=log_worker, daemon=True)
                logging_thread.start()

                # Log IN-PROGRESS status
                for cp_idx in range(len(checkpoints)-1):   
                    log_queue.put([
                        schema.AppStatus.IN_PROGRESS.status_name(), checkpoints[cp_idx], checkpoints[cp_idx+1], computation_method, "-", "-"
                    ])

                time_stamp = datetime.now().strftime('%Y%m%d-%H%M')
                future_to_marker = {
                    executor.submit(
                        run_matlab_script,
                        matlab_script_path,
                        f'{marker_format.format(start_marker=checkpoints[cp_idx], end_marker=checkpoints[cp_idx+1])}',
                        f'{gain}',
                        f'{accuracy_mode}',
                        f'{plot_frequency}',
                        f"'{time_stamp}'"
                    ): cp_idx
                    for cp_idx, gain in zip(range(len(checkpoints)-1), gain_strs)
                }
                result_folders = []
                for future in as_completed(future_to_marker):
                    cp_idx = future_to_marker[future]
                    try:
                        _, elapsed_time = future.result()
                        checkpoints_str = f"[{checkpoints[cp_idx]} {checkpoints[cp_idx+1]}]"
                        result_folder = os.path.join(
                        os.path.abspath('.'),constants.MATLAB_TEMP_OUTPUT_FOLDERS[1],
                        f"results_{time_stamp[2:]}_{checkpoints_str}")
                        result_folder = os.path.join(result_folder, f"all_estimates.csv")
                        result_folders.append(result_folder)

                        folder_df = pd.DataFrame(result_folders, columns=['Result Folder'])
                        folder_df.to_csv(constants.APP_RESULT_FOLDER_PATH, index=False)

                        print("result path created")
                        status = schema.AppStatus.COMPLETED.status_name()
                        computation_sheet.loc[len(computation_sheet)] = [
                            checkpoints[cp_idx], checkpoints[cp_idx+1], computation_method, elapsed_time, admin_input
                        ]
                    except Exception as e:
                        print("except")
                        status = schema.AppStatus.FAILED.status_name()
                        result_folder = "-"
                        elapsed_time = "-"
                        ResultfilePaths = "-"
                
                    # Log final status
                    file = pd.read_csv(constants.APP_RESULT_SHEET_PATH)
                    filtered_file = file[~((file['Start Marker'] == checkpoints[cp_idx]) & (file['End Marker'] == checkpoints[cp_idx+1]))]
                    # Optionally, save the filtered DataFrame back to the file
                    filtered_file.to_csv(constants.APP_RESULT_SHEET_PATH, index=False)
                    log_queue.put([
                        status, checkpoints[cp_idx], checkpoints[cp_idx+1], computation_method, result_folder, round(elapsed_time, 2)
                    ])

# Function to handle CSV logging in a separate thread
def log_worker(log_file_path=constants.APP_RESULT_SHEET_PATH):
    """Worker thread to write log entries from the queue to the CSV file."""
    while True:
        log_entry = log_queue.get()
        if log_entry is None:  # Sentinel to stop the worker
            break
        with open(log_file_path, mode="a", newline="") as file:
            writer = csv.writer(file)
            writer.writerow(log_entry)
        log_queue.task_done()