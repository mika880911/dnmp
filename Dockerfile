FROM ubuntu:20.04
MAINTAINER Mika
COPY builds /builds
RUN bash /builds/build.sh
VOLUME "/var/lib/mysql"
WORKDIR /
CMD ["/builds/entrypoint.sh"]
