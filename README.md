# Pipeline Trajectory Estimation Tool (EKTOpt) - Software Manual

## Overview
EKTOpt is a software tool for pipeline trajectory estimation developed at the Centre of Excellence in Oil, Gas, and Energy, IIT Bombay, in collaboration with Indian Oil Corporation Ltd. It provides an intuitive interface for configuring computation parameters and efficiently processing trajectory data.

## Features
* **User-friendly GUI** with dropdown selections and input fields.
* **Multiple computation methods** including Joint, Sequential, and Multi.
* **Customizable processing options** like marker indices, odometer initial gains, checkpoint steps, and accuracy modes, with parallel processing capabilities.
* **Graph plotting and administrative inputs** You can enable the Graphing of MATLAB and set the frequency. Admin inputs are currently not required.
* **Results tracking and logging** for processed pipeline trajectories with their current status and time.

## Installation
### Prerequisites
* Windows operating system preferably Windows 11, 64 bit.
* Display with 1920 x 1080 resolution or higher is MUST.
* Optional Python (if running the source code from Github) with dependencies (found in requirements.txt): `PyQt5`, `matplotlib`, `pandas`, etc.
* MATLAB required (used for backend processing). Extensively tested on below MATLAB configuration.
   
   **MATLAB Configuration Summary**

   **MATLAB Version**: 9.11.0.1873467 (R2021b) Update 3  
   **License Number**: 40677001  
   **Operating System**: Microsoft Windows 11 Pro Version 10.0 (Build 22631)  
   **Java Version**: Java 1.8.0_202-b08 (Oracle Corporation Java HotSpot™ 64-Bit Server VM, mixed mode)

   ---

   **Installed Toolboxes and Versions**

   | Toolbox                                           | Version     | Release   |
   |--------------------------------------------------|-------------|-----------|
   | MATLAB                                            | 9.11        | R2021b    |
   | Simulink                                          | 10.4        | R2021b    |
   | Aerospace Toolbox                                 | 4.1         | R2021b    |
   | Automated Driving Toolbox                         | 3.4         | R2021b    |
   | Computer Vision Toolbox                           | 10.1        | R2021b    |
   | Control System Toolbox                            | 10.11       | R2021b    |
   | Curve Fitting Toolbox                             | 3.6         | R2021b    |
   | DSP System Toolbox                                | 9.13        | R2021b    |
   | Deep Learning Toolbox                             | 14.3        | R2021b    |
   | Fuzzy Logic Toolbox                               | 2.8.2       | R2021b    |
   | Image Acquisition Toolbox                         | 6.5         | R2021b    |
   | Image Processing Toolbox                          | 11.4        | R2021b    |
   | Instrument Control Toolbox                        | 4.5         | R2021b    |
   | MATLAB Coder                                      | 5.3         | R2021b    |
   | MATLAB Compiler                                   | 8.3         | R2021b    |
   | MATLAB Compiler SDK                               | 6.11        | R2021b    |
   | MATLAB Report Generator                           | 5.11        | R2021b    |
   | Model Predictive Control Toolbox                  | 7.2         | R2021b    |
   | Optimization Toolbox                              | 9.2         | R2021b    |
   | Parallel Computing Toolbox                        | 7.5         | R2021b    |
   | Partial Differential Equation Toolbox             | 3.7         | R2021b    |
   | Phased Array System Toolbox                       | 4.6         | R2021b    |
   | ROS Toolbox                                       | 1.4         | R2021b    |
   | Reinforcement Learning Toolbox                    | 2.1         | R2021b    |
   | Robotics System Toolbox                           | 3.4         | R2021b    |
   | Robust Control Toolbox                            | 6.11        | R2021b    |
   | Sensor Fusion and Tracking Toolbox                | 2.2         | R2021b    |
   | Signal Processing Toolbox                         | 8.7         | R2021b    |
   | Simscape                                          | 5.2         | R2021b    |
   | Simscape Multibody                                | 7.4         | R2021b    |
   | Simulink 3D Animation                             | 9.3         | R2021b    |
   | Simulink Check                                    | 5.2         | R2021b    |
   | Simulink Code Inspector                           | 4.0         | R2021b    |
   | Simulink Coder                                    | 9.6         | R2021b    |
   | Simulink Compiler                                 | 1.3         | R2021b    |
   | Simulink Control Design                           | 6.0         | R2021b    |
   | Simulink Design Optimization                      | 3.10        | R2021b    |
   | Simulink Desktop Real-Time                        | 5.13        | R2021b    |
   | Simulink Real-Time                                | 7.2         | R2021b    |
   | Statistics and Machine Learning Toolbox           | 12.2        | R2021b    |
   | Symbolic Math Toolbox                             | 9.0         | R2021b    |
   | UAV Toolbox                                       | 1.2         | R2021b    |
   | Vehicle Network Toolbox                           | —           | R2021b    |

