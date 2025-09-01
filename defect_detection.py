import os
import sys
import json
import csv
import pandas as pd
import numpy as np
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from config import *

try:
    from ctypes import windll
    windll.shcore.SetProcessDpiAwareness(1)
except:
    pass




json_arg = sys.argv[1]

# Convert it back to a list
received_paths = json.loads(json_arg)


# Initialize lists to store specific rows

root = tk.Tk()
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
canvas = FigureCanvasTkAgg(fig, master=root)
colormaps = ['gray', 'jet', 'viridis', 'plasma']
current_cmap_index = 0

def create_main_window():

    fig.subplots_adjust(hspace=0.4)

    canvas.draw()

    canvas_widget = canvas.get_tk_widget()
    canvas_widget.config(height=350)  # reduce height of canvas widget
    canvas_widget.pack(fill=tk.BOTH, expand=1)

    root.title("B-Scan Viewer")

    label = ttk.Label(root, text="Welcome to B-Scan Viewer")
    label.pack(padx=10, pady=10)

    return root


def folder_selection():
    global file_dir
    file_dir = filedialog.askdirectory(title="Select Folder")
    if not file_dir:
        messagebox.showerror("Folder Error", "No folder selected.")

def matchOdoWithLocation(val):
    print("plotindex:",val)
    print(odo2dnumpyarray[page_no][val],lat2dnumpyarray[page_no][val],lon2dnumpyarray[page_no][val],height2dnumpyarray[page_no][val])
    return lat2dnumpyarray[page_no][val], lon2dnumpyarray[page_no][val],height2dnumpyarray[page_no][val]

def GetLocationValues(PlotIndex):

    global odo2dnumpyarray, lat2dnumpyarray, lon2dnumpyarray, height2dnumpyarray, csvfileisnotread

    if csvfileisnotread == True:

        # List of CSV files
        
        for path in received_paths:
            print(path)
            print("print1")
        
        raw_filepaths = [path.replace("\\", "\\\\") for path in received_paths]

        for path in raw_filepaths:
            print(path)
            print("print2")

        # 1D lists to store all values from all files
        odo1_rows = []
        lat_rows = []
        lon_rows = []
        height_rows = []

        # Read each file and collect data
        for path in raw_filepaths:
            df = pd.read_csv(path)

            if "odo" in df.columns:
                odo1_rows.extend(df["odo"].dropna().tolist())
            if "Lat" in df.columns:
                lat_rows.extend(df["Lat"].dropna().tolist())
            if "lon" in df.columns:
                lon_rows.extend(df["lon"].dropna().tolist())
            if "height" in df.columns:
                # Assuming you want to append height values to lon_rows
                height_rows.extend(df["height"].dropna().tolist())

        # Dimensions for 2D arrays
        pagelen = 179
        plotlen = 4999

        # Initialize empty 2D arrays
        two_d_odoarr = [[0 for _ in range(plotlen)] for _ in range(pagelen)]
        two_d_latarr = [[0 for _ in range(plotlen)] for _ in range(pagelen)]
        two_d_lonarr = [[0 for _ in range(plotlen)] for _ in range(pagelen)]
        two_d_heightarr = [[0 for _ in range(plotlen)] for _ in range(pagelen)]

        # Fill 2D arrays safely from 1D lists
        val = 0
        for i in range(pagelen):
            for j in range(plotlen):
                if val < len(odo1_rows):
                    two_d_odoarr[i][j] = odo1_rows[val]
                    two_d_latarr[i][j] = lat_rows[val]
                    two_d_lonarr[i][j] = lon_rows[val]
                    two_d_heightarr[i][j] = lon_rows[val]
                    val += 1
                else:
                    break

        # Convert to NumPy arrays
        odo2dnumpyarray = np.array(two_d_odoarr)
        lat2dnumpyarray = np.array(two_d_latarr)
        lon2dnumpyarray = np.array(two_d_lonarr)
        height2dnumpyarray = np.array(two_d_heightarr)

        csvfileisnotread = False


    # Call your function for matching ODO with location
    lat, lon, height = matchOdoWithLocation(PlotIndex)

    return lat, lon , height 

          

def select_new_file():
    global file_path1, page_no
    folder_selection()
    page_no = 0
    selected = filedialog.askopenfilename(
        initialdir=file_dir,
        title="Select Binary File",
        filetypes=[("Binary Files", "*.bin"), ("All Files", "*.*")]
    )
    if selected:
        file_path1 = selected
        update_image()

