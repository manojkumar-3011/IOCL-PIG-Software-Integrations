import subprocess
import sys
import logging
import os
import time
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import pandas as pd
import messages, constants, schema, utils
from logger import logger

if __name__ == "__main__":
    if len(sys.argv) < constants.MINIMUM_REQUIRED_ARGS:
        logger.error(messages.CLI_USAGE_ERROR)
        sys.exit(1)
    else:
        logger.debug(messages.MATLAB_BACKEND_START)

        # required inputs
        matlab_script_path = sys.argv[1]
        computation_method = sys.argv[2]
        start_marker = int(sys.argv[3])
        end_marker = int(sys.argv[4])
        script_args = sys.argv[5:]

        current_path = os.path.dirname(os.path.abspath(__file__))
        computation_sheet = pd.DataFrame(columns=['start_marker', 'end_marker', 'compute_method', 'time', 'args'])

        utils.init_matlab_with_options(matlab_script_path, computation_method, start_marker, end_marker, script_args)