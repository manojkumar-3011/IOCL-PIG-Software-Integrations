# app.py

import sys
from PyQt5.QtWidgets import (
    QApplication,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QComboBox,
    QSpinBox,
    QCheckBox,
    QFileDialog,
    QTableWidget,
    QTableWidgetItem,
    QHeaderView,
    QScrollArea,
    QFrame,
    QSizePolicy
)
from PyQt5.QtGui import QFont, QIcon, QPixmap
from PyQt5.QtCore import Qt, QTimer

import logging
import os
import threading
import time

# Import logger from the same directory level
from logger import logger
from enum import Enum

# Constants, Enums, and Static Variables
# (Prefix all with 'MyApp' for easy search/replace)
MyApp_APP_NAME = "My PyQt Application"
MyApp_LOGO_PATH = "path/to/your/logo.png"  # Replace with actual path
MyApp_COBRAND_PATH = "path/to/your/cobrand.png"  # Replace with actual path
MyApp_FONT_FAMILY = "Arial"
MyApp_FONT_SIZE = 10
MyApp_INPUT_DIR_LABEL = "Input Directory:"
MyApp_START_MARKER_LABEL = "Start Marker Index:"
MyApp_END_MARKER_LABEL = "End Marker Index:"
MyApp_COMPUTATION_METHODS = ["Sequential", "Multi", "Joint"]
MyApp_THREAD_COUNT_MIN = 1
MyApp_THREAD_COUNT_MAX = 5
MyApp_ODO_GAIN_OPTIONS = ["16km", "100km", "Manual"]
MyApp_MANUAL_ODO_GAIN_PLACEHOLDER = "Enter comma-separated values"
MyApp_ACCURACY_METHODS = ["Quick", "Accuracy", "Quick+Accuracy"]
MyApp_ENABLE_PLOTS_LABEL = "Enable Plots:"
MyApp_PLOT_FREQUENCY_LABEL = "Plot Frequency:"
MyApp_ADMIN_SETTINGS_LABEL = "Admin Settings"
MyApp_JSON_INPUT_LABEL = "JSON Input:"
MyApp_RESULTS_TABLE_HEADERS = ["Status", "Start Marker", "End Marker", "Method", "Result Folder"]
MyApp_STATUS_COMPLETED = "Completed"
MyApp_STATUS_FAILED = "Failed"
MyApp_STATUS_IN_PROGRESS = "In Progress"
MyApp_RESULT_FILE_PATH = "temp/results.csv"
MyApp_POLL_INTERVAL = 5000  # 5 seconds

class MyApp_ComputationMethod(Enum):
    Sequential = 1
    Multi = 2
    Joint = 3

class MyApp_AccuracyMethod(Enum):
    Quick = 1
    Accuracy = 2
    QuickAccuracy = 3

class MyApp_StatusColor(Enum):
    Completed = "green"
    Failed = "red"
    InProgress = "yellow"

