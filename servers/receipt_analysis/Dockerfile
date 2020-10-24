FROM ubuntu:latest
MAINTAINER JUNGHO CHEON <cjsgh85@gmail.com>

USER root

ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update -y
RUN apt-get install -y apache2
RUN apt-get install -y python3-pip python-dev build-essential

COPY . /app
WORKDIR /app
RUN pip3 install -r requirements.txt

EXPOSE 9999

CMD ["python3", "-u", "receiptWebSocket.py"]
