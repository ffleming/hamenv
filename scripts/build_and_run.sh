#!/usr/bin/env bash
set -eo pipefail

IMAGE="dmr-bridge"
BUILD_DIR="build"

function print_help() {
    cat <<EOF
${0} -[cdrHACEM]

    -c, --callsign      The operator callsign
    -d, --dmr-id        The operator DMR ID
    -r, --repeater-id   The ID for the repeater
    -H, --host          The container host running the containers
    -A                  The port for the operator analog bridge container
    -U                  The port that the operator mobile device connects to
    -M                  The port for the operator DMR bridge container
    -D                  Path to AMBE decoder device (eg /dev/ttyUSB0)
EOF
}

# get_image_version returns the current value of the VERSION file in the 
# provided image's build directory.
function get_image_version() {
    local image_name="${1}"
    echo $(cat ${BUILD_DIR}/${image_name}/VERSION)
}

# to_lower returns the input string as all lower-cased characters
function to_lower() {
    local in_string="${1}"
    echo "${in_string}" | tr '[:upper:]' '[:lower:]'
}
# Gather all of the arguments passed and override any current configurations
while (($#))
do
    case "${1}" in
        -c|--callsign)
            CALLSIGN=${2}
            shift
        ;;
        -d|--dmr-id)
            DMR_ID=${2}
            shift
        ;;
        -r|--repeater-id)
            REPEATER_ID=${2}
            shift
        ;;
        -H|--host)
            HOST=${2}
            shift
        ;;
        -A)
            ANALOG_PORT=${2}
            shift
        ;;
        -U)
            USRP_PORT=${2}
            shift
        ;;
        -M)
            MMDVM_PORT=${2}
            shift
        ;;
        -D)
            AMBE_DECODER_DEVICE=${2}
            shift
        ;;
        -h)
            print_help
            exit 0
        ;;
    esac
    shift
done

if [ -z ${CALLSIGN} ]
then
    echo "ERROR: No callsign provided, exiting."
    exit 1
fi

if [ -z ${DMR_ID} ]
then
    echo "ERROR: No DMR ID provided, exiting."
    exit 1
fi

if [ -z ${HOST} ]
then
    echo "ERROR: No host provided, exiting."
    exit 1
fi

if [ -z ${AMBE_DECODER_DEVICE} ]
then
    echo "ERROR: No AMBE device path provided, exiting."
    exit 1
fi

REPEATER_ID="${DMR_ID}01"
  # -p ${ANALOG_PORT}:${ANALOG_PORT}/udp \
  # -p ${USRP_PORT}:${USRP_PORT}/udp \
  # -p 62032:62032/udp \
  # -p 31100:31100/udp \
  # -p 31103:31103/udp \
version=$(get_image_version ${IMAGE})
op_name="${IMAGE}_$(to_lower ${CALLSIGN})-${REPEATER_ID}"

docker build \
  -t "${IMAGE}:${version}" \
  build/dmr-bridge

echo $op_name
docker run \
  -d \
  --name ${op_name} \
  -e CALLSIGN=${CALLSIGN} \
  -e DMR_ID=${DMR_ID} \
  -e ANALOG_HOST=${HOST} \
  -e ANALOG_PORT=${ANALOG_PORT} \
  -e MMDVM_HOST=${HOST} \
  -e MMDVM_PORT=${MMDVM_PORT} \
  -e USRP_PORT=${USRP_PORT} \
  -e AMBE_DECODER_DEVICE=${AMBE_DECODER_DEVICE} \
  -e BM_PASSWD=${BM_PASSWD} \
  -p ${USRP_PORT}:${USRP_PORT}/udp \
  -p ${ANALOG_PORT}:${ANALOG_PORT}/udp \
  -p ${MMDVM_PORT}:${MMDVM_PORT}/udp \
  --device=${AMBE_DECODER_DEVICE} \
  --network bridge \
  ${IMAGE}:${version}
