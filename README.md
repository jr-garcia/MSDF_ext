# MSDF_ext
Basic Python bindings for [Multi-channel signed distance field generator ](https://github.com/Chlumsky/msdfgen)

## Install
This proyect uses submodules, so clone like this:

```sh
git clone --recursive https://github.com/jr-garcia/MSDF_ext.git
```

It also needs Cython and [Freetype](https://www.freetype.org/) development library. Install it and then do

```sh
python setup.py install

```
It should compile and install.

---
Multi-channel signed distance field generator is licensed under MIT. Please read msdf/msdfgen/LICENSE.txt for details.
