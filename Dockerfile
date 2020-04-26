FROM python:3.6

ENV FLASK_APP "app/app.py"
ENV FLASK_ENV "development"

# We copy just the requirements.txt first to leverage Docker cache
COPY ["./requirements.txt", "/app/requirements.txt"]

WORKDIR /app

RUN pip3 install --upgrade pip && \
    pip3 install -r requirements.txt

COPY [".", "/app/"]
ENTRYPOINT [ "mkdir", "/app/logs" ]

EXPOSE 5000

#CMD ["python", "app.py", "runserver", "--host=0.0.0.0"]
CMD ["flask", "run", "--host=0.0.0.0"]
