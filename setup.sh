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

# creation de la couche dechets_pav
curl -v -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "<featureType><name>dechets_pav</name><nativeBoundingBox><minx>1.80105710029602</minx><maxx>2.073606729507446</maxx><miny>47.80998992919922</miny><maxy>47.96966552734375</maxy></nativeBoundingBox><latLonBoundingBox><minx>-77.519584826619</minx><maxx>-77.51958383012473</maxx><miny>40.1125166204243</miny><maxy>40.112517088402946</maxy></latLonBoundingBox></featureType>"  "http://${GEOSERVER_HOST}:${GEOSERVER_PORT}/geoserver/rest/workspaces/toto/datastores/td2/featuretypes"

# creation de la couche
curl -v -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "<featureType><name>espaces_verts_voirie</name><nativeBoundingBox><minx>1.873639583587646</minx><maxx>1.945206046104431</maxx><miny>47.81800842285156</miny><maxy>47.93342971801758</maxy></nativeBoundingBox><latLonBoundingBox><minx>-77.51958456214624</minx><maxx>-77.51958428993171</maxx><miny>40.11251665041855</miny><maxy>40.11251697486524</maxy></latLonBoundingBox></featureType>"  "http://${GEOSERVER_HOST}:${GEOSERVER_PORT}/geoserver/rest/workspaces/toto/datastores/td2/featuretypes"

