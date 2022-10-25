FROM tomcat:9

EXPOSE 8080

COPY ./webapp/ /usr/local/tomcat/webapps


