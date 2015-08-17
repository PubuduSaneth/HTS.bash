#!/bin/bash

#  checkScript.bash
#  
#
#  Created by PubuduSaneth on 7/17/14.
#

exit_if_notEmpty(){
# Exists if the error file is not empty

local errFile="$1"
local errCode="$2"
#echo $errFile
[[ ! -f "$errFile" ]] && { echo -e "Looking for a missing file - Error Code:$errCode " ; exit 0 ; }
if [ -s "$errFile" ]
then
echo -e "$errFile - not empty: ErrCode $errCode"
exit
else
[[ $errCode != 0 ]] && { echo -e "\tCheck $errCode: OK" ; }
fi
}

exit_if_notFound(){
# Exists if the pattern <"Total runtime"> is not found

local infoFile="$1"
local errCode=$2

[[ ! -f "$infoFile" ]] && { echo -e "Looking for a missing file - Error Code:$errCode " ; exit 0 ; }

if [ $(grep -c -i "Total runtime" $infoFile) == 0 ]
then
echo -e "Total runtime: not found in $infoFile: ErrCode $errCode"
exit
else
[[ $errCode != 0 ]] && { echo -e "\tCheck $errCode: OK" ; }
fi
}

exit_if_found(){
# Exists if the pattern <"Exception"> is found

local infoFile="$1"
local errCode="$2"
[[ ! -f "$infoFile" ]] && { echo -e "Looking for a missing file - Error Code:$errCode " ; exit 0 ; }
if [ $(grep -c -i "Exception" $infoFile) -ne 0 ]
then
echo -e "Exception in $infoFile: ErrCode $errCode"
exit
else
[[ $errCode != 0 ]] && { echo -e "\tCheck $errCode: OK" ; }
fi

}
