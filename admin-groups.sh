#!/bin/bash

#
# This script loops through all of the ISIS RB directories and applies ACL group
# permissions for ISIS admins based on entries in Active Directory.
#
# The directory structure is as follow:
#
# /basedirectory/INSTRUMENT_NAME/RBNumber/RBNUMBER/...
# 
# INSTRUMENT = ALF, GEM, ... WISH
# RBNUMBER = RB1510299, RB1510300 ...
#
#

TEST=true
BASE_DIR="${1:-/rbtest/}"
INFO_LOG="info.log"
ERROR_LOG="error.log"
ACL_LOG="acl.log"


ADMIN_GROUP_NAME="$1"

if [[ -z "$ADMIN_GROUP_NAME" ]]; then
    echo "Please specify the name of the admin group"
    exit 1
fi

group_info=$(getent group ${ADMIN_GROUP_NAME})
group_ret=$?

if [ $group_ret -ne 0 ]
then
    echo "Admin group not found"
    exit 1
fi

rm -f $ERROR_LOG $INFO_LOG $ACL_LOG

# loop through instrument directories
for inst_dir in $BASE_DIR*
do
    [ -d "${inst_dir}" ] || continue # if not a directory, skip

    # loop over RB directories
    for rb_dir in $inst_dir/RBNumber/*
    do
        echo "----------------------------" | tee -a $INFO_LOG 
        echo "Found RB directory: ${rb_dir}" | tee -a $INFO_LOG

        echo "Setting group to '${ADMIN_GROUP_NAME}' on directory '${rb_dir}'" | tee -a $INFO_LOG

        # set group ACL rule as well as default ACL rule which means
        # rules will be applied to any new files or directories created
        if [ "$TEST" = false ]
        then 
            setfacl -Rm d:g:$ADMIN_GROUP_NAME:rwx,g:$ADMIN_GROUP_NAME:rwx ${rb_dir} >> $ACL_LOG
        else
            setfacl --test -Rm d:g:$ADMIN_GROUP_NAME:rwx,g:$ADMIN_GROUP_NAME:rwx ${rb_dir} >> $ACL_LOG
        fi
    done
done