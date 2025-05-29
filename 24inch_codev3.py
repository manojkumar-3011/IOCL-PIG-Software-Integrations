import os
import numpy as np
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import platform
from matplotlib.colors import Normalize
from scipy.ndimage import zoom, gaussian_filter, uniform_filter
from scipy.interpolate import RectBivariateSpline, interp2d
from scipy import signal
import cv2

try:
    from ctypes import windll
    windll.shcore.SetProcessDpiAwareness(1)
except:
    pass

T = 460  # total buffer size
samps = 5000  # total samps in one page
offset = 0
page_no = 0  # default page number
cd = 2  # marked as CD number
primary_sen = 336
secondary_sen = 111
masked_sensors = set()
file_path = None

# Enhanced visualization parameters
enhancement_mode = "Advanced"  # Can be "Basic", "Advanced", "Ultra"
noise_reduction_strength = 0.3
sharpening_strength = 1.5
contrast_enhancement = 1.2

root = tk.Tk()
root.withdraw()

##File
file_dir = filedialog.askdirectory(title="Select Folder Containing Binary Files")
if not file_dir:
    messagebox.showerror("Folder Error", "No folder selected. Exiting application.")
    exit()

root.deiconify()
root.title("Enhanced B-Scan Viewer with Advanced Resolution Enhancement")

# Platform-specific window maximization
if platform.system() == "Windows":
    root.state('zoomed')
else:
    root.attributes('-zoomed', True)

colormaps = ['gray', 'jet', 'viridis', 'plasma', 'hot', 'inferno', 'magma']
current_cmap_index = 0

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
fig.subplots_adjust(hspace=0.4)

canvas = FigureCanvasTkAgg(fig, master=root)
canvas.draw()
canvas_widget = canvas.get_tk_widget()
canvas_widget.pack(fill=tk.BOTH, expand=1)

def select_new_file():
    global file_path, page_no
    page_no = 0
    selected = filedialog.askopenfilename(
        initialdir=file_dir,
        title="Select Binary File",
        filetypes=[("Binary Files", "*.bin"), ("All Files", "*.*")]
    )
    if selected:
        file_path = selected
        update_image()

def toggle_colormap():
    global current_cmap_index
    current_cmap_index = (current_cmap_index + 1) % len(colormaps)
    update_image()

def apply_noise_reduction(data, method='gaussian'):
    """Advanced noise reduction techniques"""
    if method == 'gaussian':
        return gaussian_filter(data, sigma=0.8)
    elif method == 'bilateral':
        # Convert to uint8 for OpenCV
        data_norm = ((data - data.min()) / (data.max() - data.min()) * 255).astype(np.uint8)
        filtered = cv2.bilateralFilter(data_norm, 9, 75, 75)
        # Convert back to original scale
        return filtered.astype(np.float64) / 255 * (data.max() - data.min()) + data.min()
    elif method == 'median':
        return signal.medfilt2d(data, kernel_size=3)
    else:
        return uniform_filter(data, size=2)

def apply_sharpening(data, strength=1.5):
    """Apply unsharp masking for sharpening"""
    # Create Gaussian blur
    blurred = gaussian_filter(data, sigma=1.0)
    # Create sharpening mask
    mask = data - blurred
    # Apply sharpening
    sharpened = data + strength * mask
    return sharpened

def enhance_contrast(data, method='adaptive'):
    """Enhanced contrast adjustment"""
    if method == 'adaptive':
        # Adaptive histogram equalization
        data_norm = (data - data.min()) / (data.max() - data.min())
        # Apply CLAHE-like enhancement
        enhanced = np.power(data_norm, 0.7)  # Gamma correction
        return enhanced * (data.max() - data.min()) + data.min()
    else:
        # Simple contrast stretching
        p2, p98 = np.percentile(data, (2, 98))
        return np.clip((data - p2) / (p98 - p2), 0, 1) * (data.max() - data.min()) + data.min()

