#!/bin/bash

##########################################################################
# This script puts the plugins' binary files from provided source
# directory into Jenkins plugin directory.
#
#                             NOTE !
# 1. Jenkins should be stopped (shut down) before starting this script.
# 2. You should run this script as a user that owns Jenkins workspace
#    directory (that comprises plugin directory). Otherwise some file
#    ownership related errors may occur.
##########################################################################


SCRIPT_PATH=$(dirname $(realpath $0))    # full path to the directory where the script is located
START_TIME=$(date +%F__%T | sed 's/:/-/g')
SRC_DIR="${SCRIPT_PATH}/downloaded_plugins" # do not ends the path with a slash 
DST_DIR='/opt/jenkins/workspace/plugins'    # do not ends the path with a slash 
LOG_FILE="${SCRIPT_PATH}/put-jpi-into_plugin_dir_${START_TIME}.log"
BKP_EXT='.bak_'${START_TIME}    # filename extention added to a backup of updated jpi file 


##################################################################################
# This script uses Yannek-JS Bash library; 
# it checks whether this library (bash-scripts-lib.sh) is present; 
# if not, the script is quitted.
# You can download this library from https://github.com/Yannek-JS/bash-scripts-lib
###################################################################################
if [ -f "${SCRIPT_PATH}/bash-scripts-lib.sh" ]
then
    source "${SCRIPT_PATH}/bash-scripts-lib.sh"
else
    echo -e "\n Critical !!! 'bash-script-lib.sh' is missing. Download it from 'https://github.com/Yannek-JS/bash-scripts-lib' into directory where this script is located.\n"
    exit
fi
###################################################################################


function check_exit_code() {
    # Parameters:
    #   $1 - exit code
    if [ $1 -ne 0 ]; then echo 'Error. See the log file'; else echo 'OK'; fi
}


echo -e '\nEnsure you are running this script as a user who owns Jenkins workspace directory !'
yes_or_not

if ! [ -d ${SRC_DIR} ] || ! [ -d ${DST_DIR} ]
then
    echo -e "\nProblem ! Some of following directories do not exist: \n  ${SRC_DIR} \n  ${DST_DIR} \n"
    quit_now
fi

find $SRC_DIR -type f -iname '*.hpi' | while read jpi_full_path
do
    plugin=$(echo $jpi_full_path | gawk --field-separator '/' '{print $(NF)}' \
            | gawk --field-separator '.hpi' '{print $1}')
    echo '----------------------------------------------------------------------' | tee --append "${LOG_FILE}"
    echo "  Processing $plugin plugin" | tee --append "${LOG_FILE}"
    if [ -f "${DST_DIR}/${$plugin}.jpi" ]
    then
        echo -e -n "Backing up ${DST_DIR}/${plugin}.jpi plugin -> ${DST_DIR}/${plugin}.jpi${BKP_EXT} ..... " \
            | tee --append "${LOG_FILE}"
        echo  >> "${LOG_FILE}"
        mv --verbose "${DST_DIR}/${plugin}.jpi" "${DST_DIR}/${plugin}.jpi${BKP_EXT}" >> "${LOG_FILE}" 2>&1
        if [ $? -eq 0 ]
        then
            echo 'OK' | tee --append "${LOG_FILE}"
            echo -e -n "Putting new ${plugin} plugin version from ${SRC_DIR} into ${DST_DIR} ..... " \
                | tee --append "${LOG_FILE}"
            echo  >> "${LOG_FILE}"
            cp --verbose "${SRC_DIR}/${plugin}" "${DST_DIR}/" >> "${LOG_FILE}" 2>&1
            echo $(check_exit_code $?) | tee --append "${LOG_FILE}"
        else
            echo 'Error. See the log file' | tee --append "${LOG_FILE}"
        fi
    elif [ -f "${DST_DIR}/${plugin}.disabled" ]
    then
        echo "INFO! Plugin ${plugin} has been disabled." | tee --append $LOG_FILE
        echo -e -n "Backing up ${DST_DIR}/${plugin}.disabled plugin -> ${DST_DIR}/${plugin}.disabled${BKP_EXT} ..... " \
            | tee --append "${LOG_FILE}"
        echo  >> "${LOG_FILE}"
        mv --verbose "${DST_DIR}/${plugin}.disabled" "${DST_DIR}/${plugin}.disabled${BKP_EXT}" >> "${LOG_FILE}" 2>&1
        if [ $? -eq 0 ]
        then  
            echo 'OK' | tee --append "${LOG_FILE}"
            echo -e -n "Putting new ${plugin} plugin version disabled from ${SRC_DIR} into ${DST_DIR} ..... " \
                | tee --append $LOG_FILE
            echo  >> "${LOG_FILE}"
            cp --verbose "${SRC_DIR}/${plugin}" "${DST_DIR}/${plugin}.disabled" >> "${LOG_FILE}" 2>&1
            echo $(check_exit_code $?) | tee --append "${LOG_FILE}"
        else
            echo 'Error. See the log file' | tee --append "${LOG_FILE}"
        fi
    else
        echo "INFO! No previous  ${plugin} plugin version in ${DST_DIR}." | tee --append $LOG_FILE
        echo -e -n "Putting new ${plugin} plugin version from ${SRC_DIR} into ${DST_DIR} ..... " \
            | tee --append "${LOG_FILE}"
        echo  >> "${LOG_FILE}"
        cp --verbose "${SRC_DIR}/${plugin}" "${DST_DIR}/" >> "${LOG_FILE}" 2>&1
        echo $(check_exit_code $?) | tee --append "${LOG_FILE}"
    fi
    echo | tee --append "${LOG_FILE}"
done