def toggle_colormap():
    global current_cmap_index
    current_cmap_index = (current_cmap_index + 1) % len(colormaps)
    update_image()

def folder_test():
    result_paths = []

    # Fix escape characters by replacing \ with \\
    result_paths = [path.replace("\\", "\\\\") for path in received_paths]

    # for path in corrected_paths:
    #     print(path)

    for i in result_paths:
        print("File path:", i)    

def update_image():
    global rawdata_pri3,rawdata_sec3
    if not file_path1 or not os.path.exists(file_path1):
        messagebox.showerror("File Error", "No file selected or file does not exist.")
        return

    byte_offset = (page_no * samps + offset) * T * 2
    with open(file_path1, 'rb') as fid:
        fid.seek(byte_offset, 0)
        a = np.fromfile(fid, dtype=np.uint16, count=T * samps)

    if len(a) < T * samps:
        messagebox.showerror("File Error", "Not enough data to display this page.")
        return

    buff = a.reshape((samps, T)).T

    rawdata_prif = buff[:primary_sen, :] * 4.09618 * 320 / 65535
    rawdata_secf = buff[primary_sen:primary_sen+secondary_sen, :] * 4.09618 * 320 / 65535

    avg_sec = np.mean(rawdata_secf, axis=1)
    avg_pri = np.mean(rawdata_prif, axis=1)
    rawdata_pri3 = rawdata_prif - avg_pri[:, np.newaxis]
    rawdata_sec3 = rawdata_secf - avg_sec[:, np.newaxis]

    for sensor in masked_sensors:
        if 0 <= sensor < rawdata_prif.shape[0]:
            mean_val = np.mean(rawdata_prif[sensor, :])
            rawdata_pri3[sensor, :] = mean_val - avg_pri[sensor]

    ax1.clear()
    ax2.clear()

    cmap = colormaps[current_cmap_index]
    ax1.imshow(rawdata_pri3, cmap=cmap, aspect='auto')
    ax1.set_title(f'Primary Sensors - cd: {cd} & page no: {page_no}')
    ax1.format_coord = format_coord

    ax2.imshow(rawdata_sec3, cmap=cmap, aspect='auto')
    ax2.set_title(f'Secondary Sensors - cd: {cd} & page no: {page_no}')
    ax2.format_coord = format_coord_sec

    canvas.draw_idle()

def mask_sensors():
    try:
        sensors = list(map(int, sensor_mask_entry.get().split(',')))
        masked_sensors.update(sensors)
        update_image()
    except ValueError:
        messagebox.showerror("Input Error", "Enter sensor numbers separated by commas (e.g. 10,19,36)")

def format_coord(x, y):
    x_int, y_int = int(x + 0.5), int(y + 0.5)
    if 0 <= x_int < samps and 0 <= y_int < 336:
        x_range_start = max(0, x_int - 25)
        x_range_end = min(samps, x_int + 25)
        y_values = rawdata_pri3[y_int, x_range_start:x_range_end]
        peak_to_peak = np.max(y_values) - np.min(y_values)
        lat , lon, height = GetLocationValues(x_int)
        return f"Sensor: {y_int}, Sample: {x_int}, Gauss: {peak_to_peak:.0f}, lat: {lat}, lon: {lon}, height: {height}"  # ✅ return something, not ""
    else:
        return "Out of range"  # ✅ prevents default pixel value display

def format_coord_sec(x, y):
    x_int, y_int = int(x + 0.5), int(y + 0.5)
    if 0 <= x_int < samps and 0 <= y_int < rawdata_sec3.shape[0]:
        x_range_start = max(0, x_int - 25)
        x_range_end = min(samps, x_int + 25)
        y_values = rawdata_sec3[y_int, x_range_start:x_range_end]
        peak_to_peak = np.max(y_values) - np.min(y_values)
        lat , lon, height = GetLocationValues(x_int)
        return f"Sensor: {y_int}, Sample: {x_int}, Gauss: {peak_to_peak:.0f}, lat: {lat}, lon: {lon}, height: {height}"  # ✅ return something, not ""
    else:
        return "Out of range"  # ✅ prevents default pixel value display

info_popup = tk.Toplevel(root)
info_popup.title("Cursor Info")
info_popup.geometry("200x100+1100+700")
info_popup.attributes("-topmost", True)
info_label = tk.Label(info_popup, text="", font=("Segoe UI", 12))
info_label.pack(padx=10, pady=10)

