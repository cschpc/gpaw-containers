#!/bin/bash
# Runs GPAW test suite. Run this script on Roihu-CPU login node.
# Usage: ./run_tests.sh [SLURM_ACCOUNT]
# The SLURM account can also be provided via the SLURM_ACCOUNT environment variable.

set -euo pipefail

# Needed if doing `python -m pytest ...` instead of using `gpaw python`
export GPAW_MPI_BACKEND=cgpaw

SLURM_ACCOUNT=${1:-${SLURM_ACCOUNT:-}}
if [[ -z "$SLURM_ACCOUNT" ]]; then
    echo "Warning: No SLURM account specified. Pass it as the first argument or set \$SLURM_ACCOUNT." >&2
fi
ACCOUNT_FLAG=""
[[ -n "$SLURM_ACCOUNT" ]] && ACCOUNT_FLAG="-A $SLURM_ACCOUNT"

GPAW_TAG=26.7.0

# GPAW installation doesn't ship properly packaged unit tests.
# Workaround: clone the repo at the correct release tag and run tests from there.
TEST_RUNS_DIR=$PWD/testruns_cpu
mkdir -p "$TEST_RUNS_DIR"
cd "$TEST_RUNS_DIR"

if [[ ! -d gpaw ]]; then
    git clone --depth 1 -b "$GPAW_TAG" https://gitlab.com/gpaw/gpaw.git
fi

export GPAW_HOME=$PWD/gpaw
cd ..

PYTEST_CACHE=$TEST_RUNS_DIR/pytest_cache

BIND_ARGS=$(csc-common-bind)

# Generate GPW files and capture its job ID (dependency for full test runs)
GPWJOB=$(sbatch --parsable -p small -t 00:30:00 --nodes=1 --ntasks-per-node=1 --mem-per-cpu=4G \
    $ACCOUNT_FLAG -J gpwfiles -o "$TEST_RUNS_DIR/%x.out" << EOF
#!/bin/bash
srun apptainer run --bind="$BIND_ARGS" gpaw_cpu.sif bash -c '
    cd \$GPAW_HOME
    python -m pytest -v -o cache_dir=\$PYTEST_CACHE \$GPAW_HOME/gpaw/test/test_generate_gpwfiles.py
'
EOF
)
echo "Submitted GPW file generation job: $GPWJOB"

# Submit full test suite run with n MPI tasks, held until the GPW job succeeds
submit_test_job() {
    local n=$1
    sbatch -p small --nodes=1 --ntasks-per-node="$n" --mem-per-cpu=4G -t 04:00:00 \
        $ACCOUNT_FLAG -J "pytest-cpu-$n" -o "$TEST_RUNS_DIR/%x.out" \
        --dependency=afterok:"$GPWJOB" << EOF
#!/bin/bash
srun apptainer run --bind="$BIND_ARGS" gpaw_cpu.sif bash -c '
    cd \$GPAW_HOME
    python -m pytest -v -o cache_dir=\$PYTEST_CACHE \$GPAW_HOME/gpaw/test
'
EOF
}

for n in 1 2 4 8; do
    submit_test_job "$n"
done
