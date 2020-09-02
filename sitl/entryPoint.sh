#! /bin/bash

echo SYSID_THISMAV=$1 | tee -a /ardupilot/Tools/autotest/default_params/copter.parm

if [ -f /external/extra-locations.txt ]
then
    cat /external/extra-locations.txt >> /ardupilot/Tools/autotest/locations.txt
fi

if [ "${START_LOCATION}" = "" ]
then
    START_LOCATION="-L $(< /external/start-location.conf)"
fi

if [ -n "${SITL_PARAMS}" ]
then
    echo "${SITL_PARAMS}" > extra.parm
    $PARAM_FILES+=" --add-param-file=extra.parm"
fi

sim_vehicle.py -N -v ArduCopter --frame=hexa ${START_LOCATION} $PARAM_FILES -w --model hexa --no-mavproxy --sitl-instance-args="-S --base-port $GCS_PORT" $SIM_OPTIONS
