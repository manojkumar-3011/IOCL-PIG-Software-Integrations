import sys
from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QLineEdit, QComboBox, QRadioButton, QCheckBox, QPushButton, QVBoxLayout, QHBoxLayout, QButtonGroup, QMessageBox

class EstimationConfigUI(QWidget):
    def __init__(self):
        super().__init__()

        self.initUI()

    def initUI(self):
        # Title and Main Layout
        self.setWindowTitle("Estimation Pipeline Configuration")
        layout = QVBoxLayout()

        # Marker IDs for Estimation
        layout.addWidget(QLabel("Marker IDs for Estimation"))
        self.marker_ids = QLineEdit()
        self.marker_ids.setToolTip("Enter the IDs of markers to include, separated by commas.")
        layout.addWidget(self.marker_ids)

        # Admin Marker IDs for Estimation
        layout.addWidget(QLabel("[Admin] Marker IDs for Estimation"))
        self.admin_marker_ids = QLineEdit()
        self.admin_marker_ids.setToolTip("Admin-only: Enter additional marker IDs if needed.")
        layout.addWidget(self.admin_marker_ids)

        # Pipeline Gain
        layout.addWidget(QLabel("Pipeline Gain"))
        self.pipeline_gain = QComboBox()
        self.pipeline_gain.addItems(["Low", "Medium", "High"])
        self.pipeline_gain.setToolTip("Choose the gain setting for the estimation pipeline.")
        layout.addWidget(self.pipeline_gain)

        # Execution Mode
        layout.addWidget(QLabel("Execution Mode"))
        self.quick_mode = QRadioButton("Quick Mode")
        self.detailed_mode = QRadioButton("Detailed Mode")
        self.quick_mode.setChecked(True)
        self.mode_group = QButtonGroup()
        self.mode_group.addButton(self.quick_mode)
        self.mode_group.addButton(self.detailed_mode)
        layout.addWidget(self.quick_mode)
        layout.addWidget(self.detailed_mode)

        # Output Folder Reset Option
        self.output_reset = QCheckBox("Do not reset output folders")
        self.output_reset.setChecked(True)
        self.output_reset.setToolTip("Check to preserve existing output folders; leave unchecked to reset.")
        layout.addWidget(self.output_reset)

        # Buttons
        button_layout = QHBoxLayout()
        self.submit_btn = QPushButton("Submit")
        self.submit_btn.clicked.connect(self.submit_action)
        button_layout.addWidget(self.submit_btn)
        
        self.reset_btn = QPushButton("Reset")
        self.reset_btn.clicked.connect(self.reset_action)
        button_layout.addWidget(self.reset_btn)
        
        self.exit_btn = QPushButton("Exit")
        self.exit_btn.clicked.connect(self.close)
        button_layout.addWidget(self.exit_btn)

        layout.addLayout(button_layout)
        self.setLayout(layout)

    def submit_action(self):
        # Capture all user inputs for backend processing
        marker_ids = self.marker_ids.text()
        admin_marker_ids = self.admin_marker_ids.text()
        pipeline_gain = self.pipeline_gain.currentText()
        mode = "Quick Mode" if self.quick_mode.isChecked() else "Detailed Mode"
        output_reset = not self.output_reset.isChecked()
        
        # Here, pass values to your backend (e.g., MATLAB processing)
        QMessageBox.information(self, "Submitted", "Configuration submitted successfully!")

    def reset_action(self):
        # Clear all fields and reset to defaults
        self.marker_ids.clear()
        self.admin_marker_ids.clear()
        self.pipeline_gain.setCurrentIndex(0)
        self.quick_mode.setChecked(True)
        self.output_reset.setChecked(True)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = EstimationConfigUI()
    window.show()
    sys.exit(app.exec_())
