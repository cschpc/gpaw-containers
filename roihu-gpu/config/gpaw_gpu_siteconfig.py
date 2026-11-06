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
    '-g',
    '-mcpu=grace',  # Pretty much the same as -mcpu=neoverse-v2
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

gpu = True
gpu_target = 'cuda'
gpu_compiler = 'nvcc'
gpu_compile_args = [
                    '-forward-unknown-opts',
                    '-O3',
                    '-g',
                    '-Wall',
                    '-fPIC',
                    '-arch=sm_90a',
                    '-mcpu=grace'
                    ]
libraries += ['cudart', 'cublas']
