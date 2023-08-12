FROM ubuntu:20.04
MAINTAINER Mika
COPY ./ /dnmp/src
RUN /dnmp/src/install.sh
WORKDIR /var/www
CMD ["/dnmp/src/entry-point.sh"]