### Steps
1. Download the latest setup/release of EKTOpt from [GitHub](https://github.com/sidgirase/pipeline-estimation).
2. Extract the files or install them in the preferred directory. Then navigate to the installation directory.
3. Run `EKTOpt.exe` (for Windows) or execute the Python script `app.py`.

## Usage

### Launching the Application 

1. Open the **EKTOpt** application.  
2. Select the **Patch Directory** by clicking the `Browse` button and choosing the required folder. Then click `Patch-It !` button to apply changes.
   - The patch folder MUST contain a `patch.m` which holds the logic to update the files and OPTIONALLY a `logic.m` file that specifies custom logic for each run.
   - Make sure to select the parent folder which contains `patch.m` file.
   - If you have received a patch folder without `patch.m` please contact the developers who sent you the patch.  
   - The last patched folder will appear in your installation directory under the `PATCH` folder.
   - This `PATCH` folder will be patched every time you reopen the application. So you do not need to re-patch the update
   - If you do not need the existing patch anymore, just empty the contents of the `PATCH` folder.
3. To convert and add CSV files to the MAT input database for later use:  
   - Enter a unique directory name in the provided input field (this is the name that will be used to save the inputs in the Database) 
   - Click the `Process CSV?` button to proceed. This will start a MATLAB process to convert all your files. Please follow the instructions.
   - You need to follow the usual process to select the input CSV files folder and the Reference data file in `.xlsx` format and wait for the process to complete.
   - On successful completion your files will be converted and can be found with the unique directory name provided in the `MAT INPUT DB` folder.
4. Select the **MAT Input Directory** by clicking the `Browse MAT Files` button and choosing the required input folder.
5. Configure the pipeline estimation parameters as needed based on reference data.  

### Input Files Format

1. **Patch Folder** must contain:
   - `patch.m` file
   - Optional `logic.m` file

2. **CSV IMU Data Folder**:
   - Contains multiple `.csv` input files with the following header format in the first row:
     ```
     WX, WY, WZ, AX, AY, AZ, Oddo1, Oddo2, Oddo3
     ```

3. **XLSX Markers File**:
   - A `.xlsx` input file with the following header and data format:

     **Header:**
     ```
     name, lon, lat, hgt, odo1, odo2, odo3, odosum, Ref No.
     ```

     **Example Row:**
     ```
     ST, 86.0503503, 25.433255, 10, 0, 24, 21, 45, M0
     MM-1, 86.04888095, 25.43248079, 10, 0, 748, 1105, 1853, M1
     ```

### Configuration Options
#### Input Parameters
* **Start Marker Index:** Set the starting point for trajectory computation.
* **Checkpoints Steps:** Define the interval for checkpoints. For example, if set to 2. We consider 3 markers for processing at a time starting from the start marker and ending at the end marker. This only works if the computation method is set to Joint.
* **End Marker Index:** Specify the endpoint for processing.

#### Computation Method
Select from:
* **Joint**: 
	1. In this method, you have 2 options for considering more than 2 successive markers at a time for processing. 
	2. You can do this by setting an appropriate Checkpoint Step or you may manually define the checkpoints in comma-separated format in the additional text box input field.
	3. For example:
		a. Checkpoint Steps = 2, and Start = 1, End = 6. Then you can get the final computation sections 1-3, 3-5, and 5-6.
		b. The same result can be obtained by providing a comma-separated input in the text-box in this fashion 1,3,5,6.
	4. You can use multi-threading for each generated section.
* **Sequential**: Only one pipeline section of two successive markers is selected for processing at once. There is no multi-threading.
* **Multi**: Same as Sequential but you can run up to 10 sections/threads for processing simultaneously.

#### Other Settings
* **Threads:** Define the number of threads/sections (default: `1`) for simultaneous processing (only using Joint/Multi).
* **Odo Gain:** 
	1. Adjust the initial odometer gain guess (float value). 
	2. There are 2 inbuilt odometer gains available  (`e.g., 16km`) for known pipelines. 
	3. You can even provide separate/different individual gains for each section in a comma-separated fashion by selecting the Manual Odo Gain option for newer pipelines. If only a single value is provided then the same value is considered throughout all the pipeline sections.
* **Accuracy Mode:** Choose accuracy levels (`Quick`, etc.).
* **Enable Plots:** Optionally visualize results.
* **Admin Inputs:** Enable advanced administrative configurations using JSON format (has no effect currently).

### Running the Computation
1. Click **Submit** to start the processing.
2. Click **Reset** to clear the current configuration.
3. Click **Exit** to close the application.
   
   **Please note these caveats of using Exit before processing all the sections:**
   - It will only kill any future MATLAB threads/sections to be processed.
   - It will not close the MATLAB threads that are currently in progress.
   - So the user needs to manually close all the current MATLAB windows if they want to stop all the threads.
   - If you use too many threads and your device starts hanging, then consider terminating any EKTOpt, Python, or MATLAB threads directly from the task manager. Restart the application with fresh inputs and lower threads.

### Viewing Results
Processed results are displayed in a table under **Results**, which includes:
* Status
* Start Marker
* End Marker
* Method Used
* Result Folder 
	1. with respect to the installation directory **MATLAB\CSV_OUTPUT\\** or **MATLAB\OUTPUT\\**
	2. formatted in the following fashion as per the current date and time **results_YYMMDD-HHmm_[start_marker_idx end_marker_idx]** 
	(`e.g., MATLAB\CSV_OUTPUT\results_250121-1426_[2 4]`)
* Processing Time in seconds.

## Development & Contributions
Developed by Dr. Somnath Buriuly & Siddhesh Girase.
For contributions:
1. Fork the repository.
2. Submit a pull request with changes.

## Contact & Support
For queries, contact: [pic.coeoge@iitb.ac.in](mailto:pic.coeoge@iitb.ac.in)

---
## For Developers
To Create the Pyinstaller Dist in a terminal:
1. change current directory to the app folder
   ```
   cd app/
   ```
2. then run the following command:
   ```
   pyinstaller --name EKTOpt --onefile --windowed --icon=icon/ektopt_black.ico --add-data "MATLAB_EXEC;MATLAB" .\app.py
   ```

Then to create a setup:
1. Download INNO setup
2. Watch the final part of this [YT Video](https://www.youtube.com/watch?v=p3tSLatmGvU)
