#!/usr/bin/env bash
#
#

BUILD_PATH="build"
IMAGES=(
    "dmr-bridge"
)
HOST=${HOST:-$(env | grep DOCKER_HOST | awk -F\: '{printf "%s\n", $2}' | sed "s|//||g")}
ANALOG_ADDR=${ANALOG_ADDR:-${HOST}}
MMDVM_ADDR=${MMDVM_ADDR:-${HOST}}

if [ -f .env ]
then
    . .env
fi

if [ -z ${CALLSIGN} ]
then
    echo "Error: The CALLSIGN environment variable is not set."
    exit 1
fi

if [ -z ${DMR_ID} ]
then
    echo "Error: The DMR_ID environment variable is not set."
    exit 1
fi

if [ -z ${HOST} ]
then
    echo "Error: No HOST is defined either directly or via DOCKER_HOST."
    exit 1
fi

function container_running() {
    name="${1}"
    version="${2}"
    check=$(docker ps -f name=${name} | tail -n +2 | awk '{print $2}' | awk -F\: '{print $2}')
    if [ "${check}" == "${version}" ]
    then
        echo "${version}"
    fi
}

# Ensure that the MMDVM bridge container is running
# TODO: Add better port exposure handling.
mmdvm_image="mmdvm-bridge"
mmdvm_name=${MMDVM_NAME:-${mmdvm_image}}
mmdvm_path="${BUILD_PATH}/${mmdvm_image}"
mmdvm_version=${MMDVM_VERSION:-$(cat "${mmdvm_path}/VERSION")}
if [ -z $(container_running "${mmdvm_name}" "${mmdvm_version}") ]
then
    docker stop ${mmdvm_name}
    docker rm ${mmdvm_name}
    docker run -d --name ${mmdvm_name} \
        -p 31103:31103/udp \
        -p 62032:62032/tcp -p 62032:62032/udp \
        -e CALLSIGN=${CALLSIGN} \
        -e DMR_ID=${DMR_ID} \
        -e ANALOG_ADDR=${ANALOG_ADDR} \
        ${mmdvm_image}:${mmdvm_version}
fi

# Ensure that the analog bridge container is running
# TODO: Add better port exposure handling.
analog_image="analog-bridge"
analog_name=${ANALOG_NAME:-${analog_image}}
analog_path="${BUILD_PATH}/${analog_name}"
analog_version=${ANALOG_VERSION:-$(cat "${analog_path}/VERSION")}
if [ -z $(container_running "${analog_name}" "${analog_version}") ]
then
    docker stop ${analog_name}
    docker rm ${analog_name}
    docker run -d --name ${analog_name} \
        -p 31100:31100/udp \
        -p 51100:51100/udp \
        -e DMR_ID=${DMR_ID} \
        -e ANALOG_ADDR=${ANALOG_ADDR} \
        -e MMDVM_ADDR=${MMDVM_ADDR} \
        -e AMBE_DECODER_DEVICE=${AMBE_DECODER_DEVICE} \
        ${analog_image}:${analog_version}
fi
