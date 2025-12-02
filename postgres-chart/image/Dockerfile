FROM postgres:16.0

RUN apt-get update && \
    apt-get install -y git  \
    build-essential  \
    postgresql-server-dev-16  \
    libcurl4-nss-dev \
    locales  \
    locales-all \
    vim


ARG CACHEBUST=1
RUN git clone https://github.com/DataDog/pg_tracing.git /pg_tracing && \
    cd /pg_tracing && \
    make PG_VERSION=16 && \
    make install && \
    echo "postgres:x:26:26:PostgreSQL Server:/var/lib/postgresql:/bin/bash" >> /etc/passwd


RUN rm -rf /pg_tracing && \
    apt-get remove --purge -y git build-essential postgresql-server-dev-16 && \
    apt-get autoremove -y && \
    apt-get clean