class MyApp(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle(MyApp_APP_NAME)
        self.setWindowIcon(QIcon("path/to/your/icon.ico"))  # Replace with actual path
        self.initUI()

    def initUI(self):
        # Create main layout
        main_layout = QVBoxLayout()

        # Top section with logos
        top_layout = QHBoxLayout()
        logo_label = QLabel()
        logo_pixmap = QPixmap(MyApp_LOGO_PATH)
        logo_label.setPixmap(logo_pixmap)
        top_layout.addWidget(logo_label)
        app_title_label = QLabel(MyApp_APP_NAME)
        app_title_label.setFont(QFont(MyApp_FONT_FAMILY, 16, QFont.Bold))
        app_title_label.setAlignment(Qt.AlignCenter)
        top_layout.addWidget(app_title_label)
        cobrand_label = QLabel()
        cobrand_pixmap = QPixmap(MyApp_COBRAND_PATH)
        cobrand_label.setPixmap(cobrand_pixmap)
        top_layout.addWidget(cobrand_label)
        main_layout.addLayout(top_layout)

        # Input section
        input_layout = QVBoxLayout()

        # Input Directory
        input_dir_label = QLabel(MyApp_INPUT_DIR_LABEL)
        input_dir_layout = QHBoxLayout()
        self.input_dir_dropdown = QComboBox()
        self.input_dir_dropdown.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        browse_button = QPushButton("Browse")
        browse_button.clicked.connect(self.browse_directory)
        input_dir_layout.addWidget(self.input_dir_dropdown)
        input_dir_layout.addWidget(browse_button)
        input_layout.addWidget(input_dir_label)
        input_layout.addLayout(input_dir_layout)

        # Start Marker Index
        start_marker_label = QLabel(MyApp_START_MARKER_LABEL)
        start_marker_layout = QHBoxLayout()
        self.start_marker_spinbox = QSpinBox()
        self.start_marker_spinbox.setMinimum(1)
        self.start_marker_spinbox.setValue(1)
        start_marker_layout.addWidget(start_marker_label)
        start_marker_layout.addWidget(self.start_marker_spinbox)
        input_layout.addLayout(start_marker_layout)

        # End Marker Index
        end_marker_label = QLabel(MyApp_END_MARKER_LABEL)
        end_marker_layout = QHBoxLayout()
        self.end_marker_spinbox = QSpinBox()
        self.end_marker_spinbox.setMinimum(1)
        self.end_marker_spinbox.setValue(1)
        end_marker_layout.addWidget(end_marker_label)
        end_marker_layout.addWidget(self.end_marker_spinbox)
        input_layout.addLayout(end_marker_layout)

        # Computation Method
        computation_method_label = QLabel("Computation Method:")
        self.computation_method_dropdown = QComboBox()
        self.computation_method_dropdown.addItems(MyApp_COMPUTATION_METHODS)
        self.computation_method_dropdown.currentIndexChanged.connect(self.computation_method_changed)
        input_layout.addWidget(computation_method_label)
        input_layout.addWidget(self.computation_method_dropdown)

        # Thread Count (for Multi method)
        self.thread_count_label = QLabel("Thread Count:")
        self.thread_count_spinbox = QSpinBox()
        self.thread_count_spinbox.setMinimum(MyApp_THREAD_COUNT_MIN)
        self.thread_count_spinbox.setMaximum(MyApp_THREAD_COUNT_MAX)
        self.thread_count_spinbox.setValue(MyApp_THREAD_COUNT_MIN)
        self.thread_count_spinbox.setVisible(False)
        input_layout.addWidget(self.thread_count_label)
        input_layout.addWidget(self.thread_count_spinbox)

        # Checkpoints (for Joint method)
        # ... (Implement checkpoints input)

        # Odo Gain
        odo_gain_label = QLabel("Odo Gain:")
        self.odo_gain_dropdown = QComboBox()
        self.odo_gain_dropdown.addItems(MyApp_ODO_GAIN_OPTIONS)
        self.odo_gain_dropdown.currentIndexChanged.connect(self.odo_gain_changed)
        input_layout.addWidget(odo_gain_label)
        input_layout.addWidget(self.odo_gain_dropdown)

        # Manual Odo Gain Input
        self.manual_odo_gain_input = QLineEdit()
        self.manual_odo_gain_input.setPlaceholderText(MyApp_MANUAL_ODO_GAIN_PLACEHOLDER)
        self.manual_odo_gain_input.setVisible(False)
        input_layout.addWidget(self.manual_odo_gain_input)

        # Accuracy Method
        accuracy_method_label = QLabel("Accuracy Method:")
        self.accuracy_method_dropdown = QComboBox()
        self.accuracy_method_dropdown.addItems(MyApp_ACCURACY_METHODS)
        input_layout.addWidget(accuracy_method_label)
        input_layout.addWidget(self.accuracy_method_dropdown)

        # Enable Plots
        enable_plots_checkbox = QCheckBox(MyApp_ENABLE_PLOTS_LABEL)
        enable_plots_checkbox.stateChanged.connect(self.enable_plots_changed)
        input_layout.addWidget(enable_plots_checkbox)

        # Plot Frequency
        self.plot_frequency_spinbox = QSpinBox()
        self.plot_frequency_spinbox.setMinimum(1)
        self.plot_frequency_spinbox.setValue(1)
        self.plot_frequency_spinbox.setVisible(False)
        input_layout.addWidget(self.plot_frequency_spinbox)

        # Admin Settings (Hidden)
        self.admin_settings_frame = QFrame()
        self.admin_settings_frame.setFrameShape(QFrame.StyledPanel)
        self.admin_settings_frame.setHidden(True)
        admin_settings_layout = QVBoxLayout()
        admin_settings_label = QLabel(MyApp_ADMIN_SETTINGS_LABEL)
        admin_settings_label.mousePressEvent = self.toggle_admin_settings
        admin_settings_layout.addWidget(admin_settings_label)

        # Replicate Input Settings in Admin Section (Dummy)
        admin_settings_layout.addWidget(QLabel("Admin Input Directory:"))
        admin_settings_layout.addWidget(QLineEdit())
        admin_settings_layout.addWidget(QLabel("Admin Start Marker Index:"))
        admin_settings_layout.addWidget(QSpinBox())
        # ... replicate other input settings
        admin_settings_layout.addWidget(QLabel(MyApp_JSON_INPUT_LABEL))
        admin_settings_layout.addWidget(QLineEdit())

        self.admin_settings_frame.setLayout(admin_settings_layout)
        input_layout.addWidget(self.admin_settings_frame)

        main_layout.addLayout(input_layout)

        # Buttons and Results
        buttons_layout = QHBoxLayout()
        submit_button = QPushButton("Submit")
        submit_button.clicked.connect(self.submit_data)
        reset_button = QPushButton("Reset")
        reset_button.clicked.connect(self.reset_inputs)
        exit_button = QPushButton("Exit")
        exit_button.clicked.connect(QApplication.instance().quit)
        buttons_layout.addWidget(submit_button)
        buttons_layout.addWidget(reset_button)
        buttons_layout.addWidget(exit_button)
        main_layout.addLayout(buttons_layout)

        # Results Table
        self.results_table = QTableWidget()
        self.results_table.setColumnCount(len(MyApp_RESULTS_TABLE_HEADERS))
        self.results_table.setHorizontalHeaderLabels(MyApp_RESULTS_TABLE_HEADERS)
        header = self.results_table.horizontalHeader()
        header.setSectionResizeMode(QHeaderView.Stretch) # Make columns stretch to fit
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_area.setWidget(self.results_table)
        main_layout.addWidget(QLabel("Results:"))
        main_layout.addWidget(scroll_area)

        # Bottom Branding
        bottom_label = QLabel("Powered by My Company | Contact: info@example.com")
        bottom_label.setAlignment(Qt.AlignCenter)
        main_layout.addWidget(bottom_label)

        self.setLayout(main_layout)

        # Timer for polling results
        self.timer = QTimer()
        self.timer.timeout.connect(self.poll_results)

        logger.addHandler(logging.StreamHandler())  # Console handler
        logger.addHandler(logging.FileHandler('app.log'))  # File handler
        logger.info("Application started.")

    def browse_directory(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Directory")
        if directory:
            self.input_dir_dropdown.clear()
            self.input_dir_dropdown.addItem(directory)
            try:
                for item in os.listdir(directory):
                    full_path = os.path.join(directory,item)
                    if os.path.isdir(full_path):
                        self.input_dir_dropdown.addItem(full_path)
            except FileNotFoundError as e:
                logger.error(f"error finding directory {e}")

    def computation_method_changed(self, index):
        method = MyApp_COMPUTATION_METHODS[index]
        self.thread_count_label.setVisible(method == "Multi")
        self.thread_count_spinbox.setVisible(method == "Multi")
        # ... handle visibility for checkpoints input

    def odo_gain_changed(self, index):
        self.manual_odo_gain_input.setVisible(MyApp_ODO_GAIN_OPTIONS[index] == "Manual")

    def enable_plots_changed(self, state):
        self.plot_frequency_spinbox.setVisible(state == Qt.Checked)

    def toggle_admin_settings(self, event):
        self.admin_settings_frame.setHidden(not self.admin_settings_frame.isHidden())

    def submit_data(self):
        # Dummy submission logic (replace with actual backend interaction)
        logger.info(f"Submitting data: Input Dir: {self.input_dir_dropdown.currentText()}, Start: {self.start_marker_spinbox.value()}, End: {self.end_marker_spinbox.value()}")
        # Start polling for results
        self.timer.start(MyApp_POLL_INTERVAL)

    def poll_results(self):
        try:
            if os.path.exists(MyApp_RESULT_FILE_PATH):
                with open(MyApp_RESULT_FILE_PATH, 'r') as f:
                    # Dummy CSV parsing (replace with actual CSV reading)
                    lines = f.readlines()
                    self.results_table.setRowCount(0) #clear table before adding new data
                    for line in lines[1:]:
                        data = line.strip().split(',')
                        row_position = self.results_table.rowCount()
                        self.results_table.insertRow(row_position)
                        for col, item in enumerate(data):
                            table_item = QTableWidgetItem(item)
                            self.results_table.setItem(row_position, col, table_item)
                        status = data[0]
                        color = MyApp_StatusColor[status].value
                        status_widget = QTableWidgetItem()
                        status_widget.setBackground(QColor(color))
                        self.results_table.setItem(row_position, 0, status_widget)

            else:
                logger.info("Result file not found yet.")

        except FileNotFoundError:
            logger.error("Result file not found.")
        except Exception as e:
            logger.error(f"An error occurred while polling results: {e}")

    def reset_inputs(self):
        # Reset all input fields
        self.input_dir_dropdown.setCurrentIndex(0)
        self.start_marker_spinbox.setValue(1)
        self.end_marker_spinbox.setValue(1)
        self.computation_method_dropdown.setCurrentIndex(0)
        self.thread_count_spinbox.setValue(MyApp_THREAD_COUNT_MIN)
        self.odo_gain_dropdown.setCurrentIndex(0)
        self.manual_odo_gain_input.clear()
        self.accuracy_method_dropdown.setCurrentIndex(0)
        # ... reset other inputs
        self.results_table.setRowCount(0)
        self.timer.stop() #stop the poll timer

if __name__ == "__main__":
    from enum import Enum
    from PyQt5.QtGui import QColor
    app = QApplication(sys.argv)
    window = MyApp()
    window.show()
    sys.exit(app.exec_())