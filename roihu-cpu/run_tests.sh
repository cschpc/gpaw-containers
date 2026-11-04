#!/bin/bash
# Runs GPAW test suite on Tykky-wrapped container. This assumes you have the wrappers bin directory in PATH.
# Usage: ./run_tests.sh [SLURM_ACCOUNT]
# The SLURM account can also be provided via the SLURM_ACCOUNT environment variable.

set -euo pipefail

# This is a bit messy because GPAW's parallel launcher is broken. Setting GPAW_MPI_BACKEND=cgpaw seems to be broken,
# so we have to use `srun gpaw python` which _naturally_ doesn't work with ntasks==1.


SLURM_ACCOUNT=${1:-${SLURM_ACCOUNT:-}}
if [[ -z "$SLURM_ACCOUNT" ]]; then
    echo "Warning: No SLURM account specified. Pass it as the first argument or set \$SLURM_ACCOUNT." >&2
fi
ACCOUNT_FLAG=""
[[ -n "$SLURM_ACCOUNT" ]] && ACCOUNT_FLAG="-A $SLURM_ACCOUNT"

export TEST_RUNS_DIR=$PWD/testruns_cpu
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

# Generate GPW files and capture its job ID (dependency for full test runs). Takes ~13mins.
# This is mostly no-op if the GPW files have already been cached. Clear PYTEST_CACHE directory if you need to force recomputation
GPWJOB=$(sbatch --parsable -p small -t 00:30:00 --nodes=1 --ntasks-per-node=1 --mem-per-cpu=4G \
    $ACCOUNT_FLAG -J gpwfiles -o "$TEST_RUNS_DIR/%x.out" << EOF
#!/bin/bash
cd \$GPAW_HOME
python -m pytest -v --import-mode=importlib -o cache_dir=\$PYTEST_CACHE \$GPAW_TESTDIR/test_generate_gpwfiles.py
EOF
)
echo "Submitted GPW file generation job: $GPWJOB"


### FOR REFERENCE: A "raw" version of the above that does not use Tykky wrappers:

# BIND_ARGS=$(csc-common-bind)
# GPWJOB=$(sbatch --parsable -p small -t 00:30:00 --nodes=1 --ntasks-per-node=1 --mem-per-cpu=4G \
#     $ACCOUNT_FLAG -J gpwfiles -o "$TEST_RUNS_DIR/%x.out" << EOF
# #!/bin/bash
# srun apptainer run --bind="$BIND_ARGS" gpaw_cpu.sif bash -c '
#     cd \$GPAW_HOME
#     python -m pytest -v -o cache_dir=\$PYTEST_CACHE \$GPAW_HOME/gpaw/test/test_generate_gpwfiles.py
# '
# EOF
# )

###


# Ignore tests that are known to fail for GPAW 26.7
# Single-quoted (and array, not string) so that $GPAW_TESTDIR expands inside the job script, not here.
IGNORE_FLAGS=(
    '--ignore=$GPAW_TESTDIR/test_mpi_enabledness.py'
    '--ignore=$GPAW_TESTDIR/lrtddft/test_placzek_profeta_albrecht.py'
    '--ignore=$GPAW_TESTDIR/sjm/test_cavitylike.py'
    '--ignore=$GPAW_TESTDIR/etdm/test_etdm_er_localize.py'
    '--ignore=$GPAW_TESTDIR/elph/test_supercell.py'
    '--ignore=$GPAW_TESTDIR/xc/test_lxc_fhc.py'
    # Fails due to tolerances?
    '--ignore=$GPAW_TESTDIR/tddft/test_molecule.py::test_dipole_moment_values'
    '--ignore=$GPAW_TESTDIR/test_d3_extension.py::test_d3_extensions[mode0-parallel1]'
    '--ignore=$GPAW_TESTDIR/test_d3_extension.py::test_d3_extensions[mode0-parallel2]'
)

# Submit full test suite run with n MPI tasks, held until the GPW job succeeds
submit_test_job() {
    local n=$1
    local mem launcher
    if [[ "$n" -eq 1 ]]; then
        mem=8G
        launcher="python"
    else
        mem=4G
        launcher="srun gpaw python"
    fi
    sbatch -p small --nodes=1 --ntasks-per-node="$n" --mem-per-cpu="$mem" -t 04:00:00 \
        $ACCOUNT_FLAG -J "pytest-cpu-$n" -o "$TEST_RUNS_DIR/%x.out" \
        --dependency=afterok:"$GPWJOB" << EOF
#!/bin/bash
cd \$GPAW_HOME
$launcher -m pytest -v --import-mode=importlib -o cache_dir=\$PYTEST_CACHE \$GPAW_TESTDIR ${IGNORE_FLAGS[@]}
EOF
}

for n in 1 2 4 8; do
    submit_test_job "$n"
done
