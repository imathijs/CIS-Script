#!/bin/zsh

projectfolder=$(dirname "${0:A}")

source ${projectfolder}/Header.sh

CISLevel="1"
audit="1.2 Enable Auto Update (Automated)"
orgScore="OrgScore1_2"
emptyVariables
# Verify organizational score
runAudit
# If organizational score is 1 or true, check status of client
if [[ "${auditResult}" == "1" ]]; then
	method="Profile"
	remediate="Configuration profile - payload > com.apple.SoftwareUpdate > AutomaticCheckEnabled=true"
	
	appidentifier="com.apple.SoftwareUpdate"
	value="AutomaticCheckEnabled"
	prefValue=$(getPrefValue "${appidentifier}" "${value}")
	prefIsManaged=$(getPrefIsManaged "${appidentifier}" "${value}")
	comment="Auto Update: Enabled"
	if [[ "${prefIsManaged}" == "True" && "${prefValue}" == "True" ]]; then
		countPassed=$((countPassed + 1))
		result="Passed"
	else
		if [[ "${prefValue}" == "True" ]]; then
			countPassed=$((countPassed + 1))
			result="Passed"
		else
			countFailed=$((countFailed + 1))
			result="Failed"
			comment="Auto Update: Disabled"
			
		fi
	fi
fi
printReport