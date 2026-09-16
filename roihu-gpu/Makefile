BUILDER  ?= apptainer
BUILDFLAGS := --fakeroot --bind="$(TMPDIR):/tmp"

# These containers must be built on an ARM system, preferably on Roihu-GPU directly

.PHONY: _no_default gpaw_gpu

_no_default:
	@echo "Specify a target: gpaw_gpu"
	@echo "Note: if building on Roihu, make sure to set:"
	@echo "export APPTAINER_CACHEDIR=$TMPDIR"
	@false

gpaw_gpu: gpaw_gpu.sif

gpaw_gpu.sif: gpaw_gpu.def
	$(BUILDER) build $(BUILDFLAGS) $@ $<

clean:
	rm -f *.sif
