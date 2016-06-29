#!/bin/bash
#
# $Header: 
#
# emudm_ibconnect.sh v0.1
#
# Copyright (c) 2010, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      emudm_ibconnect.sh - Enterprise Manager User-Defined Metric
#                           InfiniBand net CONNECTivity check
#
#    DESCRIPTION
#      EM UDM script to monitor connectivity over IB network to other database
#      servers and storage servers.  List of database servers is built from
#      ocrdump SYSTEM.crs.e2eport key.  List of cells is built from cellip.ora.
#      This script will not validate connectivity to additional devices on the
#      IB network like media servers.
#
#      Note that ibhosts cannot be used because of root permission requirement.
#      The approach used in this script is preferred since it scope limited
#      to servers that it should care about, which may not be the whole IB 
#      network.
#
#      No parameters required
#
#    NOTES
#      
#
#    MODIFIED   (MM/DD/YY)
#    dutzig      08/11/10 - Creation
#

NONE=0
SOME=1
ALL=2

pingFail=$ALL
rdspingFail=$ALL
error=$NONE

pingFailCt=0
rdspingFailCt=0

platform=$(/bin/uname -s)

ping='/bin/ping -c1 -n'
rdsping='/usr/bin/rds-ping -c1'
rdspingTimeout=4

oratabFile=/etc/oratab
initcrsdFile=/etc/init.d/init.crsd
cellipFile=/etc/oracle/cell/network-config/cellip.ora

# 
#
#
function now {
  /bin/date +'%F %T %Z'
}

# 
# log to logfile pointed to by env variable XMON_DEBUG
#
function debug {
  [[ -z $XMON_DEBUG ]] && return

  # make sure each line starts with DEBUG
  echo "$*" | while read; do
    echo "DEBUG: $(now) ${FUNCNAME[1]}: $REPLY" >> $XMON_DEBUG
  done
}

# 
# Look for ocrdump file in GI/CRS home
#
function get_ocrdump_path {
  local giHome
  
  # 11.2 - GI home same as ASM
  if [[ -r $oratabFile ]]; then
    giHome=$(sed -n '/^+ASM/ s/+ASM.*:\(.*\):.*/\1/p' $oratabFile 2>/dev/null)
    if [[ -x $giHome/bin/ocrdump ]]; then
      debug "ocrdump found in $giHome via oratab $oratabFile"
      echo $giHome
      return 0
    fi
  fi

  # no ocrdump yet, try 11.1 getting CRS home from startup scripts
  if [[ -r $initcrsdFile ]]; then
    giHome=$(sed -n '/^ORA_CRS_HOME=/ s/ORA_CRS_HOME=\(.*\)/\1/p' $initcrsdFile)
    if [[ -x $giHome/bin/ocrdump ]]; then
      debug "ocrdump found in $giHome via init.crsd $initcrsdFile"
      echo $giHome
      return 0
    fi
  fi

  # Did not find ocrdump
  return 1
}

# 
# get list of database nodes from ocrdump output
#
function get_rac_ip_list {
  local giHome racList ocrdumpOutput
  
  if ! giHome=$(get_ocrdump_path); then
    debug "Failed to find ocrdump"
    error=$SOME
    errorMsgPart="Database node list unavailable, ocrdump not found${errorMsgPart:+; $errorMsgPart}"
    return 1
  fi
  
  ocrdumpOutput=$($giHome/bin/ocrdump -stdout -keyname SYSTEM.crs.e2eport -noheader)
  
  if [[ $? -ne 0 ]]; then
    debug "ocrdump returned non-zero return code ($ocrdumpOutput)"
    error=$SOME
    errorMsgPart="Database node list unavailable, ocrdump failed with ${ocrdumpOutput}${errorMsgPart:+; $errorMsgPart}"
    return 1
   fi
   
   debug "ocrdump returned zero return code"
   
   racList=$(echo "$ocrdumpOutput" | /bin/sed -n '/e2eport/,+1 s/.*HOST=\([[:digit:].]*\)).*/\1/p')
   ipaddrList=(${ipaddrList[*]} $racList)
   return 0
}

