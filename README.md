# splatter-image++
Case study on enhancing monocular object reconstruction based on the 
 **"Splatter Image: Ultra-Fast Single-View 3D Reconstruction" (CVPR 2024)**

Authors: Adam Deryło, Emin Sadikhov, Małgorzata Gwiazda (equal contribution)

# Installation

1. Assuming you have CUDA/11.6 installed, create a conda environment: 
```
conda env create -f env.yaml -n splatter-image
conda activate splatter-image 
```
If that is not the case (TUM Cluster) use `env+cu116.yaml` so CUDA will be installed inside of the conda environment. The downside of this is that env initialization takes considerably longer. 

2. Install Gaussian Splatting renderer:
```
git clone git@github.com:splatter-works/gaussian-splatting.git
cd gaussian-splatting 
git submodule update --init --recursive
pip install submodules/diff-gaussian-rasterization 
```
3. If you want to train on CO3D data you will need to install Pytorch3D 0.7.2. (This is only needed for preprocessing of data.) See instructions [here](https://github.com/facebookresearch/pytorch3d/blob/main/INSTALL.md). It is recommended to install with pip from a pre-built binary. Find a compatible binary [here](https://anaconda.org/pytorch3d/pytorch3d/files?page=5) and install it with `pip`. For example, with Python 3.8, Pytorch 1.13.0, CUDA 11.6 run
`pip install --no-index --no-cache-dir pytorch3d -f https://anaconda.org/pytorch3d/pytorch3d/0.7.2/download/linux-64/pytorch3d-0.7.2-py38_cu116_pyt1130.tar.bz2`.

# Data

## ShapeNet cars and chairs
For training / evaluating on ShapeNet-SRN classes (cars, chairs) please download the srn_\*.zip (\* = cars or chairs) from [PixelNeRF data folder](https://drive.google.com/drive/folders/1PsT3uKwqHHD2bEEHkIXB99AlIjtmrEiR?usp=sharing). Unzip the data file and change `SHAPENET_DATASET_ROOT` in `datasets/srn.py` to the parent folder of the unzipped folder. For example, if your folder structure is: `/home/user/SRN/srn_cars/cars_train`, in `datasets/srn.py` set  `SHAPENET_DATASET_ROOT="/home/user/SRN"`. No additional preprocessing is needed.

## CO3D hydrants and teddybears
For training / evaluating on CO3D download the hydrant and teddybear classes from the [CO3D release](https://github.com/facebookresearch/co3d/tree/main). To do so, run the following commands:
```
git clone https://github.com/facebookresearch/co3d.git
cd co3d
mkdir DOWNLOAD_FOLDER
python ./co3d/download_dataset.py --download_folder DOWNLOAD_FOLDER --download_categories hydrant,teddybear
```
Next, set `CO3D_RAW_ROOT` to your `DOWNLOAD_FOLDER` in `data_preprocessing/preoprocess_co3d.py`. Set `CO3D_OUT_ROOT` to where you want to store preprocessed data. Run 
```
python -m data_preprocessing.preprocess_co3d
``` 
and set `CO3D_DATASET_ROOT:=CO3D_OUT_ROOT`.

## Multi-category ShapeNet
For multi-category ShapeNet we use the ShapeNet 64x64 dataset by NMR hosted by DVR authors which can be downloaded [here](https://s3.eu-central-1.amazonaws.com/avg-projects/differentiable_volumetric_rendering/data/NMR_Dataset.zip).
Unzip the folder and set `NMR_DATASET_ROOT` to the directory that holds sub-category folders after unzipping. In other words, `NMR_DATASET_ROOT` directory should contain folders `02691156`, `02828884`, `02933112` etc.

## Objaverse

For training on Objaverse we used renderings from Zero-1-to-3 which can be downloaded with the follownig command:
```
wget https://tri-ml-public.s3.amazonaws.com/datasets/views_release.tar.gz
```
Disclaimer: note that the renderings are generated with Objaverse. The renderings as a whole are released under the ODC-By 1.0 license. The licenses for the renderings of individual objects are released under the same license creative commons that they are in Objaverse.

Additionally, please download `lvis-annotations-filtered.json` from the [model repository](https://huggingface.co/szymanowiczs/splatter-image-v1/blob/main/lvis-annotations-filtered.json). 
This json which holds the list of IDs of objects from the LVIS subset. These assets are of higher quality.

Set `OBJAVERSE_ROOT` in `datasets/objaverse.py` to the directory of the unzipped folder with renderings, and set `OBJAVERSE_LVIS_ANNOTATION_PATH` in the same file to the directory of the downloaded `.json` file.

Note that Objaverse dataset is meant for training and validation only. It does not have a test subset.

## Google Scanned Objects

For evaluating the model trained on Objaverse we use Google Scanned Objects dataset to ensure no overlap with the training set. Download [renderings provided by Free3D](https://drive.google.com/file/d/1tV-qpiD5e-GzrjW5dQpTRviZa4YV326b/view). Unzip the downloaded folder and set `GSO_ROOT` in `datasets/gso.py` to the directory of the unzipped folder.

Note that Google Scanned Objects dataset is not meant for training. It is used to test the model trained on Objaverse.

# Using this repository

## Pretrained models

Pretrained models for all datasets are now available via [Huggingface Models](https://huggingface.co/szymanowiczs/splatter-image-v1). If you just want to run qualitative / quantitative evaluation, do don't need to dowload them manually, they will be used automatically if you run the evaluation script (see below).

You can also download them manually if you wish to do so, by manually clicking the download button on the [Huggingface model files page](https://huggingface.co/szymanowiczs/splatter-image-v1). Download the config file with it and see `eval.py` for how the model is loaded.

## Config

When training on evaluating on either `hydrants` or `teddybears` from CO3D dataset, please update you `.env` file such that it sets the path to the root of directory which stores the data. For example a `.env` file might look like:
```
CO3D_DATASET_ROOT='/cluster/54/aderylo/workspace/co3d/PREPROCESSED_FOLDER'
```
Previously this was set in the code which made it problematic when pushing code to the common repo. 

## Evaluation

Once you downloaded the relevant dataset, evaluation can be run with 
```
python eval.py $dataset_name
```
`$dataset_name` is the name of the dataset. We support:
- `gso` (Google Scanned Objects), 
- `objaverse` (Objaverse-LVIS), 
- `nmr` (multi-category ShapeNet), 
- `hydrants` (CO3D hydrants), 
- `teddybears` (CO3D teddybears), 
- `cars` (ShapeNet cars), 
- `chairs` (ShapeNet chairs).
The code will automatically download the relevant model for the requested dataset.

You can also train your own models and evaluate it with 
```
python eval.py $dataset_name --experiment_path $experiment_path
```
`$experiment_path` should hold a `model_latest.pth` file and a `.hydra` folder with `config.yaml` inside it.

To evaluate on the validation split, call with option `--split val`.

To save renders of the objects with the camera moving in a loop, call with option `--split vis`. With this option the quantitative scores are not returned since ground truth images are not available in all datasets.

You can set for how many objects to save renders with option `--save_vis`.
You can set where to save the renders with option `--out_folder`.

## Training

Single-view models are trained in two stages, first without LPIPS (most of the training), followed by fine-tuning with LPIPS.
1. The first stage is ran with:
      ```
      python train_network.py +dataset=$dataset_name
      ```
      where $dataset_name is one of [cars,chairs,hydrants,teddybears,nmr,objaverse].
      Once it is completed, place the output directory path in configs/experiment/lpips_$experiment_name.yaml in the option `opt.pretrained_ckpt` (by default set to null).
2. Run second stage with:
      ```
      python train_network.py +dataset=$dataset_name +experiment=$lpips_experiment_name
      ```
      Which `$lpips_experiment_name` to use depends on the dataset.
      If $dataset_name is in [cars,hydrants,teddybears], use lpips_100k.yaml.
      If $dataset_name is chairs, use lpips_200k.yaml.
      If $dataset_name is nmr, use lpips_nmr.yaml.
      If $dataset_name is objaverse, use lpips_objaverse.yaml.
      Remember to place the directory of the model from the first stage in the appropriate .yaml file before launching the second stage.

To train a 2-view model run:
```
python train_network.py +dataset=cars cam_embd=pose_pos data.input_images=2 opt.imgs_per_obj=5
```
### Experiments

In order to reproduce the *semantic embeddings* modification mentioned in the paper one has to run:
```
python train_network.py +dataset=$dataset_name \
model.semantic_context.use=true model.semantic_context.cross_attention_resolutions=[16]
```
And as for the *depth conditioning* one can turn it on via:
```
python train_network.py +dataset=$dataset_name \
model.depth_context.use=true model.depth_context.cross_attention_resolutions=[16]
```
Furthermore, code with experiments on semantic conditioning via embedding concatenation is on the branches `DINO` and `CLIP` and code for reproducing loss schedule experiments is on the branch `var_loss`. 

### Overfiting

Before scheduling a longer training job, it is useful to perform a sanity check to ensure that the model can at least overfit on a single object. To verify this, run the following command on a hydrant dataset as an example:
```
python train_network.py +dataset=hydrants +experiment=overfit.yaml
```
This process takes approximately 8 minutes to complete. However, halfway through, the PSNR score exceeds 22.25 reaching a level that the original model achieves after a week of training on the entire dataset.

## Code structure

Training loop is implemented in `train_network.py` and evaluation code is in `eval.py`. Datasets are implemented in `datasets/srn.py` and `datasets/co3d.py`. Model is implemented in `scene/gaussian_predictor.py`. The call to renderer can be found in `gaussian_renderer/__init__.py`.

## Camera conventions

Gaussian rasterizer assumes row-major order of rigid body transform matrices, i.e. that position vectors are row vectors. It also requires cameras in the COLMAP / OpenCV convention, i.e., that x points right, y down, and z away from the camera (forward).
