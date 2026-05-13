# aSAM/SAM2 Automation Pipeline

HPC-ready automation pipeline for protein conformational ensemble generation using aSAM/SAM2.

This repository streamlines:
- protein preprocessing
- PyMOL cleanup
- ensemble generation
- directory management
- batch execution on HPC systems

Built and tested on [MSU HPCC](https://icer.msu.edu/) environments.

---

# Repository Structure

```text
aSam/
├── asam_ensemble_automation.sh
├── test_1b3/
├── test_in_1b1/
├── test_out_1b1/
└── README.md
```

> The `sam2/` repository is intentionally **not included** and must be cloned separately.

---

# Requirements

## System Requirements

- Linux HPC environment
- CUDA-enabled GPU node
- SLURM (recommended)
- Conda
- PyMOL (CLI-compatible)

---

# Setup

## 1. Clone This Repository

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
```

---

## 2. Clone the SAM2 Repository

Clone the external repository into the project root:

```bash
git clone <SAM2_REPO_URL> sam2
```

Your structure should now look like:

```text
aSam/
├── sam2/
├── asam_ensemble_automation.sh
├── test_1b3/
├── test_in_1b1/
└── test_out_1b1/
```

---

## 3. Create and Activate Environment

Example:

```bash
module load Conda/3
conda create -n asam python=3.10
conda activate asam
```

Install dependencies according to the SAM2 repository instructions.

---

## 4. Configure Python Path

From the project root:

```bash
export PYTHONPATH="$(pwd)/sam2/src:$PYTHONPATH"
```

Optional sanity check:

```bash
python -c "import sam; print('SAM import successful')"
```

---

## 5. Make Script Executable

```bash
chmod +x asam_ensemble_automation.sh
```

---

# Running

## Interactive Test Run

```bash
bash asam_ensemble_automation.sh
```

---

## SLURM Example

```bash
sbatch run_asam.slurm
```

Example SLURM resources:

```bash
#SBATCH --gpus=a100:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=05:00:00
```

---

# Input Preparation

The pipeline automatically:
- loads structures into PyMOL
- removes non-protein atoms
- saves cleaned structures
- launches ensemble generation

Supported input formats:
- `.pdb`

---

# Common Issues

## `ModuleNotFoundError: No module named 'sam'`

Ensure:

```bash
export PYTHONPATH="$(pwd)/sam2/src:$PYTHONPATH"
```

is set before running.

---

## CUDA / GPU Errors

Verify:
- GPU allocation is active
- CUDA version matches PyTorch build
- running on GPU node rather than login node

Useful check:

```bash
nvidia-smi
```

---

## Out-of-Memory (OOM) Errors

Try:
- lowering batch size
- reducing number of conformations
- requesting more memory
- setting the not-minimize flag 
- using H100/H200 nodes if available

---

# Notes

- The external `sam2/` repository is intentionally excluded from version control.
- Generated outputs are not tracked.
- Tested primarily on membrane transport proteins (OATPs).

---

# Acknowledgements

Built around the [aSAM/SAM2](https://github.com/giacomo-janson/sam2) framework and adapted for automated HPC workflows.
