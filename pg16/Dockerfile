FROM docker.io/library/debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Moscow \
    PGDATA=/var/lib/1c/pgdata \
    PGSOCKET=/tmp/postgresql/socket \
    LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU:ru \
    LC_ALL=ru_RU.UTF-8

COPY pgpro-repo-add.sh \
	entrypoint.sh \
	pgdefault.conf \
	/

RUN apt-get update && \
    apt-get install -y locales && \
    sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru LC_ALL=ru_RU.UTF-8 && \
	chmod +x /pgpro-repo-add.sh /entrypoint.sh && \
    /pgpro-repo-add.sh && \
    apt-get -y install \
        tzdata \
        postgrespro-1c-16 \
        postgresql-client \
        gosu \
        pgagent && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    rm /pgpro-repo-add.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*


VOLUME ${PGDATA}

EXPOSE 5432

WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["postgres"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
	CMD pg_isready -U postgres -h localhost || exit 1