#!/bin/bash
#
# This script disables, deletes, and/or archives users on the local system.
#
# To reenable a user use the following command:
#	$ chage -E -1 ${USERNAME}
#

ARCHIVE_DIR='/archive'

usage() {
	echo "Usage: ${0} [-dra] USER [USER]..." >&2
	echo "Disable a local Linux account." >&2
	echo "	-a	Creates an archive of the home directory associated with the account(s)" >&2
	echo "	-r	Removes the home directory associated with the account(s)." >&2
	echo "	-d	Deletes the account(s) instead of disabling." >&2
	exit 1
}

# Require root privileges
if [[ "${UID}" -ne 0 ]]
then
	echo "Please run script with sudo or as root." >&2
	exit 1
fi

# Parse options
while getopts dra OPTION
do
	case ${OPTION} in
		a)	ARCHIVE='true' ;;
		r)	REMOVE_OPTION='-r' ;;
		d)	DELETE_USER='true' ;;
		?)	usage ;;
	esac
done

# Remove the options while leaving the remaining arguments.
shift "$(( OPTIND - 1 ))"

# If no arguments are supplied, display usage.
if [[ "${#}" -lt 1 ]]
then
	usage
fi

# Loop through all the usernames supplied as arguments.
for USERNAME in "${@}"
do
	echo "Processing user: ${USERNAME}"
	
	# Make sure the UID of the account is at least 1000.
	USERID=$(id -u ${USERNAME})
	if [[ "${USERID}" -lt 1000 ]]
	then
		echo "Refusing to remove the ${USERNAME} account with UID ${USERID}." >&2
		exit 1
	fi
	
	# Create an archive if requested to do so.
	if [[ "${ARCHIVE}" = 'true' ]]
	then
		# Make sure the ARCHIVE_DIR directory exists.
		if [[ ! -d "${ARCHIVE_DIR}" ]]
		then
			echo "Creating archive directory: ${ARCHIVE_DIR}"
			mkdir -p ${ARCHIVE_DIR}
			if [[ "${?}" -ne 0 ]]
			then
				echo "The archive directory ${ARCHIVE_DIR} could not be created." >&2
				exit 1
			fi
		fi
		
		# Archive the user's home directory and move it to the ARCHIVE_DIR
		HOME_DIR="/home/${USERNAME}"
		ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
		if [[ -d "${HOME_DIR}" ]]
		then
			echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
			tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
			if [[ "${?}" -ne 0 ]]
			then
				echo "Could not create ${ARCHIVE_FILE}." >&2
				exit 1
			fi
		else
			echo "${HOME_DIR} does not exist or is not a directory." >&2
			exit 1
		fi
	fi
	
	if [[ "${DELETE_USER}" = 'true' ]]
	then
		#Delete the user.
		userdel ${REMOVE_OPTION} ${USERNAME}
		
		# Check to see if the userdel command succeeded.
		if [[ "${?}" -ne 0 ]]
		then
			echo "The account ${USERNAME} was NOT deleted." >&2
			exit 1
		fi
		echo "The account ${USERNAME} was deleted."
	else
		chage -E 0 ${USERNAME}
		
		# Check to see if the chage command succeeded.
		if [[ "${?}" -ne 0 ]]
		then
			echo "The account ${USERNAME} was NOT disabled." >&2
			exit 1
		fi
		echo "The account ${USERNAME} was disabled."
	fi
done

exit 0
		