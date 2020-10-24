#!/usr/bin/env bash

docker rm -f `docker ps -a -q`
docker build -t msg-websocket .
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
docker create -it -p 80:80 --name msg-test msg-websocket
docker start msg-test
docker exec -it msg-test /bin/bash