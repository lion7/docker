#!/bin/bash

set -e

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$OPENERP_SERVER" ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi;
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

# Generate passwd file based on current uid
function generate_passwd_file() {
  export USER_ID=$(id -u)
  export GROUP_ID=$(id -g)
  grep -v ^odoo /etc/passwd > "$HOME/passwd"
  echo "odoo:x:${USER_ID}:${GROUP_ID}:Odoo:${HOME}:/bin/bash" >> "$HOME/passwd"
  export LD_PRELOAD=libnss_wrapper.so
  export NSS_WRAPPER_PASSWD=${HOME}/passwd
  export NSS_WRAPPER_GROUP=/etc/group
}
generate_passwd_file

case "$1" in
    -- | openerp-server)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec openerp-server "$@"
        else
            exec openerp-server "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        exec openerp-server "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