# 
# get list of cells from cellip.ora
#
function get_cell_ip_list {
  local cellList

  if ! cellList=$(/bin/sed 's/cell=\"\([[:digit:].]*\).*/\1/' $cellipFile); then
    debug "failed to parse $cellipFile"
    error=$SOME
    errorMsgPart="Cell list unavailable, failed to parse $cellipFile${errorMsgPart:+; $errorMsgPart}"
    return 1
   fi

   debug "parsed $cellipFile"
   
   ipaddrList=(${ipaddrList[*]} $cellList)
   return 0
}

# 
# get list of database servers and cells
#
function get_ib_ip_list {
  local retval1 retval2
  
  get_rac_ip_list
  retval1=$?
    
  get_cell_ip_list
  retval2=$?

  # if fail to get just one list, then we can continue with other set
  # if fail to get both, then this is an ERROR condition
  if [[ $retval1 -ne 0 && $retval2 -ne 0 ]]; then
    error=$ALL
    return 1
  fi
  
  return 0
}


# 
# MAIN
#

# Step through list of nodes, ping and rds-ping each
debug "Starting connectivity test"


if get_ib_ip_list; then
  
  debug "IP address list ${ipaddrList[*]}"
  for ipaddr in ${ipaddrList[*]}; do

    debug "Running ping $ipaddr"
    if ! pingOutput=$($ping $ipaddr 2>&1); then
      debug "ping $ipaddr: FAILED"
      debug "$pingOutput"

      pingFailCt=$((pingFailCt+1))
      pingFailList=(${pingFailList[*]} $ipaddr)
    else
      debug "ping $ipaddr: SUCCESS"
      debug "$pingOutput"
    fi

    debug "Running rdsping $ipaddr"
    if ! rdspingOutput=$($rdsping -i $rdspingTimeout $ipaddr 2>&1); then
      debug "rdsping $ipaddr: FAILED"
      debug "$rdspingOutput"

      rdspingFailCt=$((rdspingFailCt+1))
      rdspingFailList=(${rdspingFailList[*]} $ipaddr)
    else
      debug "rdsping $ipaddr: SUCCESS"
      debug "$rdspingOutput"
    fi

  done

  # Evaluate results of tests
  pingFail=$NONE
  if [[ $pingFailCt -gt 0 ]]; then
    pingFail=$SOME
    pingFailMsgPart="ping failed to some hosts: ${pingFailList[*]}"
    if [[ $pingFailCt -eq ${#ipaddrList[*]}-1 ]]; then
      pingFail=$ALL
      pingFailMsgPart="ping failed to all hosts: ${pingFailList[*]}"
    fi
  fi

  rdspingFail=$NONE
  if [[ $rdspingFailCt -gt 0 ]]; then
    rdspingFail=$SOME
    rdspingFailMsgPart="rds-ping failed to some hosts: ${rdspingFailList[*]}"
    if [[ $rdspingFailCt -eq ${#ipaddrList[*]}-1 ]]; then
      rdspingFail=$ALL
      rdspingFailMsgPart="rds-ping failed to all hosts: ${rdspingFailList[*]}"
    fi
  fi
  failMsgFull="${pingFailMsgPart}${rdspingFailMsgPart}"
fi

# Build response back to EM
debug "case statement qualifiers - $pingFail:$rdspingFail:$error"

case "$pingFail:$rdspingFail:$error" in
  $NONE:$NONE:$NONE)
      em_result=NORMAL
      em_message=""
      ;;

  # unable to get any hosts to ping
  *:*:$ALL)
      em_result=ERROR
      em_message="$errorMsgPart"
      ;;

  # either all ping tests failed or all rds tests failed
  *:*:[^$ALL])
      em_result=CRITICAL
      em_message="${pingFailMsgPart}${failMsgFull:+; }${rdspingFailMsgPart}"
      em_message="${em_message}${errorMsgPart:+; $errorMsgPart}"
      ;;

  *)
      em_result=WARNING
      em_message="${pingFailMsgPart}${failMsgFull:+; }${rdspingFailMsgPart}"
      em_message="${em_message}${em_message:+; }$errorMsgPart"
      ;;
esac

echo "em_result=$em_result"
echo "em_message=$em_message"

exit 0
