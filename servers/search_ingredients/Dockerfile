FROM ubuntu:latest
MAINTAINER JUNGHO CHEON <cjsgh85@gmail.com>

USER root

RUN apt-get update -y
RUN apt-get install -y python3-pip python-dev build-essential

COPY . /app
WORKDIR /app
RUN pip3 install -r requirements.txt

EXPOSE 9998

CMD ["python3", "-u", "searchIngredientWebSocket.py"]
