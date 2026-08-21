BUILDER  ?= apptainer
BUILDFLAGS := --fakeroot --bind="$(TMPDIR):/tmp"

# These containers must be built on an ARM system, preferably on Roihu-GPU directly

.PHONY: _no_default gpaw_deps gpaw_dev gpaw_release clean

_no_default:
	@echo "Specify a target: gpaw_deps, gpaw_dev, gpaw_release"
	@echo "Note: if building on Roihu, make sure to set:"
	@echo "export APPTAINER_CACHEDIR=$TMPDIR"
	@false

gpaw_deps: gpaw_deps.sif
gpaw_dev:  gpaw_dev.sif
gpaw_release: gpaw_release.sif

gpaw_deps.sif: gpaw_deps.def
	$(BUILDER) build $(BUILDFLAGS) $@ $<

gpaw_dev.sif: gpaw_dev.def gpaw_deps.sif
	$(BUILDER) build $(BUILDFLAGS) $@ $<

gpaw_release.sif: gpaw_release.def gpaw_deps.sif
	$(BUILDER) build $(BUILDFLAGS) $@ $<

clean:
	rm -f *.sif
