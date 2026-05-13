#!/bin/bash --login
#SBATCH --job-name=asam
#SBATCH --time=05:00:00
#SBATCH --gpus=a100:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --output=/path/to/root/aSam/logs/%x_%A_%a.out
#SBATCH --error=/path/to/root/aSam/logs/%x_%A_%a.err
#SBATCH --array=1-N


# -e exit immediately if a command fails
# -u treat unset variables as an error
# -o pipefail if any part of a pipe fails
set -euo pipefail

module purge
module load CUDA/12.1.1

# activate conda env (located env on your system)
source $(conda info --base)/etc/profile.d/conda.sh
conda activate asam

#---- Base Directories ----#
# root of repo
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ASAM_PERSONAL_DIR=${REPO_ROOT}

# CHANGE ME! #
# should point to your scratch directory where outputs and tmp directories will be located (Could be the same as above. Distinguish for organization purposes.)
export ASAM_SCRATCH_DIR=/path/to/some/scratch/directory

# RUN LABEL. CHANGE THIS FOR EACH RUN TO KEEP OUTPUTS ORGANIZED!
# e.g. 1b3_atlas OR 1b3_mdcath, etc.
RUN_LABEL="test3"

export ASAM_INPUT_DIR=${REPO_ROOT}
export ASAM_OUTPUT_DIR="${ASAM_SCRATCH_DIR}/outputs/${RUN_LABEL}"

# Note: if you encounter errors, these directories are helpful directories to visit in order to read the error logs
mkdir -p "${ASAM_INPUT_DIR}" "${ASAM_OUTPUT_DIR}" "${ASAM_SCRATCH_DIR}/logs" "${ASAM_SCRATCH_DIR}/tmp"

shopt -s nullglob
mapfile -t PDB_FILES < <(find "${ASAM_INPUT_DIR}/test_1b3" -name "*.pdb" | sort)
shopt -u nullglob

TMP_OUTPUT_DIR="${ASAM_INPUT_DIR}/sam2/examples/OATP_input"

# clean up cryo protein structure from non-protein ligands
for pdb in "$PDB_FILES"; do
    filename=$(basename "$pdb")

    pymol -cq "$pdb" -d "
    load $pdb, prot
    remove not polymer.protein
    save ${TMP_OUTPUT_DIR}/$filename, prot
    quit
    "

    echo "processed $filename"
done

shopt -s nullglob
mapfile -t NEW_PDB_FILES < <(find "${TMP_OUTPUT_DIR}" -name "*.pdb" | sort)
shopt -u nullglob

# --- uses SLURM TASK ID. Can only be used on a HPC cluster. (comment out if testing locally!!) --- #
# INDEX=$((SLURM_ARRAY_TASK_ID - 1))
# TOTAL_FILES=${#NEW_PDB_FILES[@]}
# if [[ "$INDEX" -ge "$TOTAL_FILES" ]]; then
#     echo "ERROR: SLURM index $SLURM_ARRAY_TASK_ID exceeds the total number of .FASTA files $TOTAL_FILES"
#     exit 1
# fi

# --- TESTING PURPOSE (uncomment and set a hard-coded index number to run the script locally) --- #
INDEX=3

# index into the pdb files directory and get the requested pdb file
PDB_FILE="${NEW_PDB_FILES[$INDEX]}"

# check if the pdb file exists
if [[ ! -f "${PDB_FILE}" ]]; then
    echo "ERROR: .PDB file not found. Please check your input directory"
    exit 1
fi


# create job tags from filenames
job_tag="$(basename "$PDB_FILE" .pdb)"
mkdir -p "${ASAM_OUTPUT_DIR}"
out_host="${ASAM_OUTPUT_DIR}/${job_tag}"


# generate ensembles
python sam2/src/sam/scripts/generate_ensemble.py \
 --no_minimize \
 -c sam2/config/atlas_model.yaml \
 -i "$PDB_FILE" \
 -o "${out_host}"\
 -n 1 \
 -b 1 \
 -d cuda