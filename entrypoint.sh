#!/bin/sh -ue

# configration for rattic
: "${DEBUG:=false}"
: "${LOGLEVEL:=ERROR}"
: "${HOSTNAME:=localhost}"
: "${URLROOT:=/}"
: "${TIMEZONE:=UTC}"
: "${SECRETKEY:=areallybadsecretkeypleasechangebeforeusinginproduction}"
: "${PASSWORD_EXPIRY_DAYS:=360}"
: "${DB_HOSTNAME:=db}"
: "${DB_PORT:=3306}"
: "${DB_DBNAME:=rattic}"
: "${DB_USERNAME:=rattic}"
#: "${LDAP_URI:=ldap://ldap}" # Leave this blank so that LDAP can be disabled
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
urlroot = $URLROOT

[filepaths]
static = /opt/rattic/static

[database]
engine = django.db.backends.mysql
host = $DB_HOSTNAME
port = $DB_PORT
name = $DB_DBNAME
user = $DB_USERNAME
EOF

if [ -n "$DB_PASSWORD" ]; then
cat >> /opt/rattic/conf/local.cfg <<EOF
password = $DB_PASSWORD
EOF
fi

#Begin LDAP config
if [ -n "$LDAP_URI" ]
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
fi # End LDAP


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
