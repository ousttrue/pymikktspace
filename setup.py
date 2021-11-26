from setuptools import Extension, setup
from Cython.Build import cythonize
import pathlib
HERE = pathlib.Path(__file__).parent

ext = Extension("mikktspace",
                sources=[
                    "src/mikktspace.pyx", "MikkTSpace/mikktspace.c"
                ],
                include_dirs=[str(HERE)],
                )

setup(
    name='pymikktspace',
    version='0.1.0',
    description='mikktspace',
    author='ousttrue',
    author_email='ousttrue@gmail.com',
    url='https://github.com/ousttrue/pymikktspace',
    ext_modules=cythonize(ext))
