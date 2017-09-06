#!/bin/bash

#
# This script loops through all of the ISIS RB directories and applies ACL group
# permissions for experiment groups based on entries in Active Directory.
#
# The directory structure is as follow:
#
# /basedirectory/INSTRUMENT_NAME/RBNumber/RBNUMBER/...
# 
# INSTRUMENT = ALF, GEM, ... WISH
# RBNUMBER = RB1510299, RB1510300 ...
#
# The ACL group names are the same as the RB numbers.
#

TEST=true
BASE_DIR="${1:-/rbtest/}"
INFO_LOG="info.log"
ERROR_LOG="error.log"
ACL_LOG="acl.log"

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

        rbnumber=$(sed 's|.*\(RB[0-9]*\).*|\1|g' <<< ${rb_dir})
        group_info=$(getent group ${rbnumber})
        group_ret=$?

        # check that Active Directory contains a group with matching the RB number
        if [ $group_ret -eq 0 ]
        then
            echo "Setting group to '${rbnumber}' on directory '${rb_dir}'" | tee -a $INFO_LOG

            # set group ACL rule as well as default ACL rule which means
            # rules will be applied to any new files or directories created
            if [ "$TEST" = false ]
            then 
                setfacl -Rm d:g:$rbnumber:rwx,g:$rbnumber:rwx ${rb_dir} >> $ACL_LOG
            else
                setfacl --test -Rm d:g:$rbnumber:rwx,g:$rbnumber:rwx ${rb_dir} >> $ACL_LOG
            fi
        elif [ $group_ret -eq 2 ]
        then
            echo "Group ${rbnumber} not found in Active Directory" | tee -a $ERROR_LOG
        else
            echo "Something went wrong with the getent cmd on ${rbnumber}" | tee -a $ERROR_LOG
        fi
    done
done