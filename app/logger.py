import logging
import constants
from datetime import datetime

class CustomFormatter(logging.Formatter):
    def formatTime(self, record, datefmt=None):
        # Custom format for time with only 3 digits for milliseconds
        ct = datetime.fromtimestamp(record.created)
        if datefmt:
            # Format time without using %f
            s = ct.strftime(datefmt)
            return s + f".{int(record.msecs):03d}"  # Append milliseconds manually
        else:
            return super().formatTime(record, datefmt)

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# Create handlers
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)

file_handler = logging.FileHandler(constants.LOG_FILE_PATH)
file_handler.setLevel(logging.INFO)

# Use the custom formatter
formatter = CustomFormatter(
    '%(levelname)s - %(asctime)s - %(pathname)s:%(lineno)d: %(message)s',
    datefmt='%H:%M:%S'  # Removed %f; milliseconds will be handled manually
)

console_handler.setFormatter(formatter)
file_handler.setFormatter(formatter)

# Add handlers to logger
logger.addHandler(console_handler)
logger.addHandler(file_handler)
