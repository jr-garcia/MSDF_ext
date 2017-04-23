# coding=utf-8
from setuptools import setup, Extension
from sys import platform
import os

incl = ['./msdf/msdfgen', './msdf/msdfgen/include', './msdf/msdfgen/include/freetype']
extrac = []
sourceFiles = ["msdf/gen.pyx"]

ignoredSources = ['save-bmp.cpp', 'render-sdf.cpp', 'import-svg.cpp']

if platform == 'win32':
    rldirs = []
    extrac.extend(['/EHsc', '/openmp'])
    extraArgs = ['/openmp']
elif platform == 'darwin':
    rldirs = []
    extrac.append('-fopenmp')
    extraArgs = ['-fopenmp']
else:
    extraArgs = ['-fopenmp']
    rldirs = ["$ORIGIN"]
    extrac.extend(["-w", "-O3", '-fopenmp'])


def addValidSources(loc):
    global sourceFiles
    for file in os.listdir(loc):
        if file in ignoredSources:
            continue
        filepath = os.path.abspath(os.path.join(loc, file))
        if os.path.isfile(filepath):
            if os.path.splitext(filepath)[1] == '.cpp':
                sourceFiles.append(filepath)
    return


def getSourceFiles():
    addValidSources('./msdf/msdfgen/core')
    addValidSources('./msdf/msdfgen/ext')
    addValidSources('./msdf/msdfgen/lib')
    return sourceFiles


setup(ext_modules=[Extension('msdf.gen', getSourceFiles(), include_dirs=incl,
                             extra_link_args=extraArgs, extra_compile_args=extrac,
                             libraries=['freetype'], language="c++")],
        name='MSDF_ext',
        version='0.1',
        packages=['msdf'],
        url='',
        license='MIT',
        author='JR-García',
        author_email='biocratos@yahoo.com.mx',
        description='Basic bindings for Multichannel signed distance field generator',
        install_requires=['cython'])
