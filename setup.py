from setuptools import Extension, setup
from Cython.Build import cythonize
import pathlib
HERE = pathlib.Path(__file__).parent


ext = Extension('mikktspace.mikktspace_c',
                sources=[
                    'src/mikktspace/mikktspace_c/mikktspace.pyx',
                    '_external/MikkTSpace/mikktspace.c'
                ],
                include_dirs=[str(HERE / '_external/MikkTSpace')],
                # language='c++',
                )

setup(
    name='pymikktspace',
    description='mikktspace',
    author='ousttrue',
    author_email='ousttrue@gmail.com',
    url='https://github.com/ousttrue/pymikktspace',
    package_dir={'': 'src'},
    include_package_data=True,
    packages=[
        'mikktspace',
        'mikktspace.mikktspace_c',
    ],
    ext_modules=cythonize(ext, compiler_directives={'language_level': '3'})
)
