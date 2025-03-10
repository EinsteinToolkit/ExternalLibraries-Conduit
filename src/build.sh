#! /bin/bash

################################################################################
# Build
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



# Set locations
THORN=Conduit
NAME=conduit-v0.9.3-src-with-blt
SRCDIR="$(dirname $0)"
BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
if [ -z "${CONDUIT_INSTALL_DIR}" ]; then
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
else
    echo "BEGIN MESSAGE"
    echo "Installing Conduit into ${CONDUIT_INSTALL_DIR}"
    echo "END MESSAGE"
    INSTALL_DIR=${CONDUIT_INSTALL_DIR}
fi
DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
CONDUIT_DIR=${INSTALL_DIR}

echo "Conduit: Preparing directory structure..."
cd ${SCRATCH_BUILD}
mkdir build external done 2> /dev/null || true
rm -rf ${BUILD_DIR} ${INSTALL_DIR}
mkdir ${BUILD_DIR} ${INSTALL_DIR}

# Build core library
echo "Conduit: Unpacking archive..."
pushd ${BUILD_DIR}
${TAR?} xf ${SRCDIR}/../dist/${NAME}.tar

echo "Conduit: Configuring..."
cd ${NAME}

if [ "${CCTK_DEBUG_MODE}" = yes ]; then
    CONDUIT_BUILD_TYPE=Debug
else
    CONDUIT_BUILD_TYPE=Release
fi

# TODO: might be useful to build non-MPI version all the time so that it can
# run on login nodes
if [ -n "${HAVE_CAPABILITY_MPI}" ]; then
    CONDUIT_USE_MPI=ON
else
    CONDUIT_USE_MPI=OFF
fi

mkdir build
cd build
CMAKE_OPTIONS=(
    -DBUILD_SHARED_LIBS=OFF
    -DCONDUIT_ENABLE_TESTS=OFF
    -DENABLE_COVERAGE=OFF
    -DENABLE_DOCS=OFF
    -DENABLE_EXAMPLES=OFF
    -DENABLE_FORTRAN=OFF
    -DENABLE_MPI=${CONDUIT_USE_MPI}
    -DENABLE_OPENMP=ON
    -DENABLE_PYTHON=ON
    -DENABLE_RELAY_WEBSERVER=OFF
    -DENABLE_TESTS=OFF
    -DENABLE_UTILS=ON
    -DHDF5_DIR=${HDF5_DIR}
    -DSILO_DIR=${SILO_DIR}
    -DZLIB_DIR=${ZLIB_DIR}
)
${CMAKE_DIR:+${CMAKE_DIR}/bin/}cmake ${CMAKE_OPTIONS[@]}

echo "Conduit: Building..."
${MAKE}

echo "Conduit: Installing..."
${MAKE} install
popd

echo "Conduit: Cleaning up..."
rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "Conduit: Done."
