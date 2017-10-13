#!/bin/bash

#
# This script applies AD uid permissions to the home directories used by the
# current analysis cluster.
#

FED_IDS="fedid1 fedid2 fedid3"

TEST=true
HOME_DIR_NOMACHINE="${1:-/test}"
HOME_DIR_IDAAAS="${2:-/test2}"
INFO_LOG="info.log"
ERROR_LOG="error.log"
ACL_LOG="acl.log"

rm -f $ERROR_LOG $INFO_LOG $ACL_LOG

# loop over Federal IDs
for fedid in $FED_IDS
do
    if [ ! -d "${HOME_DIR_NOMACHINE}/${fedid}" ]
    then
        echo "Home directory ${HOME_DIR_NOMACHINE}/${fedid} not found" | tee -a $ERROR_LOG
        continue
    fi

    user_info=$(getent passwd ${fedid})
    user_ret=$?

    # check that Active Directory contains account matching the FEDID
    if [ $user_ret -eq 0 ]
    then
        echo "Adding user permissions for '${fedid}' on directory '${HOME_DIR_NOMACHINE}/${fedid}'" | tee -a $INFO_LOG

        # set user ACL rule as well as default ACL rule which means
        if [ "$TEST" = false ]
        then 
            setfacl -Rm d:u:${fedid}:rwx,u:${fedid}:rwx ${HOME_DIR_NOMACHINE}/${fedid} >> $ACL_LOG

            # add symlink to IDAaaS home directory pointing to their NoMachine home directory
            ln -s ${HOME_DIR_NOMACHINE}/${fedid} ${HOME_DIR_IDAAAS}/${fedid}/NoMachine
        else
            setfacl --test -Rm d:u:${fedid}:rwx,u:${fedid}:rwx ${HOME_DIR_NOMACHINE}/${fedid} >> $ACL_LOG
        fi
    elif [ $group_ret -eq 2 ]
    then
        echo "User ${fedid} not found in Active Directory" | tee -a $ERROR_LOG
    else
        echo "Something went wrong with the getent cmd on ${fedid}" | tee -a $ERROR_LOG
    fi
done
