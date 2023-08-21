#!/bin/bash

# Adds user to local system with username and comment specified on the command line.
# Randomly generates a password and displays the hostname, username, and password.
# Usage: ${0} USER_NAME [COMMENT]...

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
	echo "Root privileges required to run script." >&2
	exit 1
fi

# If the user doesn't supply at least one argument, then give them help.
if [[ "${#}" -lt 1 ]]
then
	echo "Usage: ${0} USER_NAME [COMMENT]..." >&2
	exit 1
fi

# First parameter is the user name.
USER_NAME="${1}"

# The remaining parameters are comments.
shift
COMMENT="${@}"
 
# Generate a password.
PASSWORD=$(date +%s%N | sha256sum | head -c48)

# Create the user with the password.
useradd -c "${COMMENT}" -m ${USER_NAME} &> /dev/null

# Check to see if the useradd command succeeded.
if [[ "${?}" -ne 0 ]]
then
	echo "Failed to create user: ${USER_NAME}" >&2
	exit 1
fi

# Set the password on the account.
echo "${USER_NAME}:${PASSWORD}" | chpasswd &> /dev/null

# Check if the password was set successfully.
if [[ "${?}" -ne 0 ]]
then
	echo "The password could not be set." >&2
	exit 1
fi

# Force password change at first login.
passwd -e ${USER_NAME} &> /dev/null

# Display the information on the command line.
echo "Username:"
echo "${USER_NAME}"
echo
echo "Password:"
echo "${PASSWORD}"
echo
echo "Host:"
echo "${HOSTNAME}"
echo

exit 0