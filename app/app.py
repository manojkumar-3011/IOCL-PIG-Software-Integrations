import sys
import os, shutil
import subprocess
import json
from PyQt5.QtWidgets import (
    QApplication, QWidget, QLabel, QPushButton, QVBoxLayout, QHBoxLayout,
    QComboBox, QSpinBox, QLineEdit, QFileDialog, QCheckBox, QTextEdit, QTableWidget,
    QTableWidgetItem, QHeaderView, QGraphicsDropShadowEffect, QLabel, QVBoxLayout, QGraphicsDropShadowEffect,
    QMessageBox
)
from PyQt5.QtCore import Qt, QTimer
from PyQt5.QtGui import QFont, QColor, QPixmap, QIcon
from logger import logger
import schema, constants, utils, messages
from PyQt5.QtCore import QThread, pyqtSignal, QTimer
from PyQt5.QtWidgets import QMessageBox
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QColor, QPainter, QBrush
from PyQt5.QtWidgets import QTableWidgetItem, QTableWidget



def resource_path(relative_path):
    try:
        base_path = sys._MEIPASS2
    except Exception:
        try:
            base_path = sys._MEIPASS
        except Exception:
            base_path = os.path.abspath(".")

    logger.info(f'[RESOURCE PATH]: {os.path.join(base_path, relative_path)}')
    return os.path.join(base_path, relative_path)

# Worker thread to run MATLAB process in background
class MatlabWorker(QThread):
    progress_updated = pyqtSignal(str)

    def __init__(self, input_directory, computation_method, start_marker, end_marker, accuracy_mode, odo_gain, manual_gains, num_threads, checkpoints, plot_frequency, admin_input):
        super().__init__()
        self.input_directory = input_directory
        self.computation_method = computation_method
        self.start_marker = start_marker
        self.end_marker = end_marker
        self.accuracy_mode = accuracy_mode
        self.odo_gain = odo_gain
        self.manual_gains = manual_gains
        self.num_threads = num_threads
        self.checkpoints = checkpoints
        self.plot_frequency = plot_frequency
        self.admin_input = admin_input

    def run(self):
        # Simulate running the MATLAB process
        try:
            self.progress_updated.emit("MATLAB process started")
            utils.init_matlab_from_app(self.input_directory, self.computation_method, self.start_marker, self.end_marker, self.accuracy_mode, self.odo_gain, self.manual_gains, self.num_threads, self.checkpoints, self.plot_frequency, self.admin_input)
            self.progress_updated.emit("MATLAB process completed")
        except Exception as e:
            self.progress_updated.emit(f"Error during MATLAB process: {str(e)}")

class StatusSquareWidget(QWidget):
    def __init__(self, color: QColor, parent=None):
        super().__init__(parent)
        self.color = color
        self.setFixedSize(20, 20)  # Small square size
    
    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setBrush(QBrush(self.color))
        painter.drawRect(0, -5, 20, 20)  # Draw a 20x20 square

