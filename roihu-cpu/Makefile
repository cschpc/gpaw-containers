BUILDER  ?= apptainer
BUILDFLAGS := --fakeroot --bind="$(TMPDIR):/tmp"

# These containers must be built on an x86_64 system. Binaries will be built for zen5

.PHONY: _no_default gpaw_deps gpaw_dev gpaw_release clean

_no_default:
	@echo "Specify a target: gpaw_deps_cpu
	@echo "Note: if building on Roihu, make sure to set:"
	@echo "export APPTAINER_CACHEDIR=$TMPDIR"
	@false

gpaw_deps_cpu: gpaw_deps_cpu.sif

gpaw_deps_cpu.sif: gpaw_deps_cpu.def
	$(BUILDER) build $(BUILDFLAGS) $@ $<

clean:
	rm -f *.sif
