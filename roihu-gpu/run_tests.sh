#!/bin/bash
# Runs GPAW test suite on Tykky-wrapped container. This assumes you have the wrappers bin directory in PATH.
# Usage: ./run_tests.sh [SLURM_ACCOUNT]
# The SLURM account can also be provided via the SLURM_ACCOUNT environment variable.

set -euo pipefail

SLURM_ACCOUNT=${1:-${SLURM_ACCOUNT:-}}
if [[ -z "$SLURM_ACCOUNT" ]]; then
    echo "Warning: No SLURM account specified. Pass it as the first argument or set \$SLURM_ACCOUNT." >&2
fi
ACCOUNT_FLAG=""
[[ -n "$SLURM_ACCOUNT" ]] && ACCOUNT_FLAG="-A $SLURM_ACCOUNT"

export TEST_RUNS_DIR=$PWD/testruns
mkdir -p "$TEST_RUNS_DIR"
cd "$TEST_RUNS_DIR"

# GPAW installation doesn't ship properly packaged unit tests.
# Workaround: clone the repo at the correct release tag and run tests from there.
# For pytest we need --import-mode=importlib to prevent issues with conftest import
GPAW_TAG=26.7.0
if [[ ! -d gpaw ]]; then
    git clone --depth 1 -b "$GPAW_TAG" https://gitlab.com/gpaw/gpaw.git
fi

export GPAW_HOME=$PWD/gpaw
export GPAW_TESTDIR=$GPAW_HOME/gpaw/test
cd ..

export PYTEST_CACHE=$TEST_RUNS_DIR/pytest_cache

# No GPW files needed for "-m gpu" tests

# Ignore tests that are known to fail for GPAW 26.7
IGNORE_FLAGS=(
)

submit_test_job() {
    local n=$1
    local launcher
    if [[ "$n" -eq 1 ]]; then
        launcher="python"
    else
        launcher="srun gpaw python"
    fi
    sbatch -p gpumedium --nodes=1 --ntasks-per-node="$n" --gres=gpu:gh200:"$n" -t 04:00:00 \
        $ACCOUNT_FLAG -J "pytest-$n" -o "$TEST_RUNS_DIR/%x.out" << EOF
#!/bin/bash
cd \$GPAW_HOME
$launcher -m pytest -v --import-mode=importlib -o cache_dir=\$PYTEST_CACHE \$GPAW_TESTDIR ${IGNORE_FLAGS[@]}
EOF
}

for n in 1 2 4; do
    submit_test_job "$n"
done
