from setuptools_scm import get_version
from setuptools import Extension, setup
from Cython.Build import cythonize
import pathlib
HERE = pathlib.Path(__file__).parent

version = get_version()
(HERE / 'src/_version.py').write_text(f'__version__="{version}"')

ext = Extension("mikktspace",
                sources=[
                    "src/_version.py",
                    "src/mikktspace.pyx", "MikkTSpace/mikktspace.c"
                ],
                include_dirs=[str(HERE)],
                )

setup(
    name='pymikktspace',
    version=version,
    description='mikktspace',
    author='ousttrue',
    author_email='ousttrue@gmail.com',
    url='https://github.com/ousttrue/pymikktspace',
    ext_modules=cythonize(ext))
