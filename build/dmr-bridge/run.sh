#!/usr/bin/env bash
set -eo pipefail

PROGRAM_DIR="/opt/Analog_Bridge"
ANALOG_BRIDGE_CONFIG="/Analog_Bridge.ini"
DVSWITCH_INI="/DVSwitch.ini"
ANALOG_HOST=${ANALOG_HOST:-127.0.0.1}
MMDVM_HOST=${MMDVM_HOST:-127.0.0.1}
USRP_PORT=${USRP_PORT:-51100}
PLATFORM=${PLATFORM:-amd64}
REPEATER_ID=${REPEATER_ID:-00}

BM_ADDR=${BM_ADDR:-3103.repeater.net}
BM_PORT=${BM_PORT:-62031}
BM_LOCAL_PORT=${BM_LOCAL_PORT:-62032}
REPEATER_ID=${REPEATER_ID:-"${DMR_ID}"01}
LATITUDE=${LATITUDE:-0}
LONGITUDE=${LONGITUDE:-0}
LOCATION=${LOCATION:-UNKNOWN}
DESCRIPTION=${DESCRIPTION:-hamenv Bridge}
URL=${URL:-"https://qrz.com/db/${CALLSIGN}"}

MMDVM_INI=${MMDVM_INI:-/MMDVM_Bridge.ini}

if [ ! ${DMR_ID} ]
then
    echo "No DMR ID provided, exiting."
    exit 1
fi
if [ -z ${CALLSIGN} ]
then
    echo "No Callsign provided, exiting."
    exit 1
fi
if [ -z ${BM_PASSWD} ]
then
    echo "No BM password provided, exiting."
    exit 1
fi
if [ -z ${ANALOG_PORT} ]
then
    echo "No port for Analog Bridge provided, exiting."
    exit 1
fi
if [ -z ${MMDVM_PORT} ]
then
    echo "No port for MMDVM Bridge provided, exiting."
    exit 1
fi
# Check if the configuration file exists and populate it if it does not
if [ ! -f ${ANALOG_BRIDGE_CONFIG} ]
then
    echo -n "configuring analog bridge..."
    cp ${ANALOG_BRIDGE_CONFIG}.tmpl ${ANALOG_BRIDGE_CONFIG}
    sed -i "s/{{ANALOG_HOST}}/${ANALOG_HOST}/g" ${ANALOG_BRIDGE_CONFIG}
    sed -i "s/{{ANALOG_PORT}}/${ANALOG_PORT}/g" ${ANALOG_BRIDGE_CONFIG}
    sed -i "s/{{ANALOG_HOST}}/${ANALOG_HOST}/g" ${ANALOG_BRIDGE_CONFIG}
    sed -i "s/{{MMDVM_HOST}}/${MMDVM_HOST}/g" ${ANALOG_BRIDGE_CONFIG}
    sed -i "s/{{MMDVM_PORT}}/${MMDVM_PORT}/g" ${ANALOG_BRIDGE_CONFIG}
    sed -i "s/{{USRP_PORT}}/${USRP_PORT}/g" ${ANALOG_BRIDGE_CONFIG}
    sed -i "s/{{DMR_ID}}/${DMR_ID}/g" ${ANALOG_BRIDGE_CONFIG}
    sed -i "s/{{REPEATER_ID}}/${DMR_ID}${REPEATER_ID}/g" ${ANALOG_BRIDGE_CONFIG}
    sed -i "s|{{AMBE_DECODER_DEVICE}}|${AMBE_DECODER_DEVICE}|g" ${ANALOG_BRIDGE_CONFIG}
    echo "done"
    # Configure DVSwitch
    echo -n "configuring DVSwitch..."
    cp ${DVSWITCH_INI}.tmpl ${DVSWITCH_INI}
    sed -i "s/{{CALLSIGN}}/${CALLSIGN}/g" ${DVSWITCH_INI}
    sed -i "s/{{ANALOG_HOST}}/${ANALOG_HOST}/g" ${DVSWITCH_INI}
    sed -i "s/{{ANALOG_PORT}}/${ANALOG_PORT}/g" ${DVSWITCH_INI}
    sed -i "s/{{MMDVM_PORT}}/${MMDVM_PORT}/g" ${DVSWITCH_INI}
    # TODO: Figure out where this hardcoded value is getting set and determine 
    # the best way to avoid having to create this symlink
    ln -s ${DVSWITCH_INI} /opt/MMDVM_Bridge/DVSwitch.ini
    echo "done"
fi

./Analog_Bridge ${ANALOG_BRIDGE_CONFIG} &

if [ ! -f ${MMDVM_INI} ]
then
    echo -n "Configuring the MMDVM bridge..."
    cp ${MMDVM_INI}.tmpl ${MMDVM_INI}
    sed -i "s/{{CALLSIGN}}/${CALLSIGN}/g" ${MMDVM_INI}
    sed -i "s/{{DMR_BM}}/${DMR_ID}${REPEATER_ID}/g" ${MMDVM_INI}
    sed -i "s/{{LATITUDE}}/${LATITUDE}/g" ${MMDVM_INI}
    sed -i "s/{{LONGITUDE}}/${LONGITUDE}/g" ${MMDVM_INI}
    sed -i "s/{{LOCATION}}/${LOCATION}/g"  ${MMDVM_INI}
    sed -i "s/{{DESCRIPTION}}/${DESCRIPTION}/g" ${MMDVM_INI}
    # Change the string replace character to comply with characters valid in a 
    # URL
    sed -i "s|{{URL}}|${URL}|g" ${MMDVM_INI}
    sed -i "s/{{BM_ADDR}}/${BM_ADDR}/g" ${MMDVM_INI}
    sed -i "s/{{BM_PORT}}/${BM_PORT}/g" ${MMDVM_INI}
    sed -i "s/{{BM_LOCAL_PORT}}/${BM_LOCAL_PORT}/g" ${MMDVM_INI}
    sed -i "s/{{BM_PASSWD}}/${BM_PASSWD}/g" ${MMDVM_INI}
fi

/MMDVM_Bridge ${MMDVM_INI} &

while sleep 60; do
  ps aux |grep Analog_Bridge |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep MMDVM_Bridge |grep -q -v grep
  PROCESS_2_STATUS=$?
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done

