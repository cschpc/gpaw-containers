# gpaw-containers

Building the full thing:
```bash
export APPTAINER_CACHEDIR=$TMPDIR 
apptainer build --fakeroot --bind="$TMPDIR:/tmp" gpaw_cpu.sif gpaw_cpu.def
# On roihu-GPU:
apptainer build --fakeroot --bind="$TMPDIR:/tmp" gpaw_gpu_base.sif gpaw_gpu_base.def
apptainer build --fakeroot --bind="$TMPDIR:/tmp" gpaw_gpu.sif gpaw_gpu_pip.def
```

Developing and testing a container .def in an interactive sandbox:
```bash
sinteractive -g --cores 16 --time 02:00:00
export APPTAINER_CACHEDIR=$TMPDIR
apptainer build --fakeroot --sandbox "$TMPDIR/sandbox" gpaw_gpu_base.def
apptainer shell --fakeroot --contain --writable --cleanenv --bind="$TMPDIR:/tmp" "$TMPDIR/sandbox"
# alternatively: build a sensible starting .sif, then build a sandbox on top of it
```
The `--contain` flag tells apptainer to use a "fake" home dir under `/users` instead of binding the real home.
It's very small in size so don't try to install anything there (use `/opt`).
