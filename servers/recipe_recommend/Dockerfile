FROM rackspacedot/python37

WORKDIR /app
ADD . /app
RUN pip3 install -r requirements.txt

CMD ["uwsgi","uwsgi.ini"]

