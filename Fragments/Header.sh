####################################################################################################
#        License information
####################################################################################################
#
#        THE SCRIPTS ARE PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
#        INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
#        AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
#        I BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
#        OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
#        SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
#        INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
#        CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
#        ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
#        THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
####################################################################################################
# 
#        Written by: Mischa van der Bent
#
#        DESCRIPTION
#        This script is inspired by the CIS Benchmark script of Jamf Professional Services 
#        https://github.com/jamf/CIS-for-macOS-Catalina-CP
#        And will look for a managed Configuration Profile (com.cis.benchmark.plist) and checks, 
#        remediation (if needend) and report.
#        The Security Score can be set with the Jamf Pro Custom Schema json file.
#        Reports are stored in /Library/Security/Reports.
# 
#        REQUIREMENTS
#        Compatible with Big Sure macOS 11.x
#        Compatible with Monterey macOS 12.x 
# 
####################################################################################################
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

####################################################################################################
#        Directory/Path/Variables
####################################################################################################

CISBenchmarkReportPath="/Library/Security/Reports"
CISBenchmarkReport=${CISBenchmarkReportPath}/CISBenchmarkReport.csv
CISBenchmarkReportEA=${CISBenchmarkReportPath}/CISBenchmarkReportEA.txt
plistlocation="/Library/Managed Preferences/com.cis.benchmark.plist"
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')

####################################################################################################
#        Functions
####################################################################################################

function runAudit() {
	## Check if scoring file is present
	if [[ ! -e ${plistlocation} ]]; then
		## No scoring file present, reporting all
		auditResult="1"
		scored=""
		echo "OrgScore ${audit}"
	else
		auditResult=$(defaults read "${plistlocation}" "${orgScore}" 2>&1)
		if [[ "${auditResult}" == "1" ]]; then
			scored="Scored"
			echo "OrgScore ${audit}"
		else
			scored="NOT Scored"
		fi
	fi
}

function runAsUser() {
	if [[ "${currentUser}" != "loginwindow" ]]; then
		uid=$(id -u "${currentUser}")
		launchctl asuser "$uid" sudo -u "${currentUser}" "$@"
	fi
}

function getPrefValue() { # $1: domain, $2: key
	python -c "from Foundation import CFPreferencesCopyAppValue; print(CFPreferencesCopyAppValue('$2', '$1'))"
}

function getPrefValueNested() { # $1: domain, $2: key
	python -c "from Foundation import CFPreferencesCopyAppValue; print(CFPreferencesCopyAppValue('$2', '$1'))['$3']"
}

function getPrefValuerunAsUser() { # $1: domain, $2: key
	runAsUser python -c "from Foundation import CFPreferencesCopyAppValue; print(CFPreferencesCopyAppValue('$2', '$1'))"
}

function getPrefIsManaged() { # $1: domain, $2: key
	python -c "from Foundation import CFPreferencesAppValueIsForced; print(CFPreferencesAppValueIsForced('$2', '$1'))"
}

function getPrefIsManagedrunAsUser() { # $1: domain, $2: key
	runAsUser python -c "from Foundation import CFPreferencesAppValueIsForced; print(CFPreferencesAppValueIsForced('$2', '$1'))"
}

function CISBenchmarkReportFolder() {
	if [[ -d ${CISBenchmarkReportPath} ]]; then
		rm -Rf "${CISBenchmarkReportPath}"
		mkdir -p "${CISBenchmarkReportPath}"
		else
		mkdir -p "${CISBenchmarkReportPath}"
	fi
}

function printReport(){
	echo "${audit};${CISLevel};${scored};${result};${prefIsManaged};${appidentifier};${value};${prefValue};${method};${comment};${remediate}">>"${CISBenchmarkReport}"
}

function emptyVariables(){
	prefIsManaged=""
	appidentifier=""
	value=""
	prefValue=""
	result=""
	method=""
	comment=""
	remediate=""
}

####################################################################################################
#        Start Security report script
####################################################################################################

echo ""
echo "*** Security report started - $(date -u)"

# Check for admin/root permissions
if [[ "$(id -u)" != "0" ]]; then
	echo ""
	echo "*** Script must be run as root, or have root privileges (ie. sudo)." 1>&2
	echo "*** Quitting..."
	echo ""
	exit 1
fi

# Check for Big sur
osVersion=$(sw_vers -productVersion)
buildVersion=$(sw_vers -buildVersion)
if [[ "$osVersion" != "11."* ]] && [[ "$osVersion" != "12."* ]]; then
		echo ""
		echo "*** This script support macOS Big Sur and Monterey only"
		echo "*** Quitting..."
		echo ""
		exit 1
	else
		if [[ "$osVersion" = "11."* ]]; then
			echo "*** Current version - macOS Big Sur ${osVersion} (${buildVersion})"
			echo "" 1>&2
		else
			echo "*** Current version - macOS Monterey ${osVersion} (${buildVersion})"
			echo "" 1>&2
		fi
	fi

# Create report Folder/Files
CISBenchmarkReportFolder

# Create csv file headers
echo "Audit Number;Level;Scored;Result;Managed;Preference domain;Option;Value;Method;Comments;Remediate" >> "${CISBenchmarkReport}"

####################################################################################################
####################################################################################################
################################### DO NOT EDIT BELOW THIS LINE ####################################
####################################################################################################
####################################################################################################