def on_press(event):
    info_popup._drag_data = {'x': event.x, 'y': event.y}

def on_drag(event):
    dx = event.x - info_popup._drag_data['x']
    dy = event.y - info_popup._drag_data['y']
    new_x = info_popup.winfo_x() + dx
    new_y = info_popup.winfo_y() + dy
    info_popup.geometry(f"+{new_x}+{new_y}")

info_popup.bind("<ButtonPress-1>", on_press)
info_popup.bind("<B1-Motion>", on_drag)

def show_info_popup(text, label=info_label):
    info_label = label
    info_label.config(text=text)       

top_controls = tk.Frame(root)
top_controls.pack(pady=5)

sensor_mask_entry = tk.Entry(top_controls, width=20)
sensor_mask_entry.pack(side=tk.LEFT)
tk.Button(top_controls, text="Mask Sensors", command=mask_sensors).pack(side=tk.LEFT, padx=5)
tk.Button(top_controls, text="Toggle Colormap", command=toggle_colormap).pack(side=tk.LEFT, padx=5)
tk.Button(top_controls, text="Load New File", command=select_new_file).pack(side=tk.LEFT, padx=5)
tk.Button(top_controls, text="Folder Test", command=folder_test).pack(side=tk.LEFT, padx=5)

view_var = tk.StringVar(value="Both")
tk.Label(top_controls, text="View:").pack(side=tk.LEFT)
view_combo = ttk.Combobox(top_controls, textvariable=view_var, values=["Both", "Primary Only", "Secondary Only"], state="readonly", width=18)
view_combo.pack(side=tk.LEFT, padx=5)



def update_view(*args):
    selection = view_var.get()
    margin = 0.007
    if selection == 'Primary Only':
        ax1.set_visible(True)
        ax2.set_visible(False)
        fig.subplots_adjust(top=0.95, bottom=0.05)
        ax1.set_position([margin, 0.05, 1 - 2 * margin, 0.9])
    elif selection == 'Secondary Only':
        ax1.set_visible(False)
        ax2.set_visible(True)
        fig.subplots_adjust(top=0.95, bottom=0.05)
        ax2.set_position([margin, 0.05, 1 - 2 * margin, 0.9])
    else:
        ax1.set_visible(True)
        ax2.set_visible(True)
        fig.subplots_adjust(hspace=0.05)
        ax1.set_position([margin, 0.53, 1 - 2 * margin, 0.43])
        ax2.set_position([margin, 0.05, 1 - 2 * margin, 0.43])
    canvas.draw_idle()

view_combo.bind("<<ComboboxSelected>>", update_view)

jump_entry = tk.Entry(top_controls, width=5)
jump_entry.pack(side=tk.LEFT, padx=5)
tk.Button(top_controls, text="Jump to Page", command=lambda: jump_to_page()).pack(side=tk.LEFT, padx=2)
tk.Button(top_controls, text="Previous Page", command=lambda: prev_page()).pack(side=tk.LEFT, padx=2)
tk.Button(top_controls, text="Next Page", command=lambda: next_page()).pack(side=tk.LEFT, padx=2)
tk.Button(top_controls, text="Run Defect Marking", command=lambda: run_clique_analysis()).pack(side=tk.LEFT, padx=5)

x_start_entry = tk.Entry(top_controls, width=5)
x_end_entry = tk.Entry(top_controls, width=5)
x_start_entry.pack(side=tk.LEFT)
x_end_entry.pack(side=tk.LEFT)
tk.Button(top_controls, text="Show Fault Profile", command=lambda: show_fault_profile()).pack(side=tk.LEFT, padx=5)

signal_controls = tk.Frame(root)
signal_controls.pack(pady=5)

x_start_signal_entry = tk.Entry(signal_controls, width=5)
x_end_signal_entry = tk.Entry(signal_controls, width=5)
y_start_signal_entry = tk.Entry(signal_controls, width=5)
y_end_signal_entry = tk.Entry(signal_controls, width=5)

for widget in [x_start_signal_entry, x_end_signal_entry, y_start_signal_entry, y_end_signal_entry]:
    widget.pack(side=tk.LEFT, padx=2)

tk.Button(signal_controls, text="Plot Primary Signals", command=lambda: plot_primary_signals()).pack(side=tk.LEFT, padx=5)
tk.Button(signal_controls, text="Plot Secondary Signals", command=lambda: plot_secondary_signals()).pack(side=tk.LEFT, padx=5)

