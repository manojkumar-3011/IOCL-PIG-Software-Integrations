# B-Scan Viewer with Defect Marking algorithm

## Overview

The present Python application provides a Graphical User Interface (GUI) for visualizing and analyzing Magnetic Flux Leakage (MFL) pipeline inspection data. It supports interactive B-scan viewing, sensor masking, colormap switching, page navigation, signal plotting, and defect marking using an appropriate algorithm.

---

## Available features in the present GUI

- **File Selection:** Choose a folder followed by the binary file containing MFL data.
- **B-Scan Visualization:** View primary and secondary sensor data as heatmaps.
- **Sensor Masking:** Mask specific sensors by entering their indices.
- **Colormap Toggle:** Switch between different colormaps for better visualization.
- **Page Navigation:** Jump to, go to previous, or next data page.
- **Signal Plotting:** Plot raw signals for selected primary or secondary sensors.
- **Fault Profile Table:** Calculate and display peak-to-peak and peak difference for each sensor in a selected range.
- **Defect Marking algorithm:** Run the CLIQUE algorithm to automatically detect and label dense defect regions.This is a  contribution made by the technical team from TIH IITB to the existing stack provided by IOCL in order to enable defect marking and facilitate better visibility of the metal loss defects with naked eyes.The enhanced visual opens up as a seperate pop up window(.jpeg/.png). 
- **Interactive Cursor Info:** Hover over the heatmap to see sensor/sample info and peak-to-peak values.
- **View Controls:** Show both, only primary, or only secondary sensor data.

---

## Usage

1. **Create a virtual environment using `environment.yml`:**

   - **For all platforms (Windows, Linux, Mac):**
     ```bash
     conda env create -f environment.yml
     conda activate iocl
     ```

2. **Run the Script:**

   - **On Windows:**
     ```bat
     python 24inch_code.py
     ```

   - **On Linux or Mac:**
     ```bash
     python 24inch_code.py
     ```

3. **Follow the GUI prompts:**
   - Select the folder containing your binary MFL data files.
   - Use the GUI controls for navigation, visualization, masking, plotting, and defect marking as described above.
   - Use the 'Run Defect Marking' and a new pop up window comprising the marked defects appears shown below:
   [Improved GUI with Defect marking algorithm](gui_tab.png)

---

**Note:**  
- If you encounter issues with `tkinter` on Linux, you may need to install it separately:
  ```bash
  sudo apt-get install python3-tk