FROM ubuntu:20.04
MAINTAINER Mika
COPY ./install.sh /dnmp/src/install.sh
RUN /dnmp/src/install.sh
WORKDIR /var/www
CMD ["/dnmp/src/entry-point.sh"]
