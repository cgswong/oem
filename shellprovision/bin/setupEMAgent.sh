#!/bin/bash
# #######################################################################
# NAME: setupEMAgent.sh
#
# DESC: Linux bash script to run pre and post setup for EM12c Agent
#       installation.
#
# $HeadURL$
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
#
# LOG:
# yyyy/mm/dd [user]: [version] [notes]
# 2014/02/05 cgwong: [v1.0.0] Initial creation
# #######################################################################

SCRIPT=`basename $0`
SCRIPT_PATH=$(dirname $SCRIPT)

# -- Variables -- #
DT_STAMP=`date "+%Y%m%d_%H%M%S"`    # Date/time stamp
LOGFILE=`echo $SCRIPT | awk -F"." '{print $1}'`-${DT_STAMP}.log    # Log file
TGT_HOST=`hostname -f`    # Target hostname
WARN=2    # Warning status
ERR=1     # Error status
SUC=0     # Success status

# -- Functions -- #
msg ()
{ # Print message to screen and log file
  # Valid parameters:
  #   $1 - function name
  #   $2 - Message Type or status
  #   $3 - message
  #
  # Log format:
  #   Timestamp: [yyyy-mm-dd hh24:mi:ss]
  #   Component ID: [compID: ]
  #   Process ID (PID): [pid: ]
  #   Host ID: [hostID: ]
  #   User ID: [userID: ]
  #   Message Type: [NOTE | WARN | ERROR | INFO | DEBUG]
  #   Message Text: "Metadata Services: Metadata archive (MAR) not found."

  # Variables
  TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
  [[ -n "$LOGFILE" ]] && echo -e "[${TIMESTAMP}],PRC: ${1},PID: ${PID},HOST: $TGT_HOST,USER: ${USER}, STATUS: ${2}, MSG: ${3}" | tee -a $LOGFILE
}

show_usage ()
{
  echo "
 ${SCRIPT} - Linux bash script to run pre and post setup for EM Agent setup.

 USAGE
 ${SCRIPT} [-pre <install directory> | -post <properties file> <hosts file>]

 -pre <install directory>
    Do pre-installation processing. This is clearing the installation directory, which
    can be passed as an option if different from the default (/opt/emagent), and
    setting up SSH keys.
  
 -post <properties file> <hosts file>
    Do post installation processing which includes:
    1. Applying Privilege Delegation setting
    2. Applying target meta-data
 
    Specify the full name (i.e. directory and file name) of the properties file
    which will apply the meta-data to the hosts. A sample format for the 
    file content is below:
    
          <hostname>:host:Line of Business:[RSR|GBO|GP];<hostname>:host:Location:[STL|ANT|...];<hostname>:host:LifeCycle Status:[Development|Test|Stage|Production]
          
    The default property file name is '/dba/slib/emagent/deploy/rec_file'.
          
    A listing of hosts (one per line) on which to apply the Privilege Delegation setting
    should can also be used by specifying the full name (i.e. directory and file name). The
    default file name is '/opt/slib/emagent/deploy/pdp_hosts'.
"
}

prework ()
{
  # Get installation directory or use default
  INSTALL_DIR=${2:-"/opt/emagent"}
  if [ -d ${INSTALL_DIR} ]; then    # Check if location exists
    rm -rf ${INSTALL_DIR}/*
    if [ `echo $?` ]; then
      msg prework INFO "EM Agent install directory ${INSTALL_DIR} cleared."
    else
      msg prework ERROR "Failed clearing EM Agent install directory ${INSTALL_DIR}."
      STATE=${ERR}
    fi
  else    # Error and exit if location does not exist
    msg prework ERROR "EM Agent install directory ${INSTALL_DIR} not found."
    STATE=${ERR}
  fi
  
  # Setup VAS usage for EMAGENT
  ##sudo vastool configure pam emagent
}

postwork ()
{
  # Get property file or use default
  PROP_FILE=${2:-"/dba/slib/emagent/deploy/rec_file"}
  if [ -f ${PROP_FILE} ]; then
    msg postwork INFO "Setting target properties."
    $EMAGENT_HOME/emcli set_target_property_value -property_records="REC_FILE" -input_file="REC_FILE:${PROP_FILE}"
    if [ `echo $?` -ne 0 ]; then
      msg postwork WARN "Failure setting up target properties."
      STATE=${WARN}
    fi
  else
    msg postwork WARN "No target property file found."
    STATE=${WARN}
  fi
  
  # Get host listing file or use default for Privilege Delegation Propagation
  PDP_FILE=${3:-"/dba/slib/emagent/deploy/pdp_hosts"}
  if [ -f ${PROP_FILE} ]; then
    msg postwork INFO "Setting Privilege Delegation setting."
    $EMAGENT_HOME/emcli apply_privilege_delegation_setting -setting_name=sudo_setup -target_type=host -input_file="FILE:${PDP_FILE}"
    if [ `echo $?` -ne 0 ]; then
      msg postwork WARN "Failure setting up Privilege Delegation."
      STATE=${WARN}
    fi
  else
    msg postwork WARN "No Privilege Delegation Property host file found."
    STATE=${WARN}
  fi
}

# -- Functions (END) -- #

# -- Main -- #
# Process command line
case "$1" in
  "-pre")    # Pre-installation setup
    prework ;;
  "-post")   # Post installation setup
    postwork ;;
  *)        # Print usage otherwise
    show_usage
    STATE=${ERR} ;;
esac

exit ${STATE}

# End