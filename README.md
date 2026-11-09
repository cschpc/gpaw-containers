# gpaw-containers

Build recipes for containerized GPAW installations for Roihu.

## Build and test

Use one of the batch job scripts to build the container(s):
- [Roihu-CPU](roihu-cpu/build.job)
- [Roihu-GPU](roihu-gpu/build.job)

Alternatively, you can use [this script](build_and_test.sh) to submit the build job and run GPAW test suite on it afterwards.
You need to be on a CPU login node to use it for Roihu-CPU, and vice versa for GPU. Consider running it in a `tmux` session or similar.

## Developing in a sandbox

Developing and testing a container `.def` in an interactive sandbox:
```bash
sinteractive -g --cores 16 --time 02:00:00
export APPTAINER_CACHEDIR=$TMPDIR
apptainer build --fakeroot --sandbox "$TMPDIR/sandbox" gpaw_gpu_base.def
apptainer shell --fakeroot --contain --writable --cleanenv --bind="$TMPDIR:/tmp" "$TMPDIR/sandbox"
# alternatively: build a sensible starting .sif, then build a sandbox on top of it
```
The `--contain` flag tells apptainer to use a "fake" home dir under `/users` instead of binding the real home.
It's very small in size so don't try to install anything there (use `/opt`).
