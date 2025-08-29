import sys
import os
from PyQt5.QtWidgets import (
    QApplication, QWidget, QLabel, QLineEdit, QComboBox, QRadioButton, 
    QCheckBox, QPushButton, QVBoxLayout, QHBoxLayout, QButtonGroup, 
    QGroupBox, QMessageBox, QFrame
)
from PyQt5.QtGui import QFont, QPixmap
from PyQt5.QtCore import Qt

class EstimationConfigUI(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

    def initUI(self):
        # Set up the main window
        self.setWindowTitle("Pipeline Estimation Tool")
        self.setGeometry(100, 100, 600, 500)
        self.setStyleSheet("background-color: #F3F3F3;")  # Light background color

        # Main layout
        main_layout = QVBoxLayout()

        # Top Layout with Logo and Title
        top_layout = QHBoxLayout()

        # Brand Logo
        logo_label = QLabel()
        # Get the current directory (adjust the path to your use case)
        current_dir = os.path.dirname(os.path.abspath(__file__))
        image_path = os.path.join(current_dir, "img", "iitb_logo.png")
        logo_pixmap = QPixmap(image_path)  # Set path to your logo
        # Check if the pixmap is valid
        if logo_pixmap.isNull():
            print(f"Failed to load image: {image_path}")
        else:
            print("Image loaded successfully!")
        logo_pixmap = logo_pixmap.scaled(80, 80, Qt.KeepAspectRatio, Qt.SmoothTransformation)
        logo_label.setPixmap(logo_pixmap)
        logo_label.setAlignment(Qt.AlignLeft | Qt.AlignTop)
        top_layout.addWidget(logo_label)

        # IIT Bombay Branding Text Beside Logo
        branding_top_label = QLabel("भारतीय प्रौद्योगिकी संस्थान मुंबई\nIndian Institute of Technology Bombay")
        branding_top_label.setFont(QFont("Arial", 10, QFont.Bold))
        branding_top_label.setStyleSheet("color: #333333;")
        branding_top_label.setAlignment(Qt.AlignLeft | Qt.AlignVCenter)
        top_layout.addWidget(branding_top_label)

        # Title
        title_label = QLabel("Pipeline Estimation Tool")
        title_label.setFont(QFont("Arial", 16, QFont.Bold))
        title_label.setStyleSheet("color: #333333;")  # Dark text color
        title_label.setAlignment(Qt.AlignCenter)
        top_layout.addWidget(title_label)
        top_layout.addStretch(1)
        
        main_layout.addLayout(top_layout)

        # Description
        description_label = QLabel("Configure parameters for marker estimation and pipeline processing.")
        description_label.setAlignment(Qt.AlignCenter)
        description_label.setStyleSheet("color: #666666; font-size: 12px;")
        main_layout.addWidget(description_label)

        # Markers Section
        markers_group = QGroupBox("Markers Configuration")
        markers_group.setStyleSheet("QGroupBox { font-weight: bold; color: #4B4B4B; }")
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
        pipeline_group.setStyleSheet("QGroupBox { font-weight: bold; color: #4B4B4B; }")
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
        mode_group.setStyleSheet("QGroupBox { font-weight: bold; color: #4B4B4B; }")
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
        self.submit_btn.setStyleSheet("background-color: #007BFF; color: white; font-weight: bold;")
        self.submit_btn.clicked.connect(self.submit_action)
        button_layout.addWidget(self.submit_btn)

        self.reset_btn = QPushButton("Reset")
        self.reset_btn.setStyleSheet("background-color: #6C757D; color: white;")
        self.reset_btn.clicked.connect(self.reset_action)
        button_layout.addWidget(self.reset_btn)
        
        self.exit_btn = QPushButton("Exit")
        self.exit_btn.setStyleSheet("background-color: #DC3545; color: white;")
        self.exit_btn.clicked.connect(self.close)
        button_layout.addWidget(self.exit_btn)

        main_layout.addLayout(button_layout)

        # Footer Branding Text
        branding_label = QLabel("भारतीय प्रौद्योगिकी संस्थान मुंबई | Indian Institute of Technology Bombay\nPowered by YourCompanyName")
        branding_label.setAlignment(Qt.AlignCenter)
        branding_label.setStyleSheet("color: #4B4B4B; font-size: 10px; margin-top: 10px;")
        main_layout.addWidget(branding_label)

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