class MainWindow(QWidget):
    def __init__(self):
        print("test")
        super().__init__()
        self.setWindowTitle("EKTOpt")
        self.setWindowIcon(QIcon(os.path.abspath(".\\icon\\ektopt_black.ico")))
        self.setGeometry(100, 100, 500, 900)
        self.setStyleSheet("background-color: #f8f9fa;")
        self.threads = []
        self.initUI()

        # Initialize polling timer
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.poll_results)
        self.timer.start(constants.APP_RESULT_POLLING_TIME)  # Poll every msecs

        # Path to the temporary file you want to poll
        self.temp_file_path = os.path.abspath(constants.APP_RESULT_SHEET_PATH)
        # Check if the file exists and delete it
        if os.path.exists(self.temp_file_path):
            os.remove(self.temp_file_path)
            logger.info(f"File {self.temp_file_path} has been deleted.")
        else:
            logger.info(f"File {self.temp_file_path} not found.")
        
        # Init last patch
        self.patch_button(default=os.path.join(os.path.abspath("."), constants.MATLAB_PATCH_PATH))

    def initUI(self):
        # Layouts
        main_layout = QVBoxLayout()

        # Branding and Title
        branding_layout = QHBoxLayout()
        self.add_branding(branding_layout)
        main_layout.addLayout(branding_layout)

        # Patch Directory Section
        patch_dir_layout = QHBoxLayout()
        self.add_patch_directory(patch_dir_layout)
        main_layout.addLayout(patch_dir_layout)

        # Input Directory Section
        input_dir_layout = QHBoxLayout()
        self.add_input_directory(input_dir_layout)
        main_layout.addLayout(input_dir_layout)

        # CSV Input Conversion Section
        csv_input_dir_layout = QHBoxLayout()
        self.add_csv_input_conversion(csv_input_dir_layout)
        main_layout.addLayout(csv_input_dir_layout)

        # Marker and Computation Inputs
        marker_layout = QHBoxLayout()
        self.add_marker_inputs(marker_layout)
        main_layout.addLayout(marker_layout)

        # Computation, Gain and Accuracy Inputs
        computation_layout = QVBoxLayout()
        self.add_computation_inputs(computation_layout)
        main_layout.addLayout(computation_layout)

        # Enable Plots
        plots_layout = QHBoxLayout()
        self.add_enable_plots(plots_layout)
        main_layout.addLayout(plots_layout)

        # Admin Inputs
        admin_layout = QHBoxLayout()
        self.add_admin_inputs(admin_layout)
        main_layout.addLayout(admin_layout)

        # Buttons and Results
        button_layout = QHBoxLayout()
        self.add_buttons(button_layout)
        main_layout.addLayout(button_layout)

        results_layout = QVBoxLayout()
        self.add_results_section(results_layout)
        main_layout.addLayout(results_layout)

        # Final Branding Section
        footer_layout = QVBoxLayout()
        self.add_footer(footer_layout)
        main_layout.addLayout(footer_layout)

        self.setLayout(main_layout)

    def add_branding(self, layout):
        # Branding Logo
        logo_label = QLabel()
        logo_label.setPixmap(QPixmap(os.path.abspath(".\\img\\iitb_coeoge_logo.png")).scaled(250, 400, Qt.KeepAspectRatio, Qt.SmoothTransformation))
        logo_label.setAlignment(Qt.AlignCenter)

        # Caption below logo
        logo_caption = QLabel("भारतीय प्रौद्योगिकी संस्थान मुंबई\nIndian Institute of Technology Bombay")
        logo_caption.setFont(QFont("Arial", 8))
        logo_caption.setAlignment(Qt.AlignCenter)

        # message logo
        logo_aligner = QLabel('Brought to you by')
        logo_aligner.setFont(QFont("Arial", 8))
        logo_aligner.setAlignment(Qt.AlignCenter)

        # Logo + Caption Layout
        logo_layout = QVBoxLayout()
        logo_layout.addWidget(logo_aligner)
        logo_layout.addWidget(logo_label)
        logo_layout.addWidget(logo_caption)

        # Application Title
        title_label = QLabel("Pipeline Trajectory \n Estimation ")
        title_label.setFont(QFont("Helvetica", 18, QFont.Bold))
        title_label.setStyleSheet("background-color: #004ba0; color: #ffffff; border-radius: 5px; padding: 6px 12px;")
        title_label.setAlignment(Qt.AlignCenter)
        title_label.setMaximumHeight(100)
        # title_label.setMaximumWidth(1000)

        shadow_effect = QGraphicsDropShadowEffect()
        shadow_effect.setBlurRadius(16)  # Thinner shadow
        shadow_effect.setColor(QColor("#FF6600"))
        shadow_effect.setOffset(3, 3)
        title_label.setGraphicsEffect(shadow_effect)

        # Co-brand/Sponsor Logo
        sponsor_label = QLabel()
        sponsor_label.setPixmap(QPixmap(os.path.abspath(".\\img\\indianoil_logo.jpg")).scaled(150, 150, Qt.KeepAspectRatio, Qt.SmoothTransformation))
        sponsor_label.setAlignment(Qt.AlignCenter)

        # Caption below sponsor logo
        sponsor_caption = QLabel("The Energy of India!")
        sponsor_caption.setFont(QFont("Arial", 8))
        sponsor_caption.setAlignment(Qt.AlignCenter)

        # Caption below sponsor logo
        sponsor_aligner = QLabel("Powered by")
        sponsor_aligner.setFont(QFont("Arial", 8))
        sponsor_aligner.setAlignment(Qt.AlignCenter)

        # Sponsor + Caption Layout
        sponsor_layout = QVBoxLayout()
        sponsor_layout.addWidget(sponsor_aligner)
        sponsor_layout.addWidget(sponsor_label)
        sponsor_layout.addWidget(sponsor_caption)
        

        # Combine everything in a horizontal layout
        branding_layout = QHBoxLayout()
        branding_layout.addLayout(logo_layout)
        branding_layout.addWidget(title_label)
        branding_layout.addLayout(sponsor_layout)
        branding_layout.setContentsMargins(10, 10, 10, 30)  # Adding space at the bottom for branding

        layout.addLayout(branding_layout)

    def add_patch_directory(self, layout):
        label = QLabel("Patch Directory:")
        label.setFont(QFont("Arial", 12, QFont.Bold))
        
        self.patch_directory_dropdown = QComboBox()
        self.patch_directory_dropdown.setEditable(True)
        self.patch_directory_dropdown.setFont(QFont("Arial", 10))
        self.patch_directory_dropdown.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)
        
        browse_button = QPushButton("Browse")
        browse_button.setFont(QFont("Arial", 9, QFont.Bold))
        browse_button.setStyleSheet("""
            background-color: #008080; /* Teal */
            color: white;
            border-radius: 5px;
            padding: 6px 12px;
        """)
        browse_button.clicked.connect(self.browse_patch_directory)

        process_button = QPushButton("Patch-It !")
        process_button.setFont(QFont("Arial", 11, QFont.Bold))
        process_button.setStyleSheet("""
            background-color: #FFB347;  /* Bright Orange */
            color: Red;
            border-radius: 5px;
            padding: 6px 12px;
        """)
        process_button.clicked.connect(self.patch_button)


        layout.addWidget(label)
        layout.addWidget(self.patch_directory_dropdown, 3)
        layout.addWidget(browse_button, 1)
        layout.addWidget(process_button, 1)

    def add_input_directory(self, layout):
        label = QLabel("MAT Input Directory:")
        label.setFont(QFont("Arial", 12, QFont.Bold))
        
        self.directory_dropdown = QComboBox()
        self.directory_dropdown.setEditable(True)
        self.directory_dropdown.setFont(QFont("Arial", 10))
        self.directory_dropdown.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)

        browse_button = QPushButton("Browse MAT Files")
        browse_button.setFont(QFont("Arial", 12, QFont.Bold))
        browse_button.setStyleSheet("background-color: #007bff; color: white; border-radius: 5px; padding: 6px 12px;")
        browse_button.clicked.connect(self.browse_directory)

        layout.addWidget(label)
        layout.addWidget(self.directory_dropdown, 3)
        layout.addWidget(browse_button, 1)
    

    def add_csv_input_conversion(self, layout):
        label = QLabel("Convert+Add CSV files to MAT database:")
        label.setFont(QFont("Arial", 10, QFont.Bold))
        label.setMaximumWidth(280)

        self.db_name_input = QLineEdit()
        self.db_name_input.setMinimumWidth(450)
        self.db_name_input.setPlaceholderText("Enter a unique directory name to save to the input Database of MAT Files.")
        self.db_name_input.setFont(QFont("Arial", 10))
        self.db_name_input.setVisible(True)
        self.db_name_input.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)

        process_csv_button = QPushButton("Process CSV?")
        process_csv_button.setMaximumWidth(150)
        process_csv_button.setFont(QFont("Arial", 8, QFont.Bold))
        process_csv_button.setStyleSheet("""
            background-color: #FFD700; /* Vibrant Yellow */
            color: black;
            border-radius: 5px;
            padding: 6px 12px;
        """)

        process_csv_button.clicked.connect(self.process_ip_button)

        layout.addWidget(label)
        layout.addWidget(self.db_name_input)
        layout.addWidget(process_csv_button, 1)


    def add_marker_inputs(self, layout):
        start_marker_label = QLabel("Start Marker Index:")
        start_marker_label.setFont(QFont("Arial", 12, QFont.Bold))

        self.start_marker_input = QSpinBox()
        self.start_marker_input.setFont(QFont("Arial", 10))
        self.start_marker_input.setMinimum(1)
        self.start_marker_input.setMaximum(constants.APP_MAX_END_MARKER-1)
        
        checkpoint_steps_label = QLabel("Checkpoints Steps:")
        checkpoint_steps_label.setFont(QFont("Arial", 12, QFont.Bold))

        self.checkponint_steps_input = QSpinBox()
        self.checkponint_steps_input.setFont(QFont("Arial", 10))
        self.checkponint_steps_input.setMinimum(constants.APP_MIN_CHECKPOINT_STEPS)
        self.checkponint_steps_input.setMaximum(constants.APP_MAX_CHECKPOINT_STEPS)
        self.checkponint_steps_input.setValue(constants.APP_DEFAULT_CHECKPOINT_STEPS)

        end_marker_label = QLabel("End Marker Index:")
        end_marker_label.setFont(QFont("Arial", 12, QFont.Bold))

        self.end_marker_input = QSpinBox()
        self.end_marker_input.setFont(QFont("Arial", 10))
        self.end_marker_input.setMinimum(1)
        self.end_marker_input.setMaximum(constants.APP_MAX_END_MARKER)
        self.end_marker_input.setValue(constants.APP_DEFAULT_END_MARKER)

        self.start_marker_input.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)
        self.checkponint_steps_input.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)
        self.end_marker_input.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)

        layout.addWidget(start_marker_label)
        layout.addWidget(self.start_marker_input)
        layout.addWidget(checkpoint_steps_label)
        layout.addWidget(self.checkponint_steps_input)
        layout.addWidget(end_marker_label)
        layout.addWidget(self.end_marker_input)

    def add_computation_inputs(self, layout):
        computation_method_label = QLabel("Computation Method:")
        computation_method_label.setFont(QFont("Arial", 12, QFont.Bold))

        self.computation_method_dropdown = QComboBox()
        self.computation_method_dropdown.addItems(schema.ComputationMethod.long_list())
        self.computation_method_dropdown.setFont(QFont("Arial", 10))
        self.computation_method_dropdown.currentIndexChanged.connect(self.update_joint_input_visibility)
        
        thread_label = QLabel("Threads:")
        thread_label.setFont(QFont("Arial", 12, QFont.Bold))

        self.thread_input = QSpinBox()
        self.thread_input.setFont(QFont("Arial", 10))
        self.thread_input.setMinimum(constants.APP_MIN_THREADS)
        self.thread_input.setMaximum(constants.APP_MAX_THREADS)

        gain_label = QLabel("Odo Gain:")
        gain_label.setFont(QFont("Arial", 12, QFont.Bold))

        self.gain_dropdown = QComboBox()
        self.gain_dropdown.addItems(schema.GainSetting.long_list())
        self.gain_dropdown.setFont(QFont("Arial", 10))
        self.gain_dropdown.currentIndexChanged.connect(self.update_gain_input_visibility)
        accuracy_label = QLabel("Accuracy Mode:")
        accuracy_label.setFont(QFont("Arial", 12, QFont.Bold))

        self.accuracy_dropdown = QComboBox()
        self.accuracy_dropdown.addItems(schema.AccuracyMethod.long_list())
        self.accuracy_dropdown.setFont(QFont("Arial", 10))

        self.joint_checkpoints_input = QLineEdit()
        self.joint_checkpoints_input.setPlaceholderText("Enter comma-separated markers as checkpoints or set the Checkpoint Steps option above to auto populate.")
        self.joint_checkpoints_input.setFont(QFont("Arial", 10))
        self.joint_checkpoints_input.setVisible(False)

        self.gain_manual_input = QLineEdit()
        self.gain_manual_input.setPlaceholderText("Enter comma-separated gain values for each section")
        self.gain_manual_input.setFont(QFont("Arial", 10))
        self.gain_manual_input.setVisible(False)

        self.computation_method_dropdown.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)
        self.joint_checkpoints_input.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)
        self.thread_input.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)
        self.gain_dropdown.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)
        self.gain_manual_input.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)
        self.accuracy_dropdown.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)

        self.computation_method_dropdown.setCurrentIndex(2)
        layout.addWidget(computation_method_label)
        layout.addWidget(self.computation_method_dropdown)
        layout.addWidget(self.joint_checkpoints_input)
        layout.addWidget(thread_label)
        layout.addWidget(self.thread_input)
        layout.addWidget(gain_label)
        layout.addWidget(self.gain_dropdown)
        layout.addWidget(self.gain_manual_input)
        layout.addWidget(accuracy_label)
        layout.addWidget(self.accuracy_dropdown)

    def update_joint_input_visibility(self):
        self.joint_checkpoints_input.setVisible(self.computation_method_dropdown.currentText() == schema.ComputationMethod.JOINT.long_name())
    
    def update_gain_input_visibility(self):
        self.gain_manual_input.setVisible(self.gain_dropdown.currentText() == schema.GainSetting.GAIN_MANUAL.long_name())
    
    def add_enable_plots(self, layout):
        self.enable_plots_checkbox = QCheckBox("Enable Plots")
        self.enable_plots_checkbox.setFont(QFont("Arial", 12, QFont.Bold))
        self.enable_plots_checkbox.stateChanged.connect(self.toggle_graph_frequency_input)

        graph_frequency_label = QLabel("Graph Frequency:")
        graph_frequency_label.setFont(QFont("Arial", 12, QFont.Bold))
        
        self.graph_frequency_input = QSpinBox()
        self.graph_frequency_input.setFont(QFont("Arial", 10))
        self.graph_frequency_input.setMinimum(1)
        self.graph_frequency_input.setEnabled(False)

        self.graph_frequency_input.setStyleSheet(constants.INPUT_FIELD_STYLE_SHEET)

        layout.addWidget(self.enable_plots_checkbox)
        layout.addWidget(graph_frequency_label)
        layout.addWidget(self.graph_frequency_input)

    def toggle_graph_frequency_input(self):
        self.graph_frequency_input.setEnabled(self.enable_plots_checkbox.isChecked())

    def add_admin_inputs(self, layout):
        self.admin_checkbox = QCheckBox("Admin Inputs")
        self.admin_checkbox.setFont(QFont("Arial", 12, QFont.Bold))
        self.admin_checkbox.stateChanged.connect(self.toggle_admin_input_visibility)

        self.admin_input_field = QTextEdit()
        self.admin_input_field.setPlaceholderText("Enter JSON/Text input for admin settings")
        self.admin_input_field.setFont(QFont("Arial", 10))
        self.admin_input_field.setVisible(False)

        layout.addWidget(self.admin_checkbox)
        layout.addWidget(self.admin_input_field)
        
    def toggle_admin_input_visibility(self):
        self.admin_input_field.setVisible(self.admin_checkbox.isChecked())

    def add_buttons(self, layout):
        submit_button = QPushButton("Submit")
        submit_button.setFont(QFont("Arial", 12, QFont.Bold))
        submit_button.setStyleSheet("background-color: #28a745; color: white; border-radius: 5px; padding: 6px 12px;")
        submit_button.clicked.connect(self.submit)

        reset_button = QPushButton("Reset")
        reset_button.setFont(QFont("Arial", 12, QFont.Bold))
        reset_button.setStyleSheet("background-color: #007bff; color: white; border-radius: 5px; padding: 6px 12px;")
        reset_button.clicked.connect(self.reset_inputs)

        exit_button = QPushButton("Exit")
        exit_button.setFont(QFont("Arial", 12, QFont.Bold))
        exit_button.setStyleSheet("background-color: #dc3545; color: white; border-radius: 5px; padding: 6px 12px;")
        exit_button.clicked.connect(self.on_exit)

        integrate_button = QPushButton("integrate")
        integrate_button.setFont(QFont("Arial", 12, QFont.Bold))
        integrate_button.setStyleSheet("background-color: #dc3545; color: white; border-radius: 5px; padding: 6px 12px;")
        integrate_button.clicked.connect(self.on_integrate)

        layout.addWidget(submit_button)
        layout.addWidget(reset_button)
        layout.addWidget(exit_button)
        layout.addWidget(integrate_button)

    def add_results_section(self, layout):
        results_label = QLabel("Results")
        results_label.setFont(QFont("Arial", 14, QFont.Bold))
        
        self.results_table = QTableWidget()
        self.results_table.setColumnCount(len(constants.APP_RESULT_SHEET_COLS))
        self.results_table.setHorizontalHeaderLabels(constants.APP_RESULT_SHEET_COLS)

        header = self.results_table.horizontalHeader()
        
        # Prevent any column from consuming too much space
        header.setSectionResizeMode(QHeaderView.Interactive)  # Allow manual resizing
        header.setStretchLastSection(False)  # Avoid stretching the last column to fill space
        
        # Set a reasonable max width for the path column (assuming it's index 4)
        path_column_index = 4  # Update this based on your column position
        header.setSectionResizeMode(path_column_index, QHeaderView.Interactive)
        self.results_table.setColumnWidth(path_column_index, 300)  # Set an initial width
        self.results_table.setWordWrap(False)  # Prevent text wrapping from making cells huge

        # Ensure headers stay visible
        header.setMinimumHeight(30)  # Make sure headers have a fixed height
        header.setVisible(True)  

        layout.addWidget(results_label)
        layout.addWidget(self.results_table)

    def add_footer(self, layout):
        footer_label = QLabel("Created at Centre of Excellence in Oil, Gas and Energy, IIT Bombay | Contact: pic.coeoge@iitb.ac.in")
        footer_label.setFont(QFont("Arial", 10, QFont.Bold))
        footer_label.setStyleSheet("background-color: #333; color: #fff; border-radius: 5px; padding: 6px 12px;")
        footer_label.setAlignment(Qt.AlignCenter)
        layout.addWidget(footer_label)
        footer_label_auth = QLabel("by Dr. Somnath Buriuly & Siddhesh Girase")
        footer_label_auth.setFont(QFont("Arial", 10, QFont.Bold))
        footer_label_auth.setStyleSheet("background-color: #1a1a2e; color: #add8e6; border-radius: 5px; padding: 6px 12px;")
        footer_label_auth.setAlignment(Qt.AlignCenter)
        layout.addWidget(footer_label_auth)

    def browse_patch_directory(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Directory")
        if directory:
            self.patch_directory_dropdown.addItem(directory)
            self.patch_directory_dropdown.setCurrentText(directory)

    def browse_directory(self):
        file_or_dir = QFileDialog.getExistingDirectory(self, "Select Directory", constants.MAT_DB_RELATIVE_PATH)

        if file_or_dir:
            self.directory_dropdown.addItem(file_or_dir)
            self.directory_dropdown.setCurrentText(file_or_dir)
        else:
            self.directory_dropdown.setCurrentText(None)

    def reset_inputs(self):
        self.start_marker_input.setValue(1)
        self.checkponint_steps_input.setValue(constants.APP_DEFAULT_CHECKPOINT_STEPS)
        self.end_marker_input.setValue(constants.APP_DEFAULT_END_MARKER)
        self.directory_dropdown.setCurrentIndex(-1)
        self.computation_method_dropdown.setCurrentIndex(2)
        self.thread_input.setValue(1)
        self.gain_dropdown.setCurrentIndex(0)
        self.gain_manual_input.clear()
        self.gain_manual_input.setVisible(False)
        self.graph_frequency_input.setValue(0)
        self.results_table.setRowCount(0)
    
    def validate_input_directory(self):
        # Fetch input directory
        input_directory = self.directory_dropdown.currentText()
        if not input_directory:
            logger.warning("Input directory is empty")
            QMessageBox.warning(self, "Input Error", "Please select an input directory.")
            return
        return input_directory
    
    def validate_start_and_end_markers(self):
        start_marker = self.start_marker_input.value()
        end_marker = self.end_marker_input.value()
        check_point_steps = self.checkponint_steps_input.value()
        if start_marker >= end_marker:
            logger.warning("Start Marker Index must be smaller than End Marker Index.")
            QMessageBox.warning(self, "Input Error", "Start Marker Index must be smaller than End Marker Index.")
            return
        elif check_point_steps > (end_marker-start_marker):
            logger.warning("Steps are greater than the total section selected.")
            QMessageBox.warning(self, "Input Error", "Steps are greater than the total section selected.")
            return
        return start_marker, check_point_steps, end_marker
            
    def validate_compute_method_and_options(self, start_marker, checkpoint_steps, end_marker):
        # Fetch computation method
        computation_method = self.computation_method_dropdown.currentText()
        logger.info(f"Computation Method selected: {computation_method}")
        
        # Fetch additional options based on the method
        checkpoints = [cp for cp in range(start_marker, end_marker+1, constants.APP_MIN_CHECKPOINT_STEPS)]
        num_threads = self.thread_input.value()
        if num_threads < constants.APP_MIN_THREADS:
            logger.info(f"Number of threads cannot be less than 1")
            QMessageBox.warning(self, "Single Thread Usage", "Number of threads cannot be less than 1")
            num_threads = constants.APP_MIN_THREADS
            self.thread_input.setValue(num_threads)

        if computation_method == schema.ComputationMethod.MULTI.long_name():
            logger.info(f"Number of threads: {num_threads}")
        elif computation_method == schema.ComputationMethod.JOINT.long_name():
            checkpoints = [cp for cp in range(start_marker, end_marker+1, checkpoint_steps)]
            if self.joint_checkpoints_input.text():
                checkpoints = self.joint_checkpoints_input.text()
                checkpoints = utils.extract_numbers_from_text(checkpoints, int)
                checkpoints = [cp for cp in checkpoints if cp <= end_marker]
            if start_marker not in checkpoints:
                checkpoints = [start_marker] + checkpoints
            if end_marker not in checkpoints:
                checkpoints = checkpoints + [end_marker]
            checkpoints.sort()
            logger.info(f"Joint Checkpoints: {checkpoints}")
            self.joint_checkpoints_input.setText(str(checkpoints))
        else:
            if num_threads > 1:
                logger.info(f"Only 1 thread will be used at a time for SEQUENTIAL computation method")
                QMessageBox.warning(self, "Single Thread Usage", "Only 1 thread will be used at a time for SEQUENTIAL computation method")
            num_threads = 1
            self.thread_input.setValue(num_threads)
        
        return computation_method, num_threads, checkpoints
    
    def validate_odo_gains(self, checkpoints):
        odo_gain = self.gain_dropdown.currentText()
        manual_gains = []
        if odo_gain == schema.GainSetting.GAIN_MANUAL.long_name():
            manual_gains = self.gain_manual_input.text()
            manual_gains = utils.extract_numbers_from_text(manual_gains, float)
            logger.info(f"Manual Odo Gain values: {manual_gains}")

            if len(manual_gains) == 1:
                manual_gains = manual_gains * (len(checkpoints)-1)
            if len(manual_gains) != len(checkpoints)-1 or not manual_gains:
                logger.warning("The number of gains provided and the number of sections for this JOINT run do not match!")
                QMessageBox.warning(self, "Input Error", "The number of gains provided and the number of sections for this JOINT run do not match!")
                return
        return odo_gain, manual_gains
    
    def validate_accuracy_mode(self):
        # Fetch Accuracy Mode
        accuracy_mode = self.accuracy_dropdown.currentText()
        if accuracy_mode == schema.AccuracyMethod.ACCURACY_MODE.long_name() or accuracy_mode == schema.AccuracyMethod.VM_MODE.long_name():
            logger.warning("This Accuracy mode is NOT IMPLEMENTED at the moment! Please select Quick or Quick+Accuracy Mode")
            QMessageBox.warning(self, "Input Error", "This Accuracy mode is NOT IMPLEMENTED at the moment! Please select Quick or Quick+Accuracy Mode")
            return
        return accuracy_mode
    
    def validate_plotting_options(self):
        enable_plots = self.enable_plots_checkbox.isChecked()
        plot_frequency = self.graph_frequency_input.value()
        if enable_plots and plot_frequency > 0:
            plot_frequency = self.graph_frequency_input.value()
            logger.info(f"Plots enabled with frequency: Every {plot_frequency} iteration")
        else:
            plot_frequency = None
            logger.info(f"Plots Disabled")
        return enable_plots, plot_frequency
    
    def validate_admin_options(self):
        # WIP
        if self.admin_checkbox.isChecked():
            admin_input = self.admin_input_field.toPlainText()
            logger.info(f"Admin input: {admin_input}")
        else:
            admin_input = {}       
        return admin_input 

    def poll_results(self):
        # Simulate polling results every 10 seconds
        if os.path.exists(self.temp_file_path):
            with open(self.temp_file_path, "r") as f:
                lines = [line.strip().split(",") for line in f.readlines()]
            self.update_results_table(lines[1:])

    def update_results_table(self, data):
        self.results_table.setRowCount(0)  # Clear existing table data

        for row_data in data:
            row = self.results_table.rowCount()
            self.results_table.insertRow(row)

            for col, item in enumerate(row_data):
                if col == 0:  # Assuming the status is in the first column
                    # Get the status enum and corresponding color
                    try:
                        status_enum = schema.AppStatus.from_string(item)
                        status_widget = StatusSquareWidget(status_enum.color())
                        
                        # Create a container widget to center the status widget
                        container_widget = QWidget()
                        container_layout = QHBoxLayout(container_widget)
                        container_layout.setAlignment(Qt.AlignCenter)
                        container_layout.addWidget(status_widget)
                        container_widget.setLayout(container_layout)
                        
                        # Set the container widget to center-align the color square in the cell
                        self.results_table.setCellWidget(row, col, container_widget)
                    except ValueError as e:
                        logger.error(f"Error converting status: {str(e)}")
                        # Default to a neutral color in case of error
                        status_widget = StatusSquareWidget(QColor("gray"))
                        container_widget = QWidget()
                        container_layout = QHBoxLayout(container_widget)
                        container_layout.setAlignment(Qt.AlignCenter)
                        container_layout.addWidget(status_widget)
                        container_widget.setLayout(container_layout)
                        self.results_table.setCellWidget(row, col, container_widget)
                else:
                    item_widget = QTableWidgetItem(item)
                    item_widget.setTextAlignment(Qt.AlignCenter)  # Center-align the text
                    self.results_table.setItem(row, col, item_widget)

    def update_progress(self, message):
        # Update the progress based on messages from the MATLAB worker thread
        logger.info(message)
        # QMessageBox.information(self, "MATLAB Progress", message)       

    def on_exit(self):
        """Custom exit logic."""
        # Terminate threads if any
        for thread in self.threads:
            thread.quit()  # Gracefully stop QThreads
            # thread.wait()  # Wait for the thread to finish
            thread.terminate()
        
        utils.shutdown_flag.set()

        # If you're using multiprocessing
        # Terminate all child processes
        if hasattr(self, "processes"):
            for process in self.processes:
                process.terminate()
                process.join()

        self.close()  # Close the main window


    def on_integrate(self):
        # print("hello")
        # for i in utils.result_folders:
        #     print("File path:", i)
        folder_list = []
        import pandas as pd
        
        # df = pd.read_csv("fruits.csv")
        # df = pd.read_csv(os.path.join(os.path.abspath("."), constants.APP_RESULT_FOLDER_PATH), header=None).values.tolist()
        exceldatapath = os.path.join(os.path.abspath("."), constants.APP_RESULT_FOLDER_PATH)
        df = pd.read_csv(
            exceldatapath,
            header=None,
            names=['Result Folder'])
        os.remove(exceldatapath)
        folder_list = df["Result Folder"].values.tolist()
        # Absolute or relative path to multiply_runtime_input.py
        script_path = r"C:\Users\ParthGhag_ECL109\Documents\TIH\IOCL-UPDATE\24inch_code_iocl_with_defect_marking\main.py"  # <- change as needed
        json_paths = json.dumps(folder_list)
        
        # from datetime import datetime
        # pd.DataFrame(
        #     data={
        #         "file paths": folder_list
        #     }
        # ).to_csv(f"files_paths_{datetime.now()}.csv")
        
        
        
        # # App1
        # for path in folder_list: 
        #     df.to_csv(path, index=False)  # automatically closes file

        # Wait a moment to ensure OS releases any locks
        import time
        time.sleep(0.1)
        
        
        subprocess.run(["python", script_path, json_paths], shell=False)
        # subprocess.Popen(
        #     ["python", script_path, json_paths],
        #     creationflags=subprocess.CREATE_NEW_CONSOLE)

    def closeEvent(self, event):
        """Handle cleanup when the window is closed."""
        self.on_exit()
        event.accept()

    def submit(self):
        logger.info("Submit button clicked")
        
        # Example logic for handling user inputs
        try:

            # fetch input directory
            _ = self.validate_input_directory()
            if _:
                input_directory = _
            else:
                return
            
            # Validate start and end markers
            _ = self.validate_start_and_end_markers()
            if _:
                start_marker, checkpoint_steps, end_marker = _
            else:
                return
            
            # Handle computation method and its options
            _ = self.validate_compute_method_and_options(start_marker, checkpoint_steps, end_marker)
            if _:
                computation_method, num_threads, checkpoints = _
            else:
                return
            
            # Fetch Odo Gains in required format
            _ = self.validate_odo_gains(checkpoints)
            if _:
                odo_gain, manual_gains = _
            else:
                return

            _ = self.validate_accuracy_mode()
            if _:
                accuracy_mode = _
            else:
                return

            # Fetch Enable Plots option
            _ = self.validate_plotting_options()
            if _:
                enable_plots, plot_frequency = _
            else:
                return

            # Fetch Admin Input if applicable
            admin_input = self.validate_admin_options()
            
            # Start the MATLAB process in a separate thread
            self.matlab_worker = MatlabWorker(input_directory, computation_method, start_marker, end_marker, accuracy_mode, odo_gain, manual_gains, num_threads, checkpoints, plot_frequency, admin_input)
            self.matlab_worker.progress_updated.connect(self.update_progress)
            self.threads.append(self.matlab_worker)
            self.matlab_worker.start()

            # Start polling for results immediately after submission
            self.poll_results()

            QMessageBox.information(self, "Submission Successful", "Inputs submitted successfully!")

        except Exception as e:
            logger.error(f"Error during submission: {str(e)}")
            QMessageBox.critical(self, "Submission Error", f"An error occurred: {str(e)}")
    
    def patch_button(self, default=None):
        logger.info('Patching Update..')
        QMessageBox.information(self, "Update", "Looking for patch files..")

        if default:
            # os.path.join(os.path.abspath("."), constants.MAT_PATCH_RELATIVE_PATH)
            patch_directory = default
        else:
            patch_directory = self.patch_directory_dropdown.currentText()
            default = None
        
        if not patch_directory:
            logger.warning("Patch directory is empty")
            QMessageBox.warning(self, "Patch Error", "Please select a patch directory.")
            return
        
        if not os.path.exists(os.path.join(patch_directory, constants.MATLAB_PATCH_FILE_NAME)):
            logger.warning(f"{constants.MATLAB_PATCH_FILE_NAME} not found")
            if not default:
                QMessageBox.warning(self, "Patch Error", f"Please select a valid Patch Directory with a '{constants.MATLAB_PATCH_FILE_NAME}' file.")
            return
        else:
            self.patch_folder_name = os.path.basename(patch_directory.rstrip("/"))
            logger.info(self.patch_folder_name)
            utils.copy_input_folders(os.path.dirname(patch_directory.rstrip("/")), resource_path(constants.MATLAB_RELATIVE_PATH), replace_existing=True, folders_to_copy=[self.patch_folder_name])
            # Check if destination exists and delete it
            if not default and os.path.exists(os.path.join(resource_path(constants.MATLAB_RELATIVE_PATH), constants.MATLAB_PATCH_PATH)):
                shutil.rmtree(os.path.join(resource_path(constants.MATLAB_RELATIVE_PATH), constants.MATLAB_PATCH_PATH))  # Delete the existing directory
            os.rename(os.path.join(resource_path(constants.MATLAB_RELATIVE_PATH), self.patch_folder_name), os.path.join(resource_path(constants.MATLAB_RELATIVE_PATH), constants.MATLAB_PATCH_PATH))
            utils.copy_input_folders(os.path.join(resource_path(constants.MATLAB_RELATIVE_PATH)), os.path.abspath("."), replace_existing=True, folders_to_copy=[constants.MATLAB_PATCH_PATH])
        try:
            patch_script_path = resource_path(os.path.join(constants.MATLAB_RELATIVE_PATH, constants.MATLAB_PATCH_FILE_PATH))
            _, elapsed_time = utils.run_matlab_script(patch_script_path, "", nodisplay=False)
            logger.info(f'Patched in {elapsed_time:.2f} seconds!')
            QMessageBox.information(self, "Update Successful", f"Files patched in {elapsed_time:.2f} seconds!")
            return
        except Exception as e:
            logger.error(f"Error during patching: {str(e)}")
            QMessageBox.critical(self, "Patching Error", f"An error occurred: {str(e)}")
    
    def process_ip_button(self):
        logger.info('Processing Input Files')
        QMessageBox.information(self, "Input", "Processing Input files..")
        
        try:
            mat_db_path = os.path.join(os.path.abspath("."), constants.MAT_DB_RELATIVE_PATH, self.db_name_input.text())
            if not os.path.exists(constants.MAT_DB_RELATIVE_PATH):
                logger.info(f"Creating MAT DB folder..")
                os.makedirs(constants.MAT_DB_RELATIVE_PATH)
            
            if self.db_name_input.text() and not os.path.exists(mat_db_path):
                logger.info(f"Processing CSV files..")

                csv2mat_script_path = resource_path(os.path.join(constants.MATLAB_RELATIVE_PATH, constants.CSV2MAT_SCRIPT_PATH))
                _, elapsed_time = utils.run_matlab_script(csv2mat_script_path, "", nodisplay=False)
                logger.info(f'Input csv file processed in {elapsed_time:.2f} seconds!')

                os.makedirs(mat_db_path)
                utils.copy_input_folders(resource_path(constants.MATLAB_RELATIVE_PATH), os.path.join(constants.MAT_DB_RELATIVE_PATH, self.db_name_input.text()), replace_existing=True, folders_to_copy=constants.MATLAB_INPUT_FOLDERS)

                QMessageBox.information(self, "Conversion Successful", f"CSV input converted in {elapsed_time:.2f} seconds!")

                self.directory_dropdown.setCurrentText(mat_db_path)

                return
            
            else:
                logger.warning("Please provide a unique directory name first!")
                QMessageBox.warning(self, "CSV file conversion Error", f"Please provide a unique directory name first!")
                return
            
        except Exception as e:
            logger.error(f"Error during input processing: {str(e)}")
            QMessageBox.critical(self, "Processing Error", f"An error occurred: {str(e)}")


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setWindowIcon(QIcon(os.path.abspath(".\\icon\\ektopt_black.ico")))
    window = MainWindow()
    window.show()
    print("LastLineNew")
    sys.exit(app.exec_())
