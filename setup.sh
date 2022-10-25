#!/bin/bash


test_postgresql() {
  pg_isready -h "${PG_HOST}" -p "${PG_PORT}" -U postgres
}

count=0
# Chain tests together by using &&
until ( test_postgresql )
do
  count=$((count+1))
  if [ ${count} -gt 62 ]
  then
    echo "Service postgis didn't become ready in time"
    exit 1
  fi
  sleep 1
done


psql -h "${PG_HOST}" -p "${PG_PORT}" -U postgres -c "CREATE USER toto with password '${PGPASSWORD}'"
psql -h "${PG_HOST}" -p "${PG_PORT}" -U postgres -c "CREATE DATABASE toto OWNER=toto"
psql -h "${PG_HOST}" -p "${PG_PORT}" -d toto -U postgres -c "create extension postgis"
psql -h "${PG_HOST}" -p "${PG_PORT}" -d toto -U toto < base.dump


# geo server api setup



declare HOST="http://${GEOSERVER_HOST}:${GEOSERVER_PORT}/geoserver/rest/about/system-status"
declare STATUS=200
declare TIMEOUT=300

HOST=$HOST STATUS=$STATUS timeout --foreground -s TERM $TIMEOUT bash -c \
    'while [[ ${STATUS_RECEIVED} != ${STATUS} ]];\
        do STATUS_RECEIVED=$(curl -s -o /dev/null -L -w ''%{http_code}'' ${HOST} -u admin:geoserver) && \
        echo "received status: $STATUS_RECEIVED" && \
        sleep 1;\
    done;
    echo success with status: $STATUS_RECEIVED'

# creation du workspace
curl -v -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "<workspace><name>toto</name></workspace>" "http://${GEOSERVER_HOST}:${GEOSERVER_PORT}/geoserver/rest/workspaces"


# creation du store
curl -v -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "<dataStore><name>td2</name><connectionParameters><host>${PG_HOST}</host><port>${PG_PORT}</port><database>toto</database><user>toto</user><passwd>${PGPASSWORD}</passwd><dbtype>postgis</dbtype></connectionParameters></dataStore>"  "http://${GEOSERVER_HOST}:${GEOSERVER_PORT}/geoserver/rest/workspaces/toto/datastores"
