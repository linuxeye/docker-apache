#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###################################################################################################
###################################################################################################
###
### GLOBAL VARIABLES
###
###################################################################################################
###################################################################################################

### The following env variables are set inside the Dockerfiles
###   MY_USER
###   MY_GROUP
###   HTTPD_START
###   HTTPD_RELOAD

###
### Base path for main (default) document root
###
MAIN_DOCROOT_BASE="/var/www/default"
MASS_DOCROOT_BASE="/shared/httpd"

###
### Path to scripts to source
###
ENTRYPOINT_DIR="/docker-entrypoint.d"              # All entrypoint scripts
VHOSTGEN_TEMPLATE_DIR="/etc/vhost-gen/templates"   # vhost-gen default templates
VHOSTGEN_CUST_TEMPLATE_DIR="/etc/vhost-gen.d"      # vhost-gen custom templates (must be mounted to add)

###
### Defailt aliases copied from previous images, just for the record
###
#MAIN_VHOST_ALIASES_ALLOW='/devilbox-api/:/var/www/default/api, /vhost.d/:/etc/httpd'
#MASS_VHOST_ALIASES_ALLOW='/devilbox-api/:/var/www/default/api:http(s)?://(.*)$'

###
### Wait this many seconds to start watcherd after httpd has been started
###
WATCHERD_STARTUP_DELAY="3"



###################################################################################################
###################################################################################################
###
### INCLUDES
###
###################################################################################################
###################################################################################################

###
### Bootstrap
###
# shellcheck disable=SC1090,SC1091
. "${ENTRYPOINT_DIR}/bootstrap/bootstrap.sh"



###
### Source available entrypoint scripts
###
# shellcheck disable=SC2012
for f in $( ls -1 "${ENTRYPOINT_DIR}/"*.sh | sort -u ); do
	# shellcheck disable=SC1090
	. "${f}"
done



###################################################################################################
###################################################################################################
###
### MAIN ENTRYPOINT
###
###################################################################################################
###################################################################################################

# -------------------------------------------------------------------------------------------------
# SET ENVIRONMENT VARIABLES AND DEFAULT VALUES
# -------------------------------------------------------------------------------------------------

###
### Show Debug level
###
log "info" "Entrypoint debug: $( env_get "DEBUG_ENTRYPOINT" )"
log "info" "Runtime debug: $( env_get "DEBUG_RUNTIME" )"


###
### Show environment vars
###
log "info" "-------------------------------------------------------------------------"
log "info" "Environment Variables (set/default)"
log "info" "-------------------------------------------------------------------------"

log "info" "Variables: General:"
env_var_export "NEW_UID"
env_var_export "NEW_GID"
env_var_export "TIMEZONE" "UTC"
env_var_export "DOCKER_LOGS" "1"


# -------------------------------------------------------------------------------------------------
# VERIFY ENVIRONMENT VARIABLES
# -------------------------------------------------------------------------------------------------

log "info" "-------------------------------------------------------------------------"
log "info" "Validate Settings"
log "info" "-------------------------------------------------------------------------"

log "info" "Settings: General:"
env_var_validate "NEW_UID"
env_var_validate "NEW_GID"
env_var_validate "TIMEZONE"
env_var_validate "DOCKER_LOGS"



# -------------------------------------------------------------------------------------------------
# APPLY SETTINGS
# -------------------------------------------------------------------------------------------------

log "info" "-------------------------------------------------------------------------"
log "info" "Apply Settings"
log "info" "-------------------------------------------------------------------------"

###
### Change uid/gid
###
set_uid "${NEW_UID}" "${MY_USER}"
set_gid "${NEW_GID}" "${MY_USER}" "${MY_GROUP}"

###
### Set timezone
###
set_timezone "${TIMEZONE}"

###
### Fix directory/file permissions (in case it is mounted)
###
fix_perm "/var/log/httpd" "0"

# -------------------------------------------------------------------------------------------------
# MAIN ENTRYPOINT
# -------------------------------------------------------------------------------------------------

# shellcheck disable=SC2153
_HTTPD_VERSION="$( eval "${HTTPD_VERSION}" || true )"  # Set via Dockerfile

log "info" "-------------------------------------------------------------------------"
log "info" "Main Entrypoint"
log "info" "-------------------------------------------------------------------------"

log "done" "Starting Apache: ${_HTTPD_VERSION}"
exec "${HTTPD_START}"