def next_page():
    global page_no
    page_no += 1
    update_image()

def prev_page():
    global page_no
    if page_no > 0:
        page_no -= 1
        update_image()

def jump_to_page():
    global page_no
    try:
        new_page = int(jump_entry.get())
        if new_page >= 0:
            page_no = new_page
            update_image()
    except ValueError:
        messagebox.showerror("Input Error", "Please enter a valid page number")

def calculate_fault_profile(x_start, x_end):
    profile_data = []
    for i in range(336):
        sensor_data = rawdata_pri3[i, x_start:x_end]
        peak_to_peak = np.max(sensor_data) - np.min(sensor_data)
        positive_peak = np.argmax(sensor_data)
        negative_peak = np.argmin(sensor_data)
        peak_diff = positive_peak - negative_peak
        profile_data.append([i + 1, peak_to_peak, peak_diff, positive_peak, negative_peak])
    return profile_data

def show_fault_profile():
    try:
        x_start = int(x_start_entry.get())
        x_end = int(x_end_entry.get())
        if not (0 <= x_start < x_end <= samps):
            raise ValueError("Invalid X-axis range")
        profile_data = calculate_fault_profile(x_start, x_end)
        fault_profile_window = tk.Toplevel(root)
        fault_profile_window.title("Fault Profile")
        fault_profile_window.geometry("1000x700")
        columns = ["Sensor", "Peak-to-Peak", "Peak Diff (Positive - Negative)", "Positive Peak X", "Negative Peak X"]
        style = ttk.Style()
        style.configure("Treeview", font=("Segoe UI", 12, "bold"))
        tree = ttk.Treeview(fault_profile_window, columns=columns, show="headings", height=50)
        for col in columns:
            tree.heading(col, text=col, anchor="center")
            tree.column(col, width=150, anchor="center")
        for data in profile_data:
            tree.insert("", tk.END, values=data)
        tree.pack(padx=10, pady=10)
    except ValueError as e:
        messagebox.showerror("Input Error", str(e))
def run_clique_analysis():
    try:
        from CLIQUE import run_clique_on_primary_data
        run_clique_on_primary_data(rawdata_pri3)
    except Exception as e:
        messagebox.showerror("CLIQUE Error", str(e))

def plot_primary_signals():
    try:
        x1, x2 = int(x_start_signal_entry.get()), int(x_end_signal_entry.get())
        y1, y2 = int(y_start_signal_entry.get()), int(y_end_signal_entry.get())
        if not (0 <= x1 < x2 <= samps and 0 <= y1 < y2 <= 336):
            raise ValueError("Invalid range")
        fig_sig, ax_sig = plt.subplots(figsize=(10, 4))
        gap = 100
        for i, y in enumerate(range(y1, y2)):
            signal = rawdata_pri3[y, x1:x2] + i * gap
            ax_sig.plot(range(x1, x2), signal, label=f"Sensor {y}")
        ax_sig.set_title("Primary Sensor Signal Plot")
        ax_sig.set_xlabel("Sample")
        ax_sig.set_ylabel("Amplitude + Offset")
        ax_sig.grid(True)
        ax_sig.legend(fontsize=7, loc='upper right', ncol=2)
        plt.tight_layout()
        plt.show()
    except ValueError as e:
        messagebox.showerror("Input Error", str(e))

def plot_secondary_signals():
    try:
        x1, x2 = int(x_start_signal_entry.get()), int(x_end_signal_entry.get())
        y1, y2 = int(y_start_signal_entry.get()), int(y_end_signal_entry.get())
        if not (0 <= x1 < x2 <= samps and 0 <= y1 < y2 <= 111):
            raise ValueError("Invalid range")
        fig_sig, ax_sig = plt.subplots(figsize=(10, 4))
        gap = 100
        for i, y in enumerate(range(y1, y2)):
            signal = rawdata_sec3[y, x1:x2] + i * gap
            ax_sig.plot(range(x1, x2), signal, label=f"Sensor {y}")
        ax_sig.set_title("Secondary Sensor Signal Plot")
        ax_sig.set_xlabel("Sample")
        ax_sig.set_ylabel("Amplitude + Offset")
        ax_sig.grid(True)
        ax_sig.legend(fontsize=7, loc='upper right', ncol=2)
        plt.tight_layout()
        plt.show()
    except ValueError as e:
        messagebox.showerror("Input Error", str(e))
