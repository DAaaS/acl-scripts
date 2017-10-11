#!/bin/bash

#
# This script applies AD uid permissions to the home directories used by the
# current analysis cluster.
#

FED_IDS="fedid1 fedid2 fedid3"

TEST=true
BASE_DIR="${1:-/test}"
INFO_LOG="info.log"
ERROR_LOG="error.log"
ACL_LOG="acl.log"

rm -f $ERROR_LOG $INFO_LOG $ACL_LOG

# loop over Federal IDs
for fedid in $FED_IDS
do
    if [ ! -d "${BASE_DIR}/${fedid}" ]
    then
        echo "Home directory ${BASE_DIR}/${fedid} not found" | tee -a $ERROR_LOG
        continue
    fi

    user_info=$(getent passwd ${fedid})
    user_ret=$?

    # check that Active Directory contains account matching the FEDID
    if [ $user_ret -eq 0 ]
    then
        echo "Adding user permissions for '${fedid}' on directory '${BASE_DIR}/${fedid}'" | tee -a $INFO_LOG

        # set user ACL rule as well as default ACL rule which means
        if [ "$TEST" = false ]
        then 
            setfacl -Rm d:u:${fedid}:rwx,u:${fedid}:rwx ${BASE_DIR}/${fedid} >> $ACL_LOG
        else
            setfacl --test -Rm d:u:${fedid}:rwx,u:${fedid}:rwx ${BASE_DIR}/${fedid} >> $ACL_LOG
        fi
    elif [ $group_ret -eq 2 ]
    then
        echo "User ${fedid} not found in Active Directory" | tee -a $ERROR_LOG
    else
        echo "Something went wrong with the getent cmd on ${fedid}" | tee -a $ERROR_LOG
    fi
done
