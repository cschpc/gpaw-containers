#!/bin/bash
# Full Roihu pipeline: build the container, create Tykky wrappers, smoke-test, run the test suite.
# Usage: ./run_pipeline.sh <cpu|gpu> [SLURM_ACCOUNT]
# The SLURM account can also be provided via the SLURM_ACCOUNT environment variable.
# Platform-specific steps (build.job, run_tests.sh) live under roihu-cpu/ and roihu-gpu/.

# Will wrap this directory inside the container with Tykky
TYKKY_WRAP_DIR=/gpaw_container/tykky_wrap/bin

set -euo pipefail

PLATFORM=${1:-}
if [[ "$PLATFORM" != "cpu" && "$PLATFORM" != "gpu" ]]; then
    echo "Usage: $0 <cpu|gpu> [SLURM_ACCOUNT]" >&2
    exit 1
fi
shift

SLURM_ACCOUNT=${1:-${SLURM_ACCOUNT:-}}
if [[ -z "$SLURM_ACCOUNT" ]]; then
    echo "Warning: No SLURM account specified. Pass it as the second argument or set \$SLURM_ACCOUNT." >&2
fi
ACCOUNT_FLAG=()
[[ -n "$SLURM_ACCOUNT" ]] && ACCOUNT_FLAG=(--account="$SLURM_ACCOUNT")

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/roihu-$PLATFORM"

SIF=$PWD/gpaw_$PLATFORM.sif
WRAPPER_DIR=$PWD/wrappers_$PLATFORM/tester

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
wrap-container -w $TYKKY_WRAP_DIR "$SIF" --prefix "$WRAPPER_DIR"
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
smoke_test python -c "import tkinter"
# Check DFT4-Python-ASE bindings
smoke_test python -c "import dftd4; from dftd4.ase import DFTD4; print(f'DFTD4 {dftd4.__version__}')"

echo "==> Submitting test suite."
./run_tests.sh "$SLURM_ACCOUNT"