def advanced_upscale_data(data, scale=4, method='bicubic'):
    """Advanced upscaling with multiple interpolation methods"""
    if method == 'bicubic':
        # Use RectBivariateSpline for smooth bicubic interpolation
        y = np.arange(data.shape[0])
        x = np.arange(data.shape[1])
        spline = RectBivariateSpline(y, x, data, kx=3, ky=3, s=0)
        y_new = np.linspace(0, data.shape[0] - 1, data.shape[0] * scale)
        x_new = np.linspace(0, data.shape[1] - 1, data.shape[1] * scale)
        return spline(y_new, x_new)
    
    elif method == 'lanczos':
        # Use zoom with order=3 for Lanczos-like interpolation
        return zoom(data, scale, order=3, prefilter=True)
    
    elif method == 'super_resolution':
        # Multi-step super resolution approach
        # Step 1: Initial upscaling
        upscaled = zoom(data, scale//2, order=3)
        # Step 2: Noise reduction
        denoised = apply_noise_reduction(upscaled, 'bilateral')
        # Step 3: Final upscaling
        final = zoom(denoised, 2, order=3)
        return final
    
    else:  # default bicubic
        return zoom(data, scale, order=3)

def process_image_data(data, enhancement_level="Advanced"):
    """Complete image processing pipeline"""
    
    if enhancement_level == "Basic":
        # Basic processing
        enhanced = apply_noise_reduction(data, 'gaussian')
        upscaled = advanced_upscale_data(enhanced, scale=2, method='bicubic')
        
    elif enhancement_level == "Advanced":  
        # Advanced processing pipeline
        # Step 1: Noise reduction
        denoised = apply_noise_reduction(data, 'bilateral')
        # Step 2: Contrast enhancement
        contrast_enhanced = enhance_contrast(denoised, 'adaptive')
        # Step 3: Sharpening
        sharpened = apply_sharpening(contrast_enhanced, sharpening_strength)
        # Step 4: High-quality upscaling
        upscaled = advanced_upscale_data(sharpened, scale=4, method='bicubic')
        
    elif enhancement_level == "Ultra":
        # Ultra-high quality processing
        # Step 1: Advanced denoising
        denoised1 = apply_noise_reduction(data, 'bilateral')
        denoised2 = apply_noise_reduction(denoised1, 'gaussian')
        # Step 2: Multi-step contrast enhancement
        contrast1 = enhance_contrast(denoised2, 'adaptive')
        contrast2 = enhance_contrast(contrast1, method='stretch')
        # Step 3: Selective sharpening
        sharpened = apply_sharpening(contrast2, sharpening_strength * 1.2)
        # Step 4: Super-resolution upscaling
        upscaled = advanced_upscale_data(sharpened, scale=6, method='super_resolution')
        
    else:
        upscaled = data
    
    return upscaled

def update_image():
    global rawdata_pri3, rawdata_sec3
    if not file_path or not os.path.exists(file_path):
        messagebox.showerror("File Error", "No file selected or file does not exist.")
        return

    byte_offset = (page_no * samps + offset) * T * 2
    with open(file_path, 'rb') as fid:
        fid.seek(byte_offset, 0)
        a = np.fromfile(fid, dtype=np.uint16, count=T * samps)

    if len(a) < T * samps:
        messagebox.showerror("File Error", "Not enough data to display this page.")
        return

    buff = a.reshape((samps, T)).T

    rawdata_prif = buff[:primary_sen, :] * 4.09618 * 320 / 65535
    rawdata_secf = buff[primary_sen:primary_sen+secondary_sen, :] * 4.09618 * 320 / 65535

    # Subtract average for better contrast
    avg_sec = np.mean(rawdata_secf, axis=1)
    avg_pri = np.mean(rawdata_prif, axis=1)
    rawdata_pri3 = rawdata_prif - avg_pri[:, np.newaxis]
    rawdata_sec3 = rawdata_secf - avg_sec[:, np.newaxis]

    # Apply masking if sensors are masked
    if masked_sensors:
        for sensor in masked_sensors:
            if 0 <= sensor < primary_sen:
                rawdata_pri3[sensor, :] = 0
            if 0 <= sensor < secondary_sen:
                rawdata_sec3[sensor, :] = 0

    # Enhanced processing pipeline
    highres_pri = process_image_data(rawdata_pri3, enhancement_mode)
    highres_sec = process_image_data(rawdata_sec3, enhancement_mode)

    # Improved normalization with outlier handling
    def robust_normalize(data):
        p1, p99 = np.percentile(data, (1, 99))
        clipped = np.clip(data, p1, p99)
        return Normalize(vmin=p1, vmax=p99)(clipped)

    norm_pri = robust_normalize(highres_pri)
    norm_sec = robust_normalize(highres_sec)

    ax1.clear()
    ax2.clear()

    cmap = colormaps[current_cmap_index]
    
    # Enhanced display with better interpolation
    im1 = ax1.imshow(highres_pri, cmap=cmap, aspect='auto', 
                     interpolation='bilinear', norm=Normalize(vmin=np.percentile(highres_pri, 1), 
                                                            vmax=np.percentile(highres_pri, 99)))
    ax1.set_title(f'Enhanced Primary Sensors - cd: {cd} & page no: {page_no} [{enhancement_mode} Mode]')
    ax1.format_coord = format_coord

    im2 = ax2.imshow(highres_sec, cmap=cmap, aspect='auto', 
                     interpolation='bilinear', norm=Normalize(vmin=np.percentile(highres_sec, 1), 
                                                            vmax=np.percentile(highres_sec, 99)))
    ax2.set_title(f'Enhanced Secondary Sensors - cd: {cd} & page no: {page_no} [{enhancement_mode} Mode]')
    ax2.format_coord = format_coord_sec

    # Add colorbars for better visualization
    if hasattr(ax1, 'collections') and ax1.collections:
        plt.colorbar(im1, ax=ax1, shrink=0.8)
    if hasattr(ax2, 'collections') and ax2.collections:
        plt.colorbar(im2, ax=ax2, shrink=0.8)

    canvas.draw_idle()

def change_enhancement_mode():
    global enhancement_mode
    modes = ["Basic", "Advanced", "Ultra"]
    current_index = modes.index(enhancement_mode)
    enhancement_mode = modes[(current_index + 1) % len(modes)]
    enhancement_label.config(text=f"Enhancement: {enhancement_mode}")
    update_image()

def adjust_noise_reduction():
    global noise_reduction_strength
    try:
        noise_reduction_strength = float(noise_entry.get())
        update_image()
    except ValueError:
        messagebox.showerror("Input Error", "Enter a valid number for noise reduction (0.0-1.0)")

def adjust_sharpening():
    global sharpening_strength
    try:
        sharpening_strength = float(sharp_entry.get())
        update_image()
    except ValueError:
        messagebox.showerror("Input Error", "Enter a valid number for sharpening (0.5-3.0)")

def mask_sensors():
    try:
        sensors = list(map(int, sensor_mask_entry.get().split(',')))
        masked_sensors.update(sensors)
        update_image()
    except ValueError:
        messagebox.showerror("Input Error", "Enter sensor numbers separated by commas (e.g. 10,19,36)")

def clear_mask():
    global masked_sensors
    masked_sensors.clear()
    update_image()

def format_coord(x, y):
    x_int, y_int = int(x + 0.5), int(y + 0.5)
    if 0 <= x_int < samps and 0 <= y_int < primary_sen:
        x_range_start = max(0, x_int - 25)
        x_range_end = min(samps, x_int + 25)
        y_values = rawdata_pri3[y_int, x_range_start:x_range_end]
        peak_to_peak = np.max(y_values) - np.min(y_values)
        text = f"Sensor: {y_int}\nSample: {x_int}\nGauss: {peak_to_peak:.0f}"
        show_info_popup(text)
    return ""

def format_coord_sec(x, y):
    x_int, y_int = int(x + 0.5), int(y + 0.5)
    if 0 <= x_int < samps and 0 <= y_int < rawdata_sec3.shape[0]:
        x_range_start = max(0, x_int - 25)
        x_range_end = min(samps, x_int + 25)
        y_values = rawdata_sec3[y_int, x_range_start:x_range_end]
        peak_to_peak = np.max(y_values) - np.min(y_values)
        text = f"Sensor: {y_int}\nSample: {x_int}\nGauss: {peak_to_peak:.0f}"
        show_info_popup(text)
    return ""

# Info popup
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

def show_info_popup(text):
    info_label.config(text=text)

# Enhanced controls
top_controls = tk.Frame(root)
top_controls.pack(pady=5)

# File and basic controls
tk.Button(top_controls, text="Load New File", command=select_new_file).pack(side=tk.LEFT, padx=5)
tk.Button(top_controls, text="Toggle Colormap", command=toggle_colormap).pack(side=tk.LEFT, padx=5)

# Enhancement controls
enhancement_frame = tk.Frame(top_controls)
enhancement_frame.pack(side=tk.LEFT, padx=10)
enhancement_label = tk.Label(enhancement_frame, text=f"Enhancement: {enhancement_mode}", font=("Segoe UI", 10, "bold"))
enhancement_label.pack()
tk.Button(enhancement_frame, text="Change Mode", command=change_enhancement_mode).pack()

# Noise reduction control
noise_frame = tk.Frame(top_controls)
noise_frame.pack(side=tk.LEFT, padx=5)
tk.Label(noise_frame, text="Noise Reduction:").pack()
noise_entry = tk.Entry(noise_frame, width=8)
noise_entry.insert(0, str(noise_reduction_strength))
noise_entry.pack()
tk.Button(noise_frame, text="Apply", command=adjust_noise_reduction).pack()

# Sharpening control
sharp_frame = tk.Frame(top_controls)
sharp_frame.pack(side=tk.LEFT, padx=5)
tk.Label(sharp_frame, text="Sharpening:").pack()
sharp_entry = tk.Entry(sharp_frame, width=8)
sharp_entry.insert(0, str(sharpening_strength))
sharp_entry.pack()
tk.Button(sharp_frame, text="Apply", command=adjust_sharpening).pack()

# Sensor masking
mask_frame = tk.Frame(top_controls)
mask_frame.pack(side=tk.LEFT, padx=5)
tk.Label(mask_frame, text="Mask Sensors:").pack()
sensor_mask_entry = tk.Entry(mask_frame, width=15)
sensor_mask_entry.pack()
mask_buttons = tk.Frame(mask_frame)
mask_buttons.pack()
tk.Button(mask_buttons, text="Mask", command=mask_sensors).pack(side=tk.LEFT)
tk.Button(mask_buttons, text="Clear", command=clear_mask).pack(side=tk.LEFT)

# View controls
view_frame = tk.Frame(root)
view_frame.pack(pady=5)

view_var = tk.StringVar(value="Both")
tk.Label(view_frame, text="View:").pack(side=tk.LEFT)
view_combo = ttk.Combobox(view_frame, textvariable=view_var, 
                         values=["Both", "Primary Only", "Secondary Only"], 
                         state="readonly", width=18)
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

# Navigation controls
nav_frame = tk.Frame(view_frame)
nav_frame.pack(side=tk.LEFT, padx=20)

jump_entry = tk.Entry(nav_frame, width=8)
jump_entry.pack(side=tk.LEFT, padx=2)
tk.Button(nav_frame, text="Jump to Page", command=lambda: jump_to_page()).pack(side=tk.LEFT, padx=2)
tk.Button(nav_frame, text="Previous", command=lambda: prev_page()).pack(side=tk.LEFT, padx=2)
tk.Button(nav_frame, text="Next", command=lambda: next_page()).pack(side=tk.LEFT, padx=2)

# Analysis controls
analysis_frame = tk.Frame(root)
analysis_frame.pack(pady=5)

# Fault profile controls
fault_frame = tk.Frame(analysis_frame)
fault_frame.pack(side=tk.LEFT, padx=10)
tk.Label(fault_frame, text="Fault Profile Range:").pack()
fault_range_frame = tk.Frame(fault_frame)
fault_range_frame.pack()
x_start_entry = tk.Entry(fault_range_frame, width=6)
x_end_entry = tk.Entry(fault_range_frame, width=6)
x_start_entry.pack(side=tk.LEFT)
tk.Label(fault_range_frame, text=" to ").pack(side=tk.LEFT)
x_end_entry.pack(side=tk.LEFT)
tk.Button(fault_frame, text="Show Fault Profile", command=lambda: show_fault_profile()).pack()

# Signal plotting controls
signal_frame = tk.Frame(analysis_frame)
signal_frame.pack(side=tk.LEFT, padx=10)
tk.Label(signal_frame, text="Signal Range:").pack()
signal_range_frame = tk.Frame(signal_frame)
signal_range_frame.pack()

x_start_signal_entry = tk.Entry(signal_range_frame, width=5)
x_end_signal_entry = tk.Entry(signal_range_frame, width=5)
y_start_signal_entry = tk.Entry(signal_range_frame, width=5)
y_end_signal_entry = tk.Entry(signal_range_frame, width=5)

for widget in [x_start_signal_entry, x_end_signal_entry, y_start_signal_entry, y_end_signal_entry]:
    widget.pack(side=tk.LEFT, padx=1)

signal_buttons = tk.Frame(signal_frame)
signal_buttons.pack()
tk.Button(signal_buttons, text="Plot Primary", command=lambda: plot_primary_signals()).pack(side=tk.LEFT, padx=2)
tk.Button(signal_buttons, text="Plot Secondary", command=lambda: plot_secondary_signals()).pack(side=tk.LEFT, padx=2)

# Navigation functions
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

# Analysis functions
def calculate_fault_profile(x_start, x_end):
    profile_data = []
    for i in range(primary_sen):
        if i not in masked_sensors:
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
        fault_profile_window.title("Enhanced Fault Profile Analysis")
        fault_profile_window.geometry("1200x700")
        
        columns = ["Sensor", "Peak-to-Peak", "Peak Diff (Pos-Neg)", "Positive Peak X", "Negative Peak X"]
        
        style = ttk.Style()
        style.configure("Treeview", font=("Segoe UI", 11))
        style.configure("Treeview.Heading", font=("Segoe UI", 12, "bold"))
        
        tree = ttk.Treeview(fault_profile_window, columns=columns, show="headings", height=30)
        
        for col in columns:
            tree.heading(col, text=col, anchor="center")
            tree.column(col, width=180, anchor="center")
        
        for data in profile_data:
            tree.insert("", tk.END, values=data)
        
        scrollbar = ttk.Scrollbar(fault_profile_window, orient="vertical", command=tree.yview)
        tree.configure(yscrollcommand=scrollbar.set)
        
        tree.pack(side="left", fill="both", expand=True, padx=10, pady=10)
        scrollbar.pack(side="right", fill="y")
        
    except ValueError as e:
        messagebox.showerror("Input Error", str(e))

def plot_primary_signals():
    try:
        x1, x2 = int(x_start_signal_entry.get()), int(x_end_signal_entry.get())
        y1, y2 = int(y_start_signal_entry.get()), int(y_end_signal_entry.get())
        if not (0 <= x1 < x2 <= samps and 0 <= y1 < y2 <= primary_sen):
            raise ValueError("Invalid range")
        
        fig_sig, ax_sig = plt.subplots(figsize=(12, 6))
        gap = 100
        colors = plt.cm.tab10(np.linspace(0, 1, min(10, y2-y1)))
        
        for i, y in enumerate(range(y1, y2)):
            if y not in masked_sensors:
                signal_data = rawdata_pri3[y, x1:x2] + i * gap
                color = colors[i % len(colors)]
                ax_sig.plot(range(x1, x2), signal_data, label=f"Sensor {y}", color=color, linewidth=1.5)
        
        ax_sig.set_title(f"Enhanced Primary Sensor Signals (Page {page_no})", fontsize=14, fontweight='bold')
        ax_sig.set_xlabel("Sample", fontsize=12)
        ax_sig.set_ylabel("Amplitude + Offset", fontsize=12)
        ax_sig.grid(True, alpha=0.3)
        ax_sig.legend(fontsize=8, loc='upper right', ncol=3)
        plt.tight_layout()
        plt.show()
        
    except ValueError as e:
        messagebox.showerror("Input Error", str(e))

def plot_secondary_signals():
    try:
        x1, x2 = int(x_start_signal_entry.get()), int(x_end_signal_entry.get())
        y1, y2 = int(y_start_signal_entry.get()), int(y_end_signal_entry.get())
        if not (0 <= x1 < x2 <= samps and 0 <= y1 < y2 <= secondary_sen):
            raise ValueError("Invalid range")
        
        fig_sig, ax_sig = plt.subplots(figsize=(12, 6))
        gap = 100
        colors = plt.cm.tab10(np.linspace(0, 1, min(10, y2-y1)))
        
        for i, y in enumerate(range(y1, y2)):
            if y not in masked_sensors:
                signal_data = rawdata_sec3[y, x1:x2] + i * gap
                color = colors[i % len(colors)]
                ax_sig.plot(range(x1, x2), signal_data, label=f"Sensor {y}", color=color, linewidth=1.5)
        
        ax_sig.set_title(f"Enhanced Secondary Sensor Signals (Page {page_no})", fontsize=14, fontweight='bold')
        ax_sig.set_xlabel("Sample", fontsize=12)
        ax_sig.set_ylabel("Amplitude + Offset", fontsize=12)
        ax_sig.grid(True, alpha=0.3)
        ax_sig.legend(fontsize=8, loc='upper right', ncol=3)
        plt.tight_layout()
        plt.show()
        
    except ValueError as e:
        messagebox.showerror("Input Error", str(e))

if __name__ == "__main__":
    root.mainloop()