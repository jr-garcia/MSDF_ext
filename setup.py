# coding=utf-8
from setuptools import setup, Extension
from sys import platform
import os

incl = ['./msdf/msdfgen', './msdf/msdfgen/include', './msdf/msdfgen/include/freetype']
extraComp = []
sourceFiles = ["msdf/gen.pyx"]

ignoredSources = ['save-bmp.cpp', 'render-sdf.cpp', 'import-svg.cpp']

if platform == 'win32':
    rldirs = []
    extraComp.extend(['/EHsc', '/openmp'])
    extraLink = []
elif platform == 'darwin':
    rldirs = []
    extraComp.append('-fopenmp')
    extraLink = ['-fopenmp']
else:
    extraLink = ['-fopenmp']
    rldirs = ["$ORIGIN"]
    extraComp.extend(["-w", "-O3", '-fopenmp'])


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
                             extra_link_args=extraLink, extra_compile_args=extraComp,
                             libraries=['freetype'], language="c++")],
        name='MSDF_ext',
        version='0.1',
        packages=['msdf'],
        url='',
        license='MIT',
        author='JR-García',
        author_email='biocratos@yahoo.com.mx',
        description='Basic bindings for Multichannel signed distance field generator',
        # install_requires=['cython']
      )
