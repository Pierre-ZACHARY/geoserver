FROM postgis/postgis

WORKDIR /postgis/

RUN sed -i -e 's/us.archive.ubuntu.com/archive.ubuntu.com/g' /etc/apt/sources.list
RUN apt-get update; 
RUN apt-get install -y curl

COPY ./*.sh .
COPY ./*.dump .

RUN chmod +x ./setup.sh

ENTRYPOINT sh -c ./setup.sh


