#!/bin/bash
############################################################################
#
# Linux on Hyper-V and Azure Test Code, ver. 1.0.0
# Copyright (c) Microsoft Corporation
#
# All rights reserved.
# Licensed under the Apache License, Version 2.0 (the ""License"");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR
# PURPOSE, MERCHANTABLITY OR NON-INFRINGEMENT.
#
# See the Apache Version 2.0 License for specific language governing
# permissions and limitations under the License.
#
############################################################################
# VerifyKeyValue.sh
#
# This script will verify a key is present in the speicified pool or not. 
# The Parameters provided are - Test case number, Key Name. Value, Pool number
# This test should be run after the KVP Basic test.
#
#############################################################

ICA_TESTRUNNING="TestRunning"      # The test is running
ICA_TESTCOMPLETED="TestCompleted"  # The test completed successfully
ICA_TESTABORTED="TestAborted"      # Error during setup of test
ICA_TESTFAILED="TestFailed"        # Error while performing the test

CONSTANTS_FILE="constants.sh"

LogMsg()
{
    echo `date "+%a %b %d %T %Y"` : ${1}    # To add the timestamp to the log file
}

UpdateTestState()
{
    echo $1 > ~/state.txt
}

#
# Create the state.txt file so ICA knows we are running
#
LogMsg "Updating test case state to running"
UpdateTestState $ICA_TESTRUNNING

#
# Delete any summary.log files from a previous run
#
rm -f ~/summary.log
touch ~/summary.log

#
# Source the constants.sh file to pickup definitions from
# the ICA automation
#
if [ -e ./${CONSTANTS_FILE} ]; then
    source ${CONSTANTS_FILE}
else
    msg="Error: no ${CONSTANTS_FILE} file"
    LogMsg "$msg"
    echo "$msg" >> ~/summary.log
    UpdateTestState $ICA_TESTABORTED
    exit 10
fi

#
# Make sure constants.sh contains the variables we expect
#
if [ "${TC_COVERED:-UNDEFINED}" = "UNDEFINED" ]; then
    msg="The test parameter TC_COVERED is not defined in ${CONSTANTS_FILE}"
    LogMsg "$msg"
    echo "$msg" >> ~/summary.log
    UpdateTestState $ICA_TESTABORTED
    exit 20
fi

if [ "${Key:-UNDEFINED}" = "UNDEFINED" ]; then
    msg="The test parameter Key is not defined in ${CONSTANTS_FILE}"
    LogMsg "$msg"
    echo "$msg" >> ~/summary.log
    UpdateTestState $ICA_TESTABORTED
    exit 30
fi

if [ "${Value:-UNDEFINED}" = "UNDEFINED" ]; then
    msg="The test parameter Value is not defined in ${CONSTANTS_FILE}"
    LogMsg "$msg"
    echo "$msg" >> ~/summary.log
    UpdateTestState $ICA_TESTABORTED
    exit 40
fi

if [ "${Pool:-UNDEFINED}" = "UNDEFINED" ]; then
    msg="The test parameter Pool number is not defined in ${CONSTANTS_FILE}"
    LogMsg "$msg"
    echo "$msg" >> ~/summary.log
    UpdateTestState $ICA_TESTABORTED
    exit 50
fi

#
# Echo TCs we cover
#
echo "Covers ${TC_COVERED}" > ~/summary.log

#
# Verify OS architecture
#
uname -a | grep x86_64
if [ $? -eq 0 ]; then
    msg="64 bit architecture was detected"
    LogMsg "$msg"
    kvp_client="kvp_client64"
else
    uname -a | grep i686
    if [ $? -eq 0 ]; then
        msg="32 bit architecture was detected"
        LogMsg "$msg"
        kvp_client="kvp_client32" 
    else 
        msg="Error: Unable to detect OS architecture"
        LogMsg "$msg"
        echo "$msg" >> ~/summary.log
        UpdateTestState $ICA_TESTABORTED
        exit 60
    fi
fi

#
# Make sure we have the kvp_client tool
#
if [ ! -e ~/${kvp_client} ]; then
    msg="Error: ${kvp_client} tool is not on the system"
    LogMsg "$msg"
    echo "$msg" >> ~/summary.log
    UpdateTestState $ICA_TESTABORTED
    exit 60
fi

chmod 755 ~/${kvp_client}

#
# verify that the Key Value is present in the specified pool or not.
#
~/${kvp_client} $Pool | grep "${Key}; Value: ${Value}"
if [ $? -ne 0 ]; then
        msg="Error: the KVP item is not in the pool"
	LogMsg "$msg"
	echo "$msg" >> ~/summary.log
	UpdateTestState $ICA_TESTFAILED
	exit 70
fi

LogMsg "Updating test case state to completed"
UpdateTestState $ICA_TESTCOMPLETED

exit 0