import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import label
import cv2
from config import *
from defect_detection import GetLocationValues, show_info_popup, rawdata_pri3

def defect_marking_format_coord(x, y):
    x_int, y_int = int(x + 0.5), int(y + 0.5)
    if 0 <= x_int < samps and 0 <= y_int < 336:
        x_range_start = max(0, x_int - 25)
        x_range_end = min(samps, x_int + 25)
        y_values = rawdata_pri3[y_int, x_range_start:x_range_end]
        peak_to_peak = np.max(y_values) - np.min(y_values)
        lat, lon = GetLocationValues(x_int)
        print(f"lat: {lat}, lon: {lon}")
        return f"Sensor: {y_int}, Sample: {x_int}, Gauss: {peak_to_peak:.0f}, lat: {lat}, lon: {lon}"  # ✅ Return something here
    else:
        return "Out of range"  # ✅ Avoid empty string

def labelgrid_format_coord(x, y):
    x_int, y_int = int(x + 0.5), int(y + 0.5)
    if 0 <= x_int < samps and 0 <= y_int < 336:
        x_range_start = max(0, x_int - 25)
        x_range_end = min(samps, x_int + 25)
        y_values = rawdata_pri3[y_int, x_range_start:x_range_end]
        peak_to_peak = np.max(y_values) - np.min(y_values)
        lat , lon = GetLocationValues(x_int)
        print(f"lat: {lat}, lon: {lon}")
        return f"Sensor: {y_int}, Sample: {x_int}, Gauss: {peak_to_peak:.0f}, lat: {lat}, lon: {lon}"  # ✅ return something, not ""
    else:
        return "Out of range"  # ✅ prevents default pixel value display


