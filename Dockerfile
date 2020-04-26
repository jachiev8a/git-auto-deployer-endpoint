FROM python:3.6

WORKDIR /app

# We copy just the requirements.txt first to leverage Docker cache
COPY ["./requirements.txt", "/app/requirements.txt"]

RUN pip3 install --upgrade pip && \
    pip3 install -r requirements.txt

# required token to pull requests
COPY ["./gitlab-token", "/app/gitlab-token"]

COPY [".", "/app/"]
RUN mkdir /app/logs

EXPOSE 5000

# flask environment variables
ENV FLASK_APP "app.py"
ENV FLASK_ENV "development"

# run server seen outside
CMD ["flask", "run", "--host=0.0.0.0"]
