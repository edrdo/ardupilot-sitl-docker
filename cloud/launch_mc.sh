#!/system/bin/sh

VPC_DNS_SERVER="10.0.0.2"
SHARED_PREFS_DIR=/data/data/com.flytrex.onboardng/shared_prefs


RECORD_DATA=$(nslookup -type=SRV ${SRV_RECORD} ${VPC_DNS_SERVER} | grep ${SRV_RECORD})
SITL_HOSTNAME=$(echo ${RECORD_DATA} | awk '{print $NF}')
SITL_PORT=$(echo ${RECORD_DATA} | awk '{print $(NF-1)}')
echo ${SITL_HOSTNAME}:${SITL_PORT}

sed -i "s/\(<string name=\"drone_sitl_hostname\">\)[0-9A-Z.]*\(<\/string>\)/\1${SITL_HOSTNAME}\2/" ${SHARED_PREFS_DIR}/*.xml
sed -i "s/\(<string name=\"drone_sitl_port\">\)[0-9]*\(<\/string>\)/\1${SITL_PORT}\2/" ${SHARED_PREFS_DIR}/*.xml

# TODO: launch the mc app