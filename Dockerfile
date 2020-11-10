FROM python:3.6

WORKDIR /app

# We copy just the requirements.txt first to leverage Docker cache
COPY ["./requirements.txt", "/app/requirements.txt"]

RUN pip3 install --upgrade pip && \
    pip3 install -r requirements.txt

COPY [".", "/app/"]

# add ssh credentials to pull repo in git
# ----------------------------------------------------------------------
ADD id_rsa /root/.ssh/id_rsa
RUN chmod 700 /root/.ssh/id_rsa

# add ssh credentials to pull repo in git
# ----------------------------------------------------------------------
ADD ssh_config /root/.ssh/config
RUN chmod 700 /root/.ssh/config

EXPOSE 5000

# run server to be seen from outside
# ----------------------------------------------------------------------
CMD ["flask", "run", "--host=0.0.0.0"]
