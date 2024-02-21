#!/bin/bash
set -eu

module load StdEnv/2020 apptainer/1.1.8

OUTDIR=${1}
# receive all directories, and index them per job array
HEURISTICFILE=${2}
DCMDIRS=("${@:3}")
DCMDIR=${DCMDIRS[${SLURM_ARRAY_TASK_ID}]}


SUBJECT_NUMBER=${DCMDIR##*/sub-}
SUBJECT_NUMBER=${SUBJECT_NUMBER%%/*}
echo "Subject Number: $SUBJECT_NUMBER"

# Extract the session number from the DCMDIR variable
SESSION_NUMBER=${DCMDIR##*/ses-}
SESSION_NUMBER=${SESSION_NUMBER%%/*}
echo "Session Number: $SESSION_NUMBER"

# extract from archive
# Use a wildcard to find the tar.gz file and extract it
echo "Extracting dicom archive..."
tar -xzvf "${DCMDIR}/sub-${SUBJECT_NUMBER}_ses-${SESSION_NUMBER}_dicom.tar.gz" -C $SLURM_TMPDIR/ #"${DCMDIR}"
#find "${DCMDIR}" -type d -name 'DICOM' -exec mv {} "${DCMDIR}/" \;
find $SLURM_TMPDIR -type d -name 'DICOM' -exec rsync -rv {} "${DCMDIR}/" \;

echo Submitted directory: ${DCMDIR}

IMG="${HOME}/projects/def-patricia/containers/heudiconv-latest-dev.sif"

HEURISTICDIR=$(dirname "${HEURISTICFILE}")

# additional params to dcm2niix, create the JSON file dynamically
JSON_FILE="${HEURISTICDIR}/dcm2niix_config.json"

# echo '{
#   "d": 9,
# }' > "$JSON_FILE"

CMD="singularity run -B ${DCMDIR}:/dicoms -B ${OUTDIR}:/output -B ${HEURISTICFILE}:/heuristics_proventure.py:ro -B ${HEURISTICDIR}/dcm2niix_config.json:/dcm2niix_config.json:ro --no-home ${IMG} --files /dicoms/ -o /output -f /heuristics_proventure.py  -c dcm2niix  --overwrite --grouping all -b notop --minmeta -l . -s ${SUBJECT_NUMBER} -ss ${SESSION_NUMBER}}" # --dcmconfig /dcm2niix_config.json

printf "Command:\n${CMD}\n"
${CMD}
echo "Successful process. Data is stored at ${OUTDIR}. Removing decompressed data."

# Remove the 'localscratch' folder while keeping the compressed folder
rm -rfv "${DCMDIR}/DICOM"
rm -rfv "${DCMDIR}/scratch"

