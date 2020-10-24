#!/bin/sh

docker rm -f `docker ps -aq`

docker build --tag msg-nginx ./nginx/
docker build --tag msg-receipt-analysis ./receipt_analysis/
docker build --tag msg-search-ingredient ./search_ingredients/
docker build --tag msg-recipe-recommend ./recipe_recommend/

docker rmi `docker images -f "dangling=true" -q`

docker-compose up
