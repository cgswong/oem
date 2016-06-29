# ! /bin/sh
######################################################
# NAME: EMAgentenv.sh
#
# DESC: Configures environment for Enterprise Manager
#       Agent.
#
# NOTE: Due to constraints of the shell in regard to environment
#       variables, the command MUST be prefaced with ".". If it
#       is not, then no permanent change in the user's environment
#       can take place.
#
# $HeadURL$
# $LastChangedBy$
# $LastChangedDate$
# $LastChangedRevision$
#
# LOG:
# yyyy/mm/dd [user] - [notes]
# 2014/03/04 cgwong - v1.0.0 creation
######################################################

# Functions
pathman ()
{
# Function used to add non-existent directory (given as argument)
# to PATH variable.
  if ! echo ${PATH} | /bin/egrep -q "(^|:)$1($|:)" ; then
    PATH=$1:${PATH} ; export PATH
  fi
}

# Misc.
NLS_LANG=AMERICAN_AMERICA.AL32UTF8 ; export NLS_LANG
ORA_BASE=/u01/app/oracle/product   ; export ORA_BASE
unset LD_ASSUME_KERNEL

# Agent variables
AGENT_BASE=$ORA_BASE/emagent              ; export AGENT_BASE
AGENT_HOME=$AGENT_BASE/core/12.1.0.2.0    ; export AGENT_HOME
AGENT_INST_HOME=$AGENT_BASE/agent_inst    ; export AGENT_INST_HOME

#
# Put new ORACLE_HOME binaries in path and remove old one if present
#
# Ensure that OLD_ORACLE_HOME is non-null and use to store current ORACLE_HOME if any
OLD_ORACLE_HOME=${ORACLE_HOME-NOTSET}
ORACLE_HOME=$AGENT_HOME ; export ORACLE_HOME
case "$PATH" in
  *$OLD_ORACLE_HOME*)
    PATH=`echo $PATH | sed "s;${OLD_ORACLE_HOME};${ORACLE_HOME};g"` ; export PATH ;;
esac
pathman $ORACLE_HOME/bin

# EMCLI variables
EMCLI_HOME=$ORACLE_HOME/emcli ; export EMCLI_HOME

# EM Diagnostics varirable
EMDIAG_HOME=$ORACLE_HOME/emdiag ; export EMDIAG_HOME
pathman $EMDIAG_HOME/bin

# Cleanup
unset pathman
