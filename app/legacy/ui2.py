import sys
from PyQt5.QtWidgets import (
    QApplication, QWidget, QLabel, QLineEdit, QComboBox, QRadioButton, 
    QCheckBox, QPushButton, QVBoxLayout, QHBoxLayout, QButtonGroup, 
    QGroupBox, QMessageBox, QFrame
)
from PyQt5.QtGui import QFont, QColor
from PyQt5.QtCore import Qt

class EstimationConfigUI(QWidget):
    def __init__(self):
        super().__init__()

        self.initUI()

    def initUI(self):
        # Set up the main window
        self.setWindowTitle("Estimation Pipeline Configuration")
        self.setGeometry(100, 100, 500, 400)

        # Main layout
        main_layout = QVBoxLayout()

        # Title
        title_label = QLabel("Estimation Pipeline Configuration")
        title_label.setFont(QFont("Arial", 14, QFont.Bold))
        title_label.setAlignment(Qt.AlignCenter)
        main_layout.addWidget(title_label)

        # Description
        description_label = QLabel("Configure parameters for marker estimation and pipeline processing.")
        description_label.setAlignment(Qt.AlignCenter)
        main_layout.addWidget(description_label)

        # Markers Section
        markers_group = QGroupBox("Markers Configuration")
        markers_layout = QVBoxLayout()
        
        markers_layout.addWidget(QLabel("Marker IDs for Estimation"))
        self.marker_ids = QLineEdit()
        self.marker_ids.setPlaceholderText("Enter marker IDs, separated by commas")
        markers_layout.addWidget(self.marker_ids)

        markers_layout.addWidget(QLabel("[Admin] Marker IDs for Estimation"))
        self.admin_marker_ids = QLineEdit()
        self.admin_marker_ids.setPlaceholderText("Admin marker IDs (optional)")
        markers_layout.addWidget(self.admin_marker_ids)

        markers_group.setLayout(markers_layout)
        main_layout.addWidget(markers_group)

        # Separator
        separator1 = QFrame()
        separator1.setFrameShape(QFrame.HLine)
        separator1.setFrameShadow(QFrame.Sunken)
        main_layout.addWidget(separator1)

        # Pipeline Settings Section
        pipeline_group = QGroupBox("Pipeline Settings")
        pipeline_layout = QVBoxLayout()
        
        pipeline_layout.addWidget(QLabel("Pipeline Gain"))
        self.pipeline_gain = QComboBox()
        self.pipeline_gain.addItems(["Low", "Medium", "High"])
        self.pipeline_gain.setToolTip("Choose the gain setting for the pipeline")
        pipeline_layout.addWidget(self.pipeline_gain)

        pipeline_group.setLayout(pipeline_layout)
        main_layout.addWidget(pipeline_group)

        # Separator
        separator2 = QFrame()
        separator2.setFrameShape(QFrame.HLine)
        separator2.setFrameShadow(QFrame.Sunken)
        main_layout.addWidget(separator2)

        # Execution Mode Section
        mode_group = QGroupBox("Execution Mode")
        mode_layout = QHBoxLayout()

        self.quick_mode = QRadioButton("Quick Mode")
        self.detailed_mode = QRadioButton("Detailed Mode")
        self.quick_mode.setChecked(True)
        
        mode_layout.addWidget(self.quick_mode)
        mode_layout.addWidget(self.detailed_mode)
        
        mode_group.setLayout(mode_layout)
        main_layout.addWidget(mode_group)

        # Output Folder Option
        self.output_reset = QCheckBox("Do not reset output folders (default RESET)")
        self.output_reset.setChecked(True)
        main_layout.addWidget(self.output_reset)

        # Separator
        separator3 = QFrame()
        separator3.setFrameShape(QFrame.HLine)
        separator3.setFrameShadow(QFrame.Sunken)
        main_layout.addWidget(separator3)

        # Buttons Section
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

        main_layout.addLayout(button_layout)
        self.setLayout(main_layout)

    def submit_action(self):
        # Capture inputs (placeholder function)
        marker_ids = self.marker_ids.text()
        admin_marker_ids = self.admin_marker_ids.text()
        pipeline_gain = self.pipeline_gain.currentText()
        mode = "Quick Mode" if self.quick_mode.isChecked() else "Detailed Mode"
        output_reset = not self.output_reset.isChecked()

        QMessageBox.information(self, "Submission", "Configuration submitted successfully!")

    def reset_action(self):
        # Reset to default values
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
