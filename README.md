# Physically accurate albedo calibration for Photometric Stereo

MATLAB code for the paper *Physically accurate albedo calibration for Photometric Stereo*
(T. Fevrier, J. Delpech, T. Sentenac, Y. Quéau, F. Bugarin).

Photometric stereo (PS) usually recovers the albedo only up to an unknown scale factor, the
unknown intensity of the light sources. This code turns PS into an absolute albedo
measurement:

1. **Reflectometric calibration** (Sec. 4). The coefficient S̃ᵢ of each light source is
   measured at every pixel and for every filter, from images of a Spectralon standard of
   certified albedo (0.99) placed frontoparallel to the camera:
   S̃ᵢ = π Iᵢ / (0.99 cos θᵢ).
2. **EON photometric stereo** (Sec. 3). At every pixel, the diffuse albedo ρ_d, the roughness
   σ and the normal n are fitted to the images with the Energy-preserving Oren–Nayar (EON)
   model, using `fmincon` in two passes (Lambertian initialization, then neighbour-averaged
   initialization for the pixels that did not converge).
3. **Albedo** (Sec. 3.2). Since EON conserves energy, the albedo it gives is a physical
   reflectance. It is computed at an 8° incidence angle, the geometry of the
   integrating-sphere reference measurements of Sec. 5.

## Quick start

1. Put the image sets in `data/` (see [`data/README.md`](data/README.md)).
2. List them in the "Acquisition runs" section of `main.m`.
3. Run `main.m`.

Results are written to `results/`:

| File | Content |
|---|---|
| `results/summary.csv` | mean and std of the albedo and of σ for every image set (and region) |
| `results/<calib set>/calib.mat` | calibration coefficients S̃ᵢ (m x H x W) and light directions |
| `results/<calib set>/<calib set>_S_tilde.png` | distribution of S̃ᵢ for each light source |
| `results/<set>/<set>_estimates.mat` | albedo, ρ_d, σ, normals and convergence maps |
| `results/<set>/<set>_*.png` | input images, albedo, normal, σ and convergence maps, histograms, reconstructed BRDF |
| `results/calibration_spectral.png` | S̃ᵢ of every run, side by side (log scale) |

With image sets named as in `main.m` (e.g. `450nm_flat`), the figures get the file names
used in the paper (e.g. `450nm_flat_albedo_map.png`).

## Code organization

```
main.m                          the whole pipeline: settings, runs, calibration, PS, outputs
data/                           input image sets (see data/README.md)
lib/
  Data loading
    load_image_set.m            preprocessed images of a set (data.mat), or raw captures
    preprocess_raw_captures.m   averaging, dark correction and exposure normalization (Sec. 4.2)
    load_light_directions.m     light directions of a run
    load_mask.m                 binary mask from an image
    load_region_masks.m         optional sub-regions of an image set
  Reflectometric calibration
    reflectometric_calibration.m  per-pixel S̃ᵢ from the Spectralon images (Sec. 4.3)
    fit_poly2_surface.m           extrapolation of S̃ᵢ outside the standard
  EON reflectance model (Sec. 3.2)
    fon_brdf.m                  Fujii Oren–Nayar lobe, divided by ρ_d
    eon_ms_brdf.m               multiple-scattering term
    eon_brdf.m                  full EON BRDF
    fon_G.m                     angular function G_F
    fon_albedo.m                albedo of the Fujii lobe
    eon_ms_albedo.m             albedo of the multiple-scattering term
    eon_albedo.m                EON albedo
  EON photometric stereo (Sec. 3.3)
    eon_photometric_stereo.m    two-pass per-pixel estimation (Algorithm 1)
    eon_objective.m             least-squares cost of one pixel
    unit_normal_constraint.m    constraint ||n|| = 1
  Outputs
    summarize_estimates.m       mean and std of the estimates
    plot_calibration.m          histograms of S̃ᵢ
    plot_calibration_spectral.m S̃ᵢ of every run (box plot)
    plot_ps_results.m           maps and histograms of one image set
    plot_eon_brdf_polar.m       BRDF reconstructed from the estimates (Sec. 5.3)
    normals_to_rgb.m            color-coded normal map
    save_figure.m               saves a figure as .png and .fig
```

## Conventions

- Camera frame: x along the image columns, y along the image rows (pointing down), z along
  the optical axis, away from the camera.
- Light directions point from the target towards the sources (negative z component).
- A surface facing the camera has the normal [0 0 -1]; the camera is orthographic, with the
  viewing direction [0 0 -1].
- Images are in gray levels per second (divided by their integration time).

## Requirements

- MATLAB R2020b or newer.
- Optimization Toolbox (`fmincon`).
- Image Processing Toolbox (`im2double`, only to preprocess raw captures).
- Parallel Computing Toolbox, optional: the per-pixel loops are `parfor` loops, which run
  on a parallel pool when the toolbox is available and serially otherwise.

The optimization solves one nonlinear problem per pixel, so a full-resolution image set can
take several hours. Set `cfg.reuse_estimates = true` in `main.m` to redraw the figures and
statistics from saved estimates without running it again.

## Correspondence with the original scripts

| Original | Here |
|---|---|
| `preprocess.m` | `lib/preprocess_raw_captures.m`, called by `lib/load_image_set.m` |
| `etalonnage.m`, `Tools/Radiance_calib.m` (`main_mask`) | `main.m` (step 1), `lib/reflectometric_calibration.m` |
| `polyfitn` / `polyvaln` (File Exchange), order 2 | `lib/fit_poly2_surface.m` |
| `main.m`, `runall_reflecto_paper.m` | `main.m` |
| `estimation_oren_nayar_fmincon.m` | `lib/eon_photometric_stereo.m` |
| `obj_EON.m`, `optim_constraints_normals.m` | `lib/eon_objective.m`, `lib/unit_normal_constraint.m` |
| `oren_nayar_brdf.m`, `oren_nayar_EC_term.m`, `oren_nayar_brdf_full.m`, `oren_nayar_G.m` | `lib/fon_brdf.m`, `lib/eon_ms_brdf.m`, `lib/eon_brdf.m`, `lib/fon_G.m` |
| `oren_nayar_albedo.m`, `oren_nayar_EC_albedo.m`, `EON_albedo.m` | `lib/fon_albedo.m`, `lib/eon_ms_albedo.m`, `lib/eon_albedo.m` |
| `calib_display.m` | `lib/plot_calibration.m`, `lib/plot_calibration_spectral.m` |
| `Results_reflecto-paper-4/plot_EON_brdf.m` | `lib/plot_eon_brdf_polar.m` |
