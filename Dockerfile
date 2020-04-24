FROM ubuntu:16.04

MAINTAINER Your Name "javier.ochoa@osram-continental.com"

RUN apt-get update -y && \
    apt-get install -y python3.6

# We copy just the requirements.txt first to leverage Docker cache
COPY ./requirements.txt /app/requirements.txt
COPY ./*.py /app/
COPY ./docker*.sh /app/

WORKDIR /app

RUN pip install -r requirements.txt

VOLUME . /app/outside/

CMD [ "cd", "/app/outside/" ]
CMD [ "docker-start-app.sh" ]