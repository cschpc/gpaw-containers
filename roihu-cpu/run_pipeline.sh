#!/bin/bash
# Full Roihu-CPU pipeline: build containers, create Tykky wrappers, run the test suite.
# Usage: ./run_pipeline.sh [SLURM_ACCOUNT]
# The SLURM account can also be provided via the SLURM_ACCOUNT environment variable.

set -euo pipefail

SLURM_ACCOUNT=${1:-${SLURM_ACCOUNT:-}}
if [[ -z "$SLURM_ACCOUNT" ]]; then
    echo "Warning: No SLURM account specified. Pass it as the first argument or set \$SLURM_ACCOUNT." >&2
fi
ACCOUNT_FLAG=()
[[ -n "$SLURM_ACCOUNT" ]] && ACCOUNT_FLAG=(--account="$SLURM_ACCOUNT")

WRAPPER_DIR=$PWD/wrappers_cpu/tester

# Run a command, exiting with an error message if it fails.
run_step() {
    local description=$1
    shift
    echo "==> $description..."
    if ! "$@"; then
        echo "ERROR: $description failed." >&2
        exit 1
    fi
    echo "==> $description: done."
}

run_step "Building the container (build.job)" sbatch --wait "${ACCOUNT_FLAG[@]}" build.job

echo "==> Creating Tykky wrappers in $WRAPPER_DIR..."
ml tykky
SIF=$PWD/gpaw_cpu.sif
wrap-container -w /opt/tykky_wrap/bin $SIF --prefix $WRAPPER_DIR
echo "==> Wrappers created."

export PATH="$WRAPPER_DIR/bin:$PATH"

# Test that trivial things work
smoke_test() {
    echo "==> Smoke-testing: $*"
    if ! "$@"; then
        echo "ERROR: smoke test failed: $*" >&2
        exit 1
    fi
}

smoke_test gpaw info
smoke_test ase -h
# Check DFT4-Python-ASE bindings
smoke_test python -c "import dftd4; from dftd4.ase import DFTD4; print(f'DFTD4 {dftd4.__version__}')"

echo "==> Submitting test suite."
./run_tests.sh "$SLURM_ACCOUNT"
