#!/bin/bash
# Inspired by https://github.com/apache/arrow/blob/master/python/examples/minimal_build/build_venv.sh

set -eux

WORKDIR=/tmp
LIBRARY_INSTALL_DIR=$WORKDIR/local-libs
CPP_BUILD_DIR=$WORKDIR/arrow-cpp-build
ARROW_ROOT=$WORKDIR/arrow
export ARROW_HOME=$WORKDIR/dist
export LD_LIBRARY_PATH=$ARROW_HOME/lib:$LD_LIBRARY_PATH

pip install -r $ARROW_ROOT/python/requirements-build.txt \
     -r $ARROW_ROOT/python/requirements-test.txt

mkdir -p $CPP_BUILD_DIR
pushd $CPP_BUILD_DIR

cmake \
        -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
        -DARROW_SKYHOOK=ON \
        -DARROW_PARQUET=ON \
        -DARROW_WITH_SNAPPY=ON \
        -DARROW_WITH_ZLIB=ON \
        -DARROW_WITH_LZ4=ON \
        -DARROW_DATASET=ON \
        -DARROW_PYTHON=ON \
        -DARROW_CSV=ON \
         $ARROW_ROOT/cpp

make -j4 install

popd

pushd $ARROW_ROOT/python
rm -rf build/

export PYARROW_WITH_DATASET=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_RADOS=1

python setup.py build_ext --inplace --bundle-arrow-cpp bdist_wheel
pip install dist/*.whl
cp -r dist/*.whl /

python -c "import pyarrow"
python -c "import pyarrow.dataset"
python -c "import pyarrow.parquet"
python -c "from pyarrow.dataset import SkyhookFileFormat"