class DefectMarkingCLIQUE:
    """
    Implementation of the improved CLIQUE algorithm for defect marking
    in MFL (Magnetic Flux Leakage) pipeline inspection data.

    Based on the paper: "A novel method for defects marking and classifying
    in MFL inspection of pipeline" by Jianhua Pan and Lun Gao (2023)
    """

    def __init__(self, grid_step=5.0, density_threshold_factor=1.2):
        """
        Initialize the CLIQUE algorithm parameters.

        Args:
            grid_step (float): Grid step size in mm (ε parameter)
            density_threshold_factor (float): Factor to automatically set density threshold
        """
        self.grid_step = grid_step  # ε in the paper
        self.density_threshold = None  # δ in the paper
        self.density_threshold_factor = density_threshold_factor

    def read_mfl_data(self, axial_component_data):
        """
        Step 1: Read MFL data - Extract axial component as primary discriminative data.

        Args:
            axial_component_data (np.ndarray): 2D array of axial MFL detection signals

        Returns:
            np.ndarray: Processed axial component data
        """
        if axial_component_data.ndim != 2:
            raise ValueError("Input data must be 2D array (axial x circumferential)")

        print(f"Original data shape: {axial_component_data.shape}")
        return axial_component_data.copy()

    def divide_grid(self, data):
        """
        Step 2: Divide the detection area into grid cells.

        Args:
            data (np.ndarray): 2D MFL axial component data

        Returns:
            tuple: (grid_data, grid_shape, original_shape)
        """
        rows, cols = data.shape

        # Calculate grid dimensions
        grid_rows = int(np.ceil(rows / self.grid_step))
        grid_cols = int(np.ceil(cols / self.grid_step))

        print(f"Grid dimensions: {grid_rows} x {grid_cols}")
        print(f"Grid cell size: {self.grid_step} x {self.grid_step} mm")

        # Initialize grid to store maximum values
        grid_data = np.zeros((grid_rows, grid_cols))

        # Fill grid with maximum values from each cell
        for i in range(grid_rows):                                             ### Needs to be tuned
            for j in range(grid_cols):
                # Define cell boundaries
                row_start = int(i * self.grid_step)
                row_end = min(int((i + 1) * self.grid_step), rows)
                col_start = int(j * self.grid_step)
                col_end = min(int((j + 1) * self.grid_step), cols)

                # Extract maximum value from cell
                cell_data = data[row_start:row_end, col_start:col_end]
                if cell_data.size > 0:
                    grid_data[i, j] = np.max(cell_data)

        return grid_data, (grid_rows, grid_cols), data.shape

    def filter_data_and_calculate_density(self, grid_data):
        """
        Step 3: Filter data and transform to density values.

        Args:
            grid_data (np.ndarray): Grid data with maximum values

        Returns:
            np.ndarray: Density values for each grid cell
        """
        # Transform maximum values to density values
        # In this implementation, we use the maximum magnetic induction intensity
        # as the density value directly
        density_data = grid_data.copy()                             #### Needs to be tuned

        print(f"Density range: {np.min(density_data):.4f} to {np.max(density_data):.4f}")

        return density_data

    def set_density_threshold(self, density_data):
        """
        Step 4: Automatically set density threshold.

        Args:
            density_data (np.ndarray): Density values for grid cells
        """
        # Calculate background density (areas away from defects)
        # Use median as background reference
        # Filter out zero values before calculating median
        positive_density = density_data[density_data > 0]
        if positive_density.size > 0:
            background_density = np.median(positive_density)
        else:
            background_density = 0 # Handle case with no positive density values

        # Set threshold as 1.2 times the background density (empirical value from paper)
        self.density_threshold = background_density * self.density_threshold_factor

        print(f"Background density: {background_density:.4f}")
        print(f"Density threshold (δ): {self.density_threshold:.4f}")

    def mark_defects(self, density_data):
        """
        Step 5: Mark defects by identifying dense and sparse grids.

        Args:
            density_data (np.ndarray): Density values for grid cells

        Returns:
            tuple: (binary_mask, labeled_defects, num_defects)
        """
        # Create binary mask: dense grids (1) and sparse grids (0)
        dense_mask = density_data >= self.density_threshold

        # Connect adjacent dense grids into clusters
        labeled_defects, num_defects = label(dense_mask)
        return dense_mask.astype(int), labeled_defects, num_defects

    def process_pipeline_data(self, mfl_data):
        """
        Complete defect marking pipeline.

        Args:
            mfl_data (np.ndarray): 2D MFL axial component data

        Returns:
            dict: Results containing all processing stages
        """
        print("=" * 50)
        print("DEFECT MARKING ALGORITHM -  CLIQUE")
        print("=" * 50)

        # Step 1: Read data
        print("\nStep 1: Reading MFL data...")
        processed_data = self.read_mfl_data(mfl_data)

        # Step 2: Divide grid
        print("\nStep 2: Dividing into grid cells...")
        grid_data, grid_shape, original_shape = self.divide_grid(processed_data)

        # Step 3: Filter data and calculate density
        print("\nStep 3: Filtering data and calculating density...")
        density_data = self.filter_data_and_calculate_density(grid_data)

        # Step 4: Set density threshold
        print("\nStep 4: Setting density threshold...")
        self.set_density_threshold(density_data)

        # Step 5: Mark defects
        print("\nStep 5: Marking defects...")
        binary_mask, labeled_defects, num_defects = self.mark_defects(density_data)

        # Prepare results
        results = {
            'original_data': processed_data,
            'grid_data': grid_data,
            'density_data': density_data,
            'binary_mask': binary_mask,
            'labeled_defects': labeled_defects,
            'num_defects': num_defects,
            'grid_shape': grid_shape,
            'original_shape': original_shape,
            'density_threshold': self.density_threshold
        }

        print(f"\nProcessing complete! {num_defects} defect regions marked.")
        return results

    def visualize_results(self, results, figsize=(8, 10)):
        """
        Visualize the defect marking results: (a) Original, (e) Labeled Defects.
        Arranged as a 2x1 figure (two rows, one column).
        Args:
            results (dict): Results from process_pipeline_data
            figsize (tuple): Figure size
        """
        fig, axes = plt.subplots(2, 1, figsize=figsize)
        fig.suptitle('Defect Marking Algorithm Results', fontsize=16)

        # (a) Original data
        im1 = axes[0].imshow(results['original_data'], cmap='gray', aspect='auto')
        axes[0].set_title('(a) Original Axial MFL Data')
        axes[0].set_xlabel('Circumferential Position (mm)')
        axes[0].set_ylabel('Axial Position (mm)')
        plt.colorbar(im1, ax=axes[0], label='Magnetic Induction (T)')
        axes[0].format_coord = defect_marking_format_coord

        # (e) Labeled defects
        im2 = axes[1].imshow(results['labeled_defects'], cmap='gray', aspect='auto')
        axes[1].set_title(f'(e) Labeled Defects (n={results["num_defects"]})')
        axes[1].set_xlabel('Grid Column')
        axes[1].set_ylabel('Grid Row')
        axes[1].format_coord = labelgrid_format_coord
        plt.colorbar(im2, ax=axes[1], label='Defect Label')
        axes[1].format_coord = labelgrid_format_coord

        plt.tight_layout(rect=[0, 0, 1, 0.97])
        plt.show()

    def extract_defect_regions(self, results):
        """
        Extract individual defect regions for further analysis.

        Args:
            results (dict): Results from process_pipeline_data

        Returns:
            list: List of defect region information
        """
        defect_regions = []

        for defect_id in range(1, results['num_defects'] + 1):
            # Find defect region in grid coordinates
            defect_mask = results['labeled_defects'] == defect_id
            rows, cols = np.where(defect_mask)

            if len(rows) > 0:
                # Calculate bounding box in grid coordinates
                min_row, max_row = np.min(rows), np.max(rows)
                min_col, max_col = np.min(cols), np.max(cols)

                # Convert to original data coordinates
                orig_min_row = int(min_row * self.grid_step)
                orig_max_row = min(int((max_row + 1) * self.grid_step), results['original_shape'][0])
                orig_min_col = int(min_col * self.grid_step)
                orig_max_col = min(int((max_col + 1) * self.grid_step), results['original_shape'][1])

                # Extract original data for this defect region
                defect_data = results['original_data'][
                    orig_min_row:orig_max_row,
                    orig_min_col:orig_max_col
                ]

                defect_info = {
                    'defect_id': defect_id,
                    'grid_bbox': (min_row, max_row, min_col, max_col),
                    'original_bbox': (orig_min_row, orig_max_row, orig_min_col, orig_max_col),
                    'defect_data': defect_data,
                    'area_grid_cells': np.sum(defect_mask),
                    'max_signal': np.max(defect_data) if defect_data.size > 0 else 0
                }

                defect_regions.append(defect_info)

        return defect_regions


