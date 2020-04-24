FROM python:3.6

MAINTAINER Your Name "javier.ochoa@osram-continental.com"

# We copy just the requirements.txt first to leverage Docker cache
COPY ./requirements.txt /app/requirements.txt
COPY ./*.py /app/
COPY ./docker*.sh /app/

WORKDIR /app

RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt

VOLUME . /app/outside/

CMD [ "cd", "/app/outside/" ]
CMD [ "docker-start-app.sh" ]