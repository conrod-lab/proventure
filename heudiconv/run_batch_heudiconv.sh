#!/bin/bash

set -eu

# Change this to where you git cloned the project proventure:
PROJECT_HOME=/home/${USER}/project/${USER}
# where the DICOMs are located
DCMROOT=$HOME/projects/def-patricia/data/proventure/sourcedata/dicoms

# Change this to where you want your slurm outputs to go
LOG_OUTPUT=$SCRATCH/proventure/raw/tmp/output

# Output of conversion
OUTPUT=$SCRATCH/proventure/raw/bids

# This is what you change to grab a subject you want for a specific session
#subject_session_to_filter=("sub-020/ses-01" "sub-028/ses-01" "sub-029/ses-01" "sub-030/ses-01" "sub-033/ses-02" "sub-052/ses-03" "sub-069/ses-01" "sub-072/ses-01" "sub-073/ses-03" "sub-074/ses-02" "sub-079/ses-02" "sub-086/ses-01" "sub-090/ses-01" "sub-153/ses-01")
# Specify heuristics file (if you are using dcm2niix_config, put it in the same directory)
HEURISTICFILE="$PROJECT_HOME/proventure/heudiconv/heuristics_proventure.py"

HEUDICONV_FOLDER="$OUTPUT/.heudiconv"

# Check if the .heudiconv folder exists
if [ -d "$HEUDICONV_FOLDER" ]; then
    echo "Removing .heudiconv folder from $OUTPUT"
    rm -r "$HEUDICONV_FOLDER"
else
    echo "No .heudiconv folder found in $OUTPUT"
fi


## The rest of the code is static


# single subject test
#DCMROOT=/scratch/spinney/proventure/raw/dicoms_clean
# where we want to output the data

# find all DICOM directories
#DCMDIRS=( $(find ${DCMROOT} -maxdepth 2 -type d -name "ses-*" ) )
filtered_paths=( $(find ${DCMROOT} -maxdepth 2 -type d -name "ses-*" ) )

# Array to store filtered paths
#filtered_paths=()

# Loop through the array of paths
# for path in "${DCMDIRS[@]}"; do
#   # Extract the subject_session from the path
#   subject_session=$(echo "$path" | grep -oP 'sub-\d+/ses-\d+')

#   # Check if the subject_session is in the list to be filtered
#   if [[ " ${subject_session_to_filter[@]} " =~ " ${subject_session} " ]]; then
#     filtered_paths+=("$path")
#   fi
# done

# Print the filtered paths
for path in "${filtered_paths[@]}"; do
  echo "$path"
done

#More ressources
sbatch --array=0-`expr ${#filtered_paths[@]} - 1`%100 \
       --cpus-per-task=1 \
       --mem=2GB \
       --output=${LOG_OUTPUT}/heudiconv/heudiconv_%A_%a.out \
       --error=${LOG_OUTPUT}/heudiconv/heudiconv_%A_%a.err \
       $PROJECT_HOME/proventure/heudiconv/run_heudiconv.sh ${OUTPUT} ${HEURISTICFILE} ${filtered_paths[@]} 

