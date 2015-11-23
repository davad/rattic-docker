#!/bin/sh -ue

# should be exported by linked postgres image
: "${POSTGRES_PORT_5432_TCP_ADDR:=postgres}"
: "${POSTGRES_PORT_5432_TCP_PORT:=5432}"

# configration for rattic
: "${DEBUG:=false}"
: "${LOGLEVEL:=ERROR}"
: "${HOSTNAME:=localhost}"
: "${TIMEZONE:=UTC}"
: "${SECRETKEY:=areallybadsecretkeypleasechangebeforeusinginproduction}"
: "${PASSWORD_EXPIRY_DAYS:=360}"
: "${POSTGRES_HOSTNAME:=$POSTGRES_PORT_5432_TCP_ADDR}"
: "${POSTGRES_PORT:=$POSTGRES_PORT_5432_TCP_PORT}"
: "${POSTGRES_DBNAME:=postgres}"
: "${POSTGRES_USERNAME:=postgres}"
: "${LDAP_URI:=ldap://ldap}"
: "${LDAP_STARTTLS:=false}"
: "${LDAP_REQCERT:=false}"
: "${LDAP_BASE:=dc=example,dc=com}"
: "${LDAP_USERBASE:=cn=users,cn=accounts,$LDAP_BASE}"
: "${LDAP_USERFILTER:=(uid=%(user)s)}"
: "${LDAP_GROUPBASE:=cn=groups,cn=accounts,$LDAP_BASE}"
: "${LDAP_GROUPFILTER:=(objectClass=groupofnames)}"
: "${LDAP_GROUPTYPE:=GroupOfNamesType}"
: "${LDAP_USERFIRSTNAME:=givenName}"
: "${LDAP_USERLASTNAME:=sn}"

cat > /opt/rattic/conf/local.cfg <<EOF
[ratticweb]
debug = $DEBUG
loglevel = $LOGLEVEL
hostname = $HOSTNAME
timezone = $TIMEZONE
secretkey = $SECRETKEY
passwordexpirydays = $PASSWORD_EXPIRY_DAYS

[filepaths]
static = /opt/rattic/static

[database]
engine = django.db.backends.postgresql_psycopg2
host = $POSTGRES_HOSTNAME
port = $POSTGRES_PORT
name = $POSTGRES_DBNAME
user = $POSTGRES_USERNAME
EOF

if [ -n "$POSTGRES_PASSWORD" ]; then
cat >> /opt/rattic/conf/local.cfg <<EOF
password = $POSTGRES_PASSWORD
EOF
fi

cat >> /opt/rattic/conf/local.cfg <<EOF
[ldap]
pwchange = false
uri = $LDAP_URI
requirecert = $LDAP_REQCERT
starttls = $LDAP_STARTTLS
userbase = $LDAP_USERBASE
userfilter = $LDAP_USERFILTER
groupbase = $LDAP_GROUPBASE
groupfilter = $LDAP_GROUPFILTER
grouptype = $LDAP_GROUPTYPE
userfirstname = $LDAP_USERFIRSTNAME
userlastname = $LDAP_USERLASTNAME
EOF

if [ -n "$LDAP_BINDDN" ]; then
    cat >> /opt/rattic/conf/local.cfg <<EOF
binddn = $LDAP_BINDDN
bindpw = $LDAP_BINDPW
EOF
fi

if [ -n "$LDAP_STAFFDN" ]; then
    cat >> /opt/rattic/conf/local.cfg <<EOF
staff = $LDAP_STAFFDN
EOF
fi


cd /opt/rattic
# for debugging config
[ 'false' != "$DEBUG" ] && cat conf/local.cfg

case "$1" in
    deploy)
        ./manage.py syncdb --noinput
        exec ./manage.py migrate --all # south
        ;;
    demosetup)
        exec ./manage.py demosetup
        ;;
    runserver)
        exec ./manage.py runserver --insecure 0.0.0.0:8000
        ;;
    serve)
        exec gunicorn -b 0.0.0.0:8000 ratticweb.wsgi
        ;;
    *)
        exec sh -c "$@"
        ;;
esac
