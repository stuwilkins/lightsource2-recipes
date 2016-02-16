#!/usr/bin/env bash

# NOTE: This script has been adapted from content generated by github.com/conda-forge/conda-smithy

REPO_ROOT=$(cd "$(dirname "$0")/.."; pwd;)
IMAGE_NAME="pelson/obvious-ci:latest_x64"

config=$(cat <<CONDARC

channels:
 - lightsource2-dev
 - lightsource2
 - conda-forge
 - defaults

always_yes: true
show_channel_urls: True

CONDARC
)

cat << EOF | docker run -i \
                        -v ${REPO_ROOT}/recipes:/conda-recipes \
                        -a stdin -a stdout -a stderr \
                        $IMAGE_NAME \
                        bash || exit $?

if [ "${BINSTAR_TOKEN}" ];then
    export BINSTAR_TOKEN=${BINSTAR_TOKEN}
fi

# Unused, but needed by conda-build currently... :(
export CONDA_NPY='19'

export PYTHONUNBUFFERED=1
echo "$config" > ~/.condarc

# A lock sometimes occurs with incomplete builds. The lock file is stored in build_artefacts.
conda clean --lock

conda update conda
conda install anaconda-client conda-build-all
conda info
unset LANG

git clone https://github.com/conda/conda-build
cd conda-build
python setup.py develop

# These are some standard tools. But they aren't available to a recipe at this point (we need to figure out how a recipe should define OS level deps)
#yum install -y expat-devel git autoconf libtool texinfo check-devel

# These were specific to installing matplotlib. I really want to avoid doing this if possible, but in some cases it
# is inevitable (without re-implementing a full OS), so I also really want to ensure we can annotate our recipes to
# state the build dependencies at OS level, too.
yum install -y libXext libXrender libSM tk libX11-devel

conda-build-all /conda-recipes --upload-channels lightsource2-dev --matrix-conditions "numpy >=1.8" "python >=2.7,<3|>=3.4" --inspect-channels lightsource2-dev

EOF

