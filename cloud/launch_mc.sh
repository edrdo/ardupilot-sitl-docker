#!/system/bin/sh

set -e
set -x

SHARED_PREFS_DIR=/data/data/com.flytrex.onboardng/shared_prefs
SHARED_PREFS_FILENAME=com.flytrex.onboardng_prefs.xml
MC_PACKAGE_NAME="com.flytrex.onboardng"
MC_MAIN_ACTIVITY="ui.MainActivity"
VPC_DNS_SERVER=$(getprop net.dns1)

for i in {1..10}
do
    RECORD_DATA=$(nslookup -type=SRV ${SRV_RECORD} ${VPC_DNS_SERVER} | grep ${SRV_RECORD})
    SITL_HOSTNAME=$(echo ${RECORD_DATA} | awk '{print $NF}')
    SITL_PORT=$(echo ${RECORD_DATA} | awk '{print $(NF-1)}')
    if [ "${SITL_PORT}" -gt 0 ]
    then
        break
    fi
    sleep 1
done
if [ ! "${SITL_PORT}" -gt 0 ]
then
    echo "can't resolve SRV"
    exit 1
fi

echo ${SITL_HOSTNAME}:${SITL_PORT}

PREFS_TMP_PATH=${SHARED_PREFS_DIR}/${SHARED_PREFS_FILENAME}.tmp
grep -v -e "drone_sitl_port" -e "drone_use_sitl" -e "drone_sitl_hostname" -e "simulate_ioio" -e "vehicle_id" -e "</map>" ${SHARED_PREFS_DIR}/${SHARED_PREFS_FILENAME} > ${PREFS_TMP_PATH}
echo "    <int name=\"drone_sitl_port\" value=\"${SITL_PORT}\" />" >> ${PREFS_TMP_PATH}
echo "    <boolean name=\"drone_use_sitl\" value=\"true\" />" >> ${PREFS_TMP_PATH}
echo "    <string name=\"drone_sitl_hostname\">${SITL_HOSTNAME}</string>" >> ${PREFS_TMP_PATH}
echo "    <boolean name=\"simulate_ioio\" value=\"true\" />" >> ${PREFS_TMP_PATH}
echo "    <int name=\"vehicle_id\" value=\"${VEHICLE_ID}\" />" >> ${PREFS_TMP_PATH}
echo "</map>" >> ${PREFS_TMP_PATH}
cat ${PREFS_TMP_PATH} > ${SHARED_PREFS_DIR}/${SHARED_PREFS_FILENAME}
rm ${PREFS_TMP_PATH}
rm ${SHARED_PREFS_DIR}/${MC_PACKAGE_NAME}_preferences.xml
chown $(stat -c '%U:%G' ${SHARED_PREFS_DIR} | tr -d '[:space:]') ${SHARED_PREFS_DIR}/${SHARED_PREFS_FILENAME}
restorecon ${SHARED_PREFS_DIR}/${SHARED_PREFS_FILENAME}

echo "launching Mission Computer"
am force-stop ${MC_PACKAGE_NAME}
sync && sleep 5
am start -n ${MC_PACKAGE_NAME}/.${MC_MAIN_ACTIVITY}
