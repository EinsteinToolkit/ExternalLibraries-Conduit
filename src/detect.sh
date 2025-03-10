#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

. $CCTK_HOME/lib/make/bash_utils.sh

# Take care of requests to build the library in any case
CONDUIT_DIR_INPUT=$CONDUIT_DIR
if [ "$(echo "${CONDUIT_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]; then
    CONDUIT_BUILD=1
    CONDUIT_DIR=
else
    CONDUIT_BUILD=
fi

################################################################################
# Decide which libraries to link with
################################################################################

CONDUIT_REQ_LIBS="conduit_relayconduit_blueprint conduit"
CONDUIT_MPI_LIBS="conduit_relay_mpi_io conduit_relay_mpi conduit_blueprint_mpi"

# Set up names of the libraries based on configuration variables. Also
# assign default values to variables.
# Try to find the library if build isn't explicitly requested
if [ -z "${CONDUIT_BUILD}" -a -z "${CONDUIT_INC_DIRS}" -a -z "${CONDUIT_LIB_DIRS}" -a -z "${CONDUIT_LIBS}" ]; then
    find_lib Conduit conduit 1 0.93 "$CONDUIT_LIBS" "conduit/conduit_config.h" "$CONDUIT_DIR"

    if [ -n "${CONDUIT_DIR}" ]; then
        # any libraries needed b/c of Conduit compile options
        CONDUITCONFFILES="conduit/conduit_relay_config.h"
        for dir in $CONDUIT_INC_DIRS $CONDUIT_DIR/include; do
            for file in $CONDUITCONFFILES ; do
                if [ -r "$dir/$file" ]; then
                    CONDUITCONF="$dir/$file"
                    break
                fi
            done
        done
        if [ -z "$CONDUITCONF" ]; then
            echo 'BEGIN MESSAGE'
            echo 'WARNING in Conduit configuration: '
            echo "None of $CONDUITCONFFILES found in $CONDUIT_INC_DIRS $CONDUIT_DIR/include"
            echo "Automatic detection of MPI use not possible"
            echo 'END MESSAGE'
        else
            # Check whether we have to link with MPI
            if grep -qe '^#define CONDUIT_RELAY_MPI_ENABLED' "$CONDUITCONF" 2> /dev/null; then
                test_mpi=0
            else
                test_mpi=1
            fi
            if [ $test_mpi -eq 0 ]; then
                CONDUIT_LIBS="$CONDUIT_MPI_LIBS $CONDUIT_LIBS"
            fi
        fi
    fi
fi

THORN=Conduit

# configure library if build was requested or is needed (no usable
# library found)
if [ -n "$CONDUIT_BUILD" -o -z "${CONDUIT_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Using bundled Conduit..."
    echo "END MESSAGE"
    CONDUIT_BUILD=1

    check_tools "tar patch"
    
    # Set locations
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${CONDUIT_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing Conduit into ${CONDUIT_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${CONDUIT_INSTALL_DIR}
    fi
    CONDUIT_DIR=${INSTALL_DIR}
    CONDUIT_INC_DIRS="${CONDUIT_DIR}/include"
    CONDUIT_LIB_DIRS="${CONDUIT_DIR}/lib"
    CONDUIT_LIBS="$CONDUIT_REQ_LIBS"
    if [ -n "${MPI_DIR+set}" ]; then
        CONDUIT_LIBS="${CONDUIT_MPI_LIBS} ${CONDUIT_LIBS}"
    fi
else
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    if [ ! -e ${DONE_FILE} ]; then
        mkdir ${SCRATCH_BUILD}/done 2> /dev/null || true
        date > ${DONE_FILE}
    fi
fi

if [ -n "$CONDUIT_DIR" ]; then
    :
else
    echo 'BEGIN ERROR'
    echo 'ERROR in Conduit configuration: Could neither find nor build library.'
    echo 'END ERROR'
    exit 1
fi

################################################################################
# Check for additional libraries
################################################################################


################################################################################
# Configure Cactus
################################################################################

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "CONDUIT_BUILD          = ${CONDUIT_BUILD}"
echo "CONDUIT_DIR            = ${CONDUIT_DIR}"
echo "CONDUIT_INC_DIRS       = ${CONDUIT_INC_DIRS} ${HDF5_INC_DIRS} ${SILO_INC_DIRS} ${ZLIB_INC_DIRS}"
echo "CONDUIT_LIB_DIRS       = ${CONDUIT_LIB_DIRS} ${HDF5_LIB_DIRS} ${SILO_LIB_DIRS} ${ZLIB_LIB_DIRS}"
echo "CONDUIT_LIBS           = ${CONDUIT_LIBS}"
echo "CONDUIT_INSTALL_DIR    = ${CONDUIT_INSTALL_DIR}"
echo "END MAKE_DEFINITION"

echo "BEGIN DEFINE"
if [ -n "${MPI_DIR+set}" ]; then
echo "CONDUIT_USE_MPI 1"
fi
echo "END DEFINE"

echo 'INCLUDE_DIRECTORY $(CONDUIT_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(CONDUIT_LIB_DIRS)'
echo 'LIBRARY           $(CONDUIT_LIBS)'
