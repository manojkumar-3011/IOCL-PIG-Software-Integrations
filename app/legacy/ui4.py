import sys
import os
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QPushButton, QFileDialog, QVBoxLayout,
    QHBoxLayout, QWidget, QLabel, QComboBox, QLineEdit, QFormLayout, 
    QSpinBox, QCheckBox, QDoubleSpinBox
)
from PyQt5.QtGui import QFont
from PyQt5.QtCore import Qt, QTimer
from constants import AppConfig
from schema import FileType, FontStyle, ComputationMethod
from messages import Messages
from logger import logger

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.init_ui()

    def init_ui(self):
        # Set up main window
        self.setWindowTitle(AppConfig.APP_TITLE)
        self.setGeometry(100, 100, AppConfig.WINDOW_WIDTH, AppConfig.WINDOW_HEIGHT)
        self.logger = logger

        # Set up central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)
        layout.setContentsMargins(20, 20, 20, 20)

        # Logo and Title Section
        header_layout = QHBoxLayout()
        header_layout.setSpacing(20)

        # Logo Placeholder
        self.logo_placeholder = QLabel(AppConfig.LOGO_PLACEHOLDER_TEXT)
        self.logo_placeholder.setAlignment(Qt.AlignLeft)
        self.logo_placeholder.setFont(self.get_font(FontStyle.BOLD, 20))
        self.logo_placeholder.setStyleSheet("color: gray;")
        header_layout.addWidget(self.logo_placeholder, stretch=1)

        # Title Placeholder
        self.title_placeholder = QLabel(AppConfig.TITLE_PLACEHOLDER_TEXT)
        self.title_placeholder.setAlignment(Qt.AlignCenter)
        self.title_placeholder.setFont(self.get_font(FontStyle.BOLD, 18))
        self.title_placeholder.setStyleSheet("color: black;")
        header_layout.addWidget(self.title_placeholder, stretch=2)

        layout.addLayout(header_layout)

        # Directory Selection Prompt
        dir_prompt = QLabel("Please select the input directory to proceed:")
        dir_prompt.setFont(self.get_font(FontStyle.NORMAL, 12))
        dir_prompt.setAlignment(Qt.AlignLeft)
        dir_prompt.setStyleSheet("color: black; margin-bottom: 5px;")
        layout.addWidget(dir_prompt)

        # Directory Selection Section
        dir_selection_layout = QHBoxLayout()
        dir_selection_layout.setSpacing(10)

        # Dropdown for showing current directory subfolders
        self.directory_dropdown = QComboBox(self)
        self.directory_dropdown.setEditable(True)
        self.directory_dropdown.setFont(self.get_font(FontStyle.NORMAL, 10))
        self.directory_dropdown.setStyleSheet(
            f"background-color: {AppConfig.DROPDOWN_BG_COLOR}; color: {AppConfig.DROPDOWN_TEXT_COLOR}; padding: 5px; border: 1px solid #ccc;"
        )
        self.directory_dropdown.addItem(AppConfig.DIR_DROPDOWN_DEFAULT)
        dir_selection_layout.addWidget(self.directory_dropdown, stretch=7)

        # Directory selection button
        select_dir_button = QPushButton("Browse", self)
        select_dir_button.setFont(self.get_font(FontStyle.BOLD, 10))
        select_dir_button.setStyleSheet(
            f"background-color: {AppConfig.BUTTON_BG_COLOR}; color: {AppConfig.BUTTON_TEXT_COLOR}; padding: 8px; border-radius: 5px;"
        )
        select_dir_button.clicked.connect(self.select_directory)
        dir_selection_layout.addWidget(select_dir_button, stretch=3)

        layout.addLayout(dir_selection_layout)


        # Add Start Marker Index and End Marker Index inputs
        marker_layout = QFormLayout()
        self.start_marker_input = QSpinBox()
        self.start_marker_input.setRange(0, 10000)  # Example range
        self.start_marker_input.setValue(0)
        self.start_marker_input.setFont(self.get_font(FontStyle.NORMAL, 10))
        marker_layout.addRow("Start Marker Index:", self.start_marker_input)

        self.end_marker_input = QSpinBox()
        self.end_marker_input.setRange(0, 10000)  # Example range
        self.end_marker_input.setValue(0)
        self.end_marker_input.setFont(self.get_font(FontStyle.NORMAL, 10))
        marker_layout.addRow("End Marker Index:", self.end_marker_input)
        layout.addLayout(marker_layout)

        # Computation Method Dropdown
        self.computation_method_dropdown = QComboBox(self)
        self.computation_method_dropdown.setFont(self.get_font(FontStyle.NORMAL, 10))
        self.computation_method_dropdown.addItems(
            [method.value for method in ComputationMethod]
        )
        self.computation_method_dropdown.setStyleSheet(
            f"background-color: {AppConfig.DROPDOWN_BG_COLOR}; color: {AppConfig.DROPDOWN_TEXT_COLOR}; padding: 5px; border: 1px solid #ccc;"
        )
        layout.addWidget(QLabel("Select Computation Method:"))
        layout.addWidget(self.computation_method_dropdown)

        # Define Gain Section
        # Gain Option Dropdown
        gain_layout = QHBoxLayout()

        gain_label = QLabel("Define Gain:")
        gain_label.setFont(self.get_font(FontStyle.NORMAL, 12))
        gain_layout.addWidget(gain_label)

        self.gain_option_dropdown = QComboBox(self)
        self.gain_option_dropdown.setFont(self.get_font(FontStyle.NORMAL, 10))
        self.gain_option_dropdown.addItems(["Option 1", "Option 2", "User-Defined"])
        self.gain_option_dropdown.setStyleSheet(
            f"background-color: {AppConfig.DROPDOWN_BG_COLOR}; color: {AppConfig.DROPDOWN_TEXT_COLOR}; padding: 5px; border: 1px solid #ccc;"
        )
        gain_layout.addWidget(self.gain_option_dropdown)

        # User-defined gain input (initially hidden)
        self.user_defined_gain_input = QDoubleSpinBox(self)
        self.user_defined_gain_input.setRange(0.1, 100.0)  # Adjust range as necessary
        self.user_defined_gain_input.setSingleStep(0.1)
        self.user_defined_gain_input.setFont(self.get_font(FontStyle.NORMAL, 10))
        self.user_defined_gain_input.setVisible(False)
        self.user_defined_gain_input.setStyleSheet(
            f"background-color: {AppConfig.INPUT_BG_COLOR}; color: {AppConfig.INPUT_TEXT_COLOR}; padding: 5px; border: 1px solid #ccc;"
        )
        gain_layout.addWidget(self.user_defined_gain_input)

        layout.addLayout(gain_layout)

        # Connect dropdown to toggle visibility of user-defined input
        self.gain_option_dropdown.currentTextChanged.connect(self.toggle_gain_input)

        gain_layout = QHBoxLayout()
        self.gain_dropdown = QComboBox(self)
        self.gain_dropdown.addItems(["Low Gain", "High Gain", "Custom Gain"])
        self.gain_dropdown.setFont(self.get_font(FontStyle.NORMAL, 10))
        self.gain_dropdown.currentIndexChanged.connect(self.toggle_custom_gain_input)
        gain_layout.addWidget(self.gain_dropdown, stretch=1)

        self.custom_gain_input = QLineEdit()
        self.custom_gain_input.setPlaceholderText("Enter custom gain (float)")
        self.custom_gain_input.setFont(self.get_font(FontStyle.NORMAL, 10))
        self.custom_gain_input.setVisible(False)  # Initially hidden
        gain_layout.addWidget(self.custom_gain_input, stretch=2)

        layout.addLayout(gain_layout)

        # Enable Graphs Checkbox
        self.enable_graphs_checkbox = QCheckBox("Enable Graphs")
        self.enable_graphs_checkbox.setFont(self.get_font(FontStyle.NORMAL, 12))
        self.enable_graphs_checkbox.stateChanged.connect(self.toggle_graphs_input)
        layout.addWidget(self.enable_graphs_checkbox)

        # Integer input for graphs (initially hidden)
        self.graph_input = QSpinBox()
        self.graph_input.setRange(1, 100)  # Adjust range as needed
        self.graph_input.setValue(1)
        self.graph_input.setFont(self.get_font(FontStyle.NORMAL, 10))
        self.graph_input.setVisible(False)  # Hidden until checkbox is checked
        layout.addWidget(self.graph_input)

        # Submit and Cancel Buttons
        button_layout = QHBoxLayout()

        submit_button = QPushButton("Submit")
        submit_button.setFont(self.get_font(FontStyle.BOLD, 12))
        submit_button.setStyleSheet(
            f"background-color: {AppConfig.BUTTON_BG_COLOR}; color: {AppConfig.BUTTON_TEXT_COLOR}; padding: 8px; border-radius: 5px;"
        )
        submit_button.clicked.connect(self.process_backend)
        button_layout.addWidget(submit_button)

        cancel_button = QPushButton("Cancel")
        cancel_button.setFont(self.get_font(FontStyle.BOLD, 12))
        cancel_button.setStyleSheet(
            f"background-color: #d9534f; color: white; padding: 8px; border-radius: 5px;"
        )
        cancel_button.clicked.connect(self.close)
        button_layout.addWidget(cancel_button)

        layout.addLayout(button_layout)

        layout.addStretch()

    def toggle_custom_gain_input(self, index):
        """Show or hide custom gain input based on dropdown selection."""
        if self.gain_dropdown.currentText() == "Custom Gain":
            self.custom_gain_input.setVisible(True)
        else:
            self.custom_gain_input.setVisible(False)

    def toggle_gain_input(self, selected_option):
        """Toggle visibility of user-defined gain input."""
        self.user_defined_gain_input.setVisible(selected_option == "User-Defined")

    # Method to toggle graph input visibility
    def toggle_graphs_input(self, state):
        """Toggle visibility of graph input based on checkbox state."""
        self.graph_input.setVisible(state == Qt.Checked)

    def get_font(self, style, size):
        """Utility to get a QFont object based on FontStyle and size."""
        font = QFont(AppConfig.FONT_FAMILY, size)
        if style == FontStyle.BOLD:
            font.setBold(True)
        return font

    def select_directory(self):
        """Function to select a directory and display its subfolders in the dropdown."""
        try:
            selected_dir = QFileDialog.getExistingDirectory(self, Messages.SELECT_DIR_PROMPT)
            if selected_dir:
                self.logger.info(Messages.LOG_DIR_SELECTED.format(FileType.DIRECTORY.value, selected_dir))
                self.directory_dropdown.clear()  # Clear existing items
                self.directory_dropdown.addItem(selected_dir)  # Add the selected directory itself
                subfolders = [
                    f.name for f in os.scandir(selected_dir) if f.is_dir()
                ]  # List all subfolders
                if subfolders:
                    self.directory_dropdown.addItems(subfolders)
                else:
                    self.directory_dropdown.addItem(Messages.NO_DIR_SELECTED)
                self.directory_dropdown.setCurrentText(selected_dir)
            else:
                self.logger.info(Messages.LOG_NO_DIR_SELECTED)
                self.directory_dropdown.setCurrentText(AppConfig.DIR_DROPDOWN_DEFAULT)
        except Exception as e:
            self.logger.error(Messages.LOG_ERROR.format(e))
            self.directory_dropdown.clear()
            self.directory_dropdown.addItem(Messages.ERROR)

    def show_status_boxes(self, sections):
        """Show red-to-green status boxes based on backend processing."""
        self.clear_status_boxes()  # Clear any existing boxes

        # Layout for status boxes
        self.status_box_layout = QHBoxLayout()
        for i in range(sections-1):
            box = QLabel()
            box.setFixedSize(30, 30)  # Box size
            box.setStyleSheet("background-color: red; border: 1px solid black;")
            self.status_box_layout.addWidget(box)

            # Simulate backend delay and update status
            self.update_status_box(box, i)

        self.centralWidget().layout().addLayout(self.status_box_layout)

    def update_status_box(self, box, index):
        """Simulate backend processing and update the status of a box."""
        QTimer.singleShot(500 * (index + 1), lambda: box.setStyleSheet("background-color: green; border: 1px solid black;"))

    def clear_status_boxes(self):
        """Remove existing status boxes from the layout."""
        if hasattr(self, "status_box_layout"):
            for i in reversed(range(self.status_box_layout.count())):
                widget = self.status_box_layout.itemAt(i).widget()
                if widget:
                    widget.deleteLater()

    def process_backend(self):
        """Dummy backend processing logic."""
        # Collect input values
        selected_directory = self.directory_dropdown.currentText()
        start_marker = self.start_marker_input.value()
        end_marker = self.end_marker_input.value()
        computation_method = self.computation_method_dropdown.currentText()
        enable_graphs = self.enable_graphs_checkbox.isChecked()
        graph_value = self.graph_input.value() if enable_graphs else None
        gain_option = self.gain_option_dropdown.currentText()

        # Log the collected inputs
        self.logger.info("Processing backend with the following inputs:")
        self.logger.info(f"Selected Directory: {selected_directory}")
        self.logger.info(f"Start Marker: {start_marker}, End Marker: {end_marker}")
        self.logger.info(f"Computation Method: {computation_method}")
        self.logger.info(f"Enable Graphs: {enable_graphs}, Graph Value: {graph_value}")
        self.logger.info(f"Gain Option: {gain_option}")

        # Simulate backend processing
        sections = end_marker - start_marker + 1
        if sections <= 0:
            self.logger.error("Invalid marker range. End Marker must be greater than or equal to Start Marker.")
            return

        self.logger.info(f"Number of Sections to Process: {sections}")
        self.show_status_boxes(sections)  # Simulate showing red-to-green status boxes

def main():
    app = QApplication([])
    window = MainWindow()
    window.show()
    app.exec_()

if __name__ == "__main__":
    main()
