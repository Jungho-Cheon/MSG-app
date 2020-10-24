FROM nginx:latest
MAINTAINER JUNGHO CHEON <cjsgh85@gmail.com>

USER root

RUN apt-get update
RUN apt-get install -y wget
RUN apt-get install -y make

RUN wget https://projects.unbit.it/downloads/uwsgi-latest.tar.gz
RUN tar zxvf uwsgi-latest.tar.gz
RUN cd uwsgi-2.0.19.1
RUN make .

COPY ./conf.d /etc/nginx/conf.d
WORKDIR /etc/nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
