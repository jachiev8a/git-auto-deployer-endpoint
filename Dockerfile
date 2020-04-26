FROM python:3.6

# We copy just the requirements.txt first to leverage Docker cache
COPY ["./requirements.txt", "/app/requirements.txt"]

WORKDIR /app

RUN pip3 install --upgrade pip && \
    pip3 install -r requirements.txt

COPY [".", "/app/"]

CMD ["flask run --host=0.0.0.0"]
