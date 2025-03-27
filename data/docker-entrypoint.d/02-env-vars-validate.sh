#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to validate the given environment variables
###


# -------------------------------------------------------------------------------------------------
# MAIN VALIDATOR
# -------------------------------------------------------------------------------------------------

###
### Validate environment variables
###
### This function is just a gate-keeper and calls the validate_<ENV>()
### function for each environment variable to ensure the assigned
### value is correct.
###
env_var_validate() {
	local name="${1}"
	local value

	value="$( env_get "${name}" )"
	func="validate_$( echo "${name}" | awk '{print tolower($0)}' )"

	# Call specific validator function: validate_<ENV>()
	$func "${name}" "${value}"
}



# -------------------------------------------------------------------------------------------------
# VALIDATE FUNCTIONS: GENERAL
# -------------------------------------------------------------------------------------------------

###
### Validate NEW_UID
###
validate_new_uid() {
	local name="${1}"
	local value="${2}"

	# Ignore if empty (no change)
	if [ -z "${value}" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(not specified)"
		return 0
	fi
	if ! is_uid "${value}"; then
		_log_env_valid "invalid" "${name}" "${value}" "Must be positive integer"
		exit 1
	fi
	_log_env_valid "valid" "${name}" "${value}" "User ID (uid)" "${value}"
}


###
### Validate NEW_GID
###
validate_new_gid() {
	local name="${1}"
	local value="${2}"

	# Ignore if empty (no change)
	if [ -z "${value}" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(not specified)"
		return 0
	fi
	if ! is_gid "${value}"; then
		_log_env_valid "invalid" "${name}" "${value}" "Must be positive integer"
		exit 1
	fi
	_log_env_valid "valid" "${name}" "${value}" "Group ID (gid)" "${value}"
}


###
### Validate TIMEZONE
###
validate_timezone() {
	local name="${1}"
	local value="${2}"

	# Show ignored
	if [ "${value}" = "UTC" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(not specified)"
		return 0
	fi
	if [ ! -f "/usr/share/zoneinfo/${value}" ]; then
		_log_env_valid "invalid" "${name}" "${value}" "File '${value}' must exist in: " "/usr/share/zoneinfo/"
		exit 1
	fi
	_log_env_valid "valid" "${name}" "${value}" "Timezone" "${value}"
}


# -------------------------------------------------------------------------------------------------
# VALIDATE FUNCTIONS: MISC VALIDATION
# -------------------------------------------------------------------------------------------------


###
### Validate DOCKER_LOGS
###
validate_docker_logs() {
	local name="${1}"
	local value="${2}"
	_validate_bool "${name}" "${value}" "Log to" "0" "stdout and stderr" "/var/log/"
}


# -------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Generic validator for bool (Enabled/Disabled)
###
_validate_bool() {
	local name="${1}"
	local value="${2}"
	local message="${3}"
	local ignore="${4:-0}"
	local on="${5:-Enabled}"
	local off="${5:-Disabled}"

	# Validate
	if ! is_bool "${value}"; then
		_log_env_valid "invalid" "${name}" "${value}" "Must be 0 or 1" ""
		exit 1
	fi

	# Check if we ignore the value
	if [ "${ignore}" = "1" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(disabled)"
		return
	fi

	# Show status
	if [ "${value}" = "0" ]; then
		_log_env_valid "valid" "${name}" "${value}" "${message}" "${off}"
	else
		_log_env_valid "valid" "${name}" "${value}" "${message}" "${on}"
	fi
}


# -------------------------------------------------------------------------------------------------
# Logger
# -------------------------------------------------------------------------------------------------

###
### Use custom logger to log env variable validity
###
_log_env_valid() {
	local state="${1}"         # 'valid', `ignore` or 'invalid'
	local name="${2}"          # Variable name
	local value="${3}"         # Variable value
	local message="${4:-}"     # Message: what will happen (valid) or expected format (invalid)
	local message_val="${5:-}" # value for message

	local clr_valid="\033[0;32m"    # green
	local clr_invalid="\033[0;31m"  # red

	local clr_expect="\033[0;31m"   # red
	local clr_ignore="\033[0;34m"   # red

	local clr_ok="\033[0;32m"       # green
	local clr_fail="\033[0;31m"     # red
	local clr_rst="\033[0m"

	if [ "${state}" = "valid" ]; then
		log "ok" "$( \
			printf "${clr_ok}%-11s${clr_rst}%-8s${clr_valid}\$%-27s${clr_rst}%-20s${clr_valid}%s${clr_rst}\n" \
				"[OK]" \
				"Valid" \
				"${name}" \
				"${message}" \
				"${message_val}" \
		)" "1"
	elif [ "${state}" = "ignore" ]; then
		log "ok" "$( \
			printf "${clr_ok}%-11s${clr_rst}%-8s${clr_rst}\$%-27s${clr_ignore}%-20s${clr_rst}%s\n" \
				"[OK]" \
				"Valid" \
				"${name}" \
				"ignored" \
				"${message}" \
		)" "1"
	elif [ "${state}" = "invalid" ]; then
		log "err" "$( \
			printf "${clr_fail}%-11s${clr_rst}%-8s${clr_invalid}\$%-27s${clr_rst}${clr_invalid}'%s'${clr_rst}. %s${clr_expect}%s${clr_rst}\n" \
				"[ERR]" \
				"Invalid" \
				"${name}" \
				"${value}" \
				"${message}" \
				"${message_val}" \
		)" "1"
	else
		log "????" "Internal: Wrong value given to _log_env_valid"
		exit 1
	fi
}