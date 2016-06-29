# ! /bin/sh
######################################################
# NAME: OEMenv.sh
#
# DESC: Configures environment for Oracle Enterprise Manager
#       (OEM) access.
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
# 2013/03/11 cgwong - Creation
# 2013/04/09 cgwong - Corrected ORACLE_INSTANCE_NAME to INSTANCE_NAME
# 2014/03/04 cgwong - v2.0.0 Updated header comments, updated variables
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

# Middleware variables
MW_HOME=$ORA_BASE/fmw          ; export MW_HOME
WL_HOME=$MW_HOME/wlserver_10.3 ; export WL_HOME
INSTANCE_NAME=gc_inst          ; export INSTANCE_NAME

# Domain variables
DOMAIN_NAME=GCDomain                                                   ; export DOMAIN_NAME
DOMAIN_HOME=$MW_HOME/$INSTANCE_NAME/user_projects/domains/$DOMAIN_NAME ; export DOMAIN_HOME
DOMAIN_PORT=7102                                                       ; export DOMAIN_PORT
DOMAIN_HOST=`uname -n`                                                 ; export DOMAIN_HOST

# OMS variables
ORACLE_INSTANCE_NAME=$INSTANCE_NAME                ; export ORACLE_INSTANCE_NAME
OMS_HOME=$MW_HOME/oms                              ; export OMS_HOME
OMS_INSTANCE_HOME=$MW_HOME/$INSTANCE_NAME          ; export OMS_INSTANCE_HOME
ORACLE_CONFIG_HOME=$OMS_INSTANCE_HOME/em/EMGC_OMS1 ; export ORACLE_CONFIG_HOME

#
# Put new JAVA_HOME in path and remove old one if present
#
# Ensure that OLD_JAVA_HOME is non-null and use to store current JAVA_HOME if any
OLD_JAVA_HOME=${JAVA_HOME-NOTSET}
JAVA_HOME=$MW_HOME/jdk16/jdk ; export JAVA_HOME
case "$PATH" in
  *$OLD_JAVA_HOME*)
    PATH=`echo $PATH | sed "s;${OLD_JAVA_HOME};${JAVA_HOME};g"` ; export PATH ;;
  *)
    pathman $JAVA_HOME/bin ;;
esac

#
# Put new OID binaries in path and remove old one if present
#
# Ensure that OLD_ORACLE_HOME is non-null and use to store current ORACLE_HOME if any
OLD_ORACLE_HOME=${ORACLE_HOME-NOTSET}
ORACLE_HOME=$OMS_HOME ; export ORACLE_HOME
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
