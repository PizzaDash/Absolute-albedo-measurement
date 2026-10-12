# Input data

Put one subfolder per image set here, plus the file(s) of light directions.
The names are chosen in the "Acquisition runs" section of `main.m`.

```
data/experiment_n
├── light_directions.mat        light directions of the setup
├── 450nm_calib/                calibration set: 99 % Spectralon standard, frontoparallel
│   ├── data.mat                preprocessed images (or the raw captures, see below)
│   └── mask_radiance.tif       pixels where the standard is visible
├── 450nm_flat/                 image set to reconstruct
│   ├── data.mat
│   ├── mask.tif                pixels to reconstruct
│   └── mask_<region>.tif       optional: regions with their own statistics
│                               (e.g. mask_white.tif and mask_gray.tif for the Bear)
└── ...
```

## Light directions

A `.mat` file holding the unit vectors from the target towards each light source, in the
camera frame (x along the image columns, y along the image rows, z along the optical axis
away from the camera; the directions therefore have a negative z component). Either:

- a variable `light_dirs` of size m x 3, or
- a struct `calib` with a field `S` of size m x 3 (the format written by our geometric
  calibration with AprilTag markers).

Row i must correspond to the i-th image of every image set. Use the `light_sources` field of
a run in `main.m` to keep only some rows of the file.

## Images

Each image set folder contains either:

1. **`data.mat`**: a struct `data` with
   - `data.I`: m x H x W double, one image per light source, already averaged over the
     N captures, dark-corrected and divided by the integration time (gray levels per second);
   - `data.ti`: m x 1 integration times, in seconds.

2. **The raw captures**, which are then preprocessed on the first run and cached as `data.mat`:
   - one subfolder per light source, whose name contains `p` and ends with the integration
     time in ms, holding the N captures as `.tif` files, e.g. `p1_im_ti_100/`, `p2_im_ti_100/`...
   - one subfolder whose name contains `bg` and ends with the integration time in ms, holding
     the dark captures (all light sources off), e.g. `bg_ti_100/`.

   The light-source subfolders are read in alphabetical order, which must be the order of
   the light directions.

All the image sets of a run (calibration and measurements) must have the same number of
images and the same size.

## Masks

`.tif` images, non-zero inside the region. Only the first channel is read.
