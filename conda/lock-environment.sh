#!/usr/bin/env bash
# This script will re-generate reproducible lockfiles
# Execution needs to be from inside the `conda` folder

ENV_FILE="environment.yml"
LOCK_ENV='CondaLock'

check_success() {
  if [[ $1 -ne 0 ]]; then
    printf "\033[1;31m ERROR \033[0m "
    printf "$2\n"
    exit 1
  else
    printf "\033[1;32m SUCCESS \033[0m "
    printf "$2\n"
  fi
}

# Generate CondaLock environment unless present
conda env list | grep ${LOCK_ENV} > /dev/null

if [[ $? -eq 1 ]]; then
  conda create -q -y -n ${LOCK_ENV} -c conda-forge python=3.10 conda-lock=2.1.2 mamba=1.4.9
fi

# https://github.com/conda/conda/issues/7980#issuecomment-492784093
eval "$(conda shell.bash hook)"
conda activate ${LOCK_ENV}

if [[ ! -s "${ENV_FILE}" ]]; then
    >&2 printf " Missing ${ENV_FILE} to generate environments with\n"
    >&2 printf " Are you inside the 'conda' folder?\n"
    exit 1
fi

# https://github.com/conda/conda-lock/issues/196
rm *lock.yml

# Local environments
## Generate explicit lock files
conda-lock lock --mamba -f ${ENV_FILE}
lock_success=$?
check_success lock_success "  Building local environments"

# Remove CondaLock environment when the last command was successful
if [[ lock_success -eq 0 ]]; then
  conda deactivate
  conda remove -q -y --name ${LOCK_ENV} --all
fi
