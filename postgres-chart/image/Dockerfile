FROM postgres:17.0
USER root

RUN apt-get update && \
    apt-get install -y git  \
    build-essential  \
    postgresql-server-dev-17 \
    libcurl4-nss-dev \
    python3-pip \
    locales  \
    locales-all \
    vim && \
    pip3 install --break-system-packages barman[cloud] && \
    ln -sf /usr/local/bin/barman-cloud-wal-archive /usr/bin/barman-cloud-wal-archive && \
    ln -sf /usr/local/bin/barman-cloud-backup /usr/bin/barman-cloud-backup


ARG CACHEBUST=1
RUN git clone https://github.com/DataDog/pg_tracing.git /pg_tracing && \
    cd /pg_tracing && \
    make PG_VERSION=17 && \
    make install && \
    echo "postgres:x:26:26:PostgreSQL Server:/var/lib/postgresql:/bin/bash" >> /etc/passwd


RUN rm -rf /pg_tracing && \
    apt-get remove --purge -y git build-essential postgresql-server-dev-17 && \
    apt-get autoremove -y && \
    apt-get clean

USER postgres