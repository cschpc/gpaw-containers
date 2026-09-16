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
    '-fopenmp',
    '-Wall',
    '-Wno-unused-parameter',
]

libraries += ['xc', 'openblas']

with_omp = True
if with_omp:
    extra_compile_args += ['-fopenmp']
    extra_link_args = ['-fopenmp']

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
    # elpa headers have messed up directory structure
    include_dirs += ['/opt/views/gpaw_deps/include/elpa_openmp-2026.02.002']

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
                    ]
libraries += ['cudart', 'cublas']