# def generate_synthetic_mfl_data(shape=(200, 100), num_defects=3, noise_level=0.1):
#     """
#     Generate synthetic MFL data for testing the algorithm.

#     Args:
#         shape (tuple): Shape of the data (axial, circumferential)
#         num_defects (int): Number of defects to simulate
#         noise_level (float): Noise level

#     Returns:
#         np.ndarray: Synthetic MFL data
#     """
#     data = np.random.normal(0, noise_level, shape)

#     # Add defects as high-amplitude regions
#     for i in range(num_defects):
#         # Random defect position and size
#         center_row = np.random.randint(20, shape[0] - 20)
#         center_col = np.random.randint(20, shape[1] - 20)
#         size_row = np.random.randint(10, 30)
#         size_col = np.random.randint(5, 15)
#         amplitude = np.random.uniform(0.5, 1.5)

#         # Create Gaussian-like defect
#         y, x = np.ogrid[:shape[0], :shape[1]]
#         defect_mask = ((y - center_row)**2 / (size_row/2)**2 +
#                       (x - center_col)**2 / (size_col/2)**2) <= 1

#         # Calculate the exponential term using the full 2D arrays
#         defect_amplitude = amplitude * np.exp(-((y - center_row)**2 / (size_row/4)**2 +
#                                                 (x - center_col)**2 / (size_col/4)**2))

#         # Apply the defect mask to the calculated amplitude and add to data
#         data[defect_mask] += defect_amplitude[defect_mask]


#     return data


# Applying the CLIQUE algorithm on primary MFL data: 
def run_clique_on_primary_data(primary_data, grid_step=1.2, density_factor=5.0):
    """
    Run CLIQUE defect marking algorithm on given primary sensor data.

    Args:
        primary_data (np.ndarray): Preprocessed 2D primary MFL data (rawdata_pri3)
        grid_step (float): Grid cell size for CLIQUE
        density_factor (float): Density threshold multiplier

    Returns:
        dict: Result dictionary from CLIQUE processing
    """
    if primary_data is None or not isinstance(primary_data, np.ndarray):
        raise ValueError("Valid primary data (rawdata_pri3) must be provided.")

    print("Running CLIQUE defect marking algorithm...")
    # marker = DefectMarkingCLIQUE(grid_step=grid_step, density_threshold_factor=density_factor)
    # results = marker.process_pipeline_data(primary_data)
    # marker.visualize_results(results)
    clique = DefectMarkingCLIQUE(grid_step=1.2, density_threshold_factor=5.0)
    results = clique.process_pipeline_data(primary_data)
    clique.visualize_results(results)
    return results

