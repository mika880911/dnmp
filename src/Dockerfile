FROM ubuntu:20.04
MAINTAINER Mika
COPY ./install.sh /dnmp/src/install.sh
COPY ./ca.crt /usr/local/share/ca-certificates/ca.crt

RUN /dnmp/src/install.sh
WORKDIR /var/www
CMD ["/dnmp/src/entry-point.sh"]
