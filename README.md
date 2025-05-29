# TIH
# IOCL-PIG software


## Overview
The `24inch_codev2.py` script is a Python-based GUI application designed for visualizing and analyzing binary sensor data. It provides tools for displaying sensor readings, fault profiles, and 2D plots of sensor data over a specified range. The application is built using **Tkinter** for the GUI and **Matplotlib** for data visualization.

---

## Features
1. **B-Scan Visualization**:
   - Displays primary and secondary sensor data as heatmaps.
   - Supports multiple colormaps for better visualization.

2. **Fault Profile Analysis**:
   - Calculates and displays fault profiles for sensors over a specified range.
   - Provides metrics like peak-to-peak amplitude and peak differences.

3. **2D Sensor Data Plotting**:
   - Plots magnitude vs. distance/time for individual sensors.
   - Allows users to specify the sensor and range of samples.

4. **Page Navigation**:
   - Navigate through pages of sensor data.
   - Jump to a specific page using the GUI.

5. **Interactive GUI**:
   - User-friendly interface for selecting files, masking sensors, and visualizing data.
   - Platform-specific window maximization for better usability.

---

## Requirements
### **Create an environment file under the name, `environment.yml`** which contains the packages essential for compiling and executing the code
To set up the required environment, follow these steps:

1. **Install Conda**:
   - If you don’t have Conda installed, download and install it from [Miniconda](https://docs.conda.io/en/latest/miniconda.html) or [Anaconda](https://www.anaconda.com/).

2. **Create the Environment**:
   - Run the following command to create the environment using the `environment.yml` file:
     ```bash
     conda env create -f environment.yml
     ```

3. **Activate the Environment**:
   - Activate the newly created environment:
     ```bash
     conda activate iocl
     ```

4. **Run the Script**:
   - Once the environment is activated, run the script(Replace with the folder path as applicable in the respective user's case):
     ```bash
     /usr/bin/python3 "/home/abhinandan074/Downloads/IOCL-- PIG Software-20250520T084230Z-1-001/IOCL-- PIG Software/24inch_Withcode/24inch_codev2.py"
     ```

### **Contents of `environment.yml`**
Below is the content of the `environment.yml` file used to set up the environment:

name: iocl
channels:
  - conda-forge
  - defaults
  - scipy
dependencies:
  - python=3.10
  - numpy
  - matplotlib
  - tk
  - platform
  - scipy
  - opencv
  - ctypes

  - python=3.10
  - numpy
  - matplotlib
  - tk
