mpi = True
compiler = 'mpicxx'

libraries = []
extra_compile_args = []
library_dirs = []
runtime_library_dirs = []
include_dirs = []

extra_compile_args = [
    '-fPIC',
    '-O3',
    '-march=znver5',
    '-g',
    '-Wall',
    '-Wno-unused-parameter',
]

with_omp = True
if with_omp:
    extra_compile_args += ['-fopenmp']
    extra_link_args = ['-fopenmp']

# Build without a BLAS library?
noblas = False
if not noblas:
    libraries += ['openblas']

# Build without Libxc?
nolibxc = False
if not nolibxc:
    libraries += ['xc']

fftw = True
if fftw:
    libraries += ['fftw3']

scalapack = True
if scalapack:
    libraries += ['scalapack']

libvdwxc = True
if libvdwxc:
    libraries += ['vdwxc']

elpa = True
if elpa:
    libraries += ['elpa_openmp']
