#!/bin/bash

set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

initialize_database() {
    log "Initializing database..."
    if [ -z "$PG_PASSWORD" ]; then
        log "ERROR: PG_PASSWORD must be set for database initialization"
        exit 1
    fi
    
    encrypted_pass=$(gosu postgres psql -t -c "SELECT concat('md5', md5('$PG_PASSWORD$POSTGRES_USER'))")
    if ! gosu postgres ./initdb --auth-host=md5 --auth-local=peer; then
        log "Database initialization failed"
        exit 1
    fi
    gosu postgres psql -c "ALTER USER postgres WITH PASSWORD '$encrypted_pass';"
    log "Database initialized with provided password"
}

configure_postgresql() {
    log "Configuring PostgreSQL..."
    mkdir -p "$PGDATA/conf.d"

    # Start writing to custom.conf
    {
        # Add custom settings first
        cat <<EOF
# Custom settings
synchronous_commit = off
unix_socket_directories = '/tmp,$PGSOCKET'
listen_addresses = '*'
EOF

        # Check if we should include pgdefault.conf
        if [ "${INCLUDE_PGDEFAULT:-no}" = "yes" ]; then
            echo ""  # Add a newline for clarity
            echo "# Include contents from pgdefault.conf"
            cat /pgdefault.conf
        fi
    } > "$PGDATA/conf.d/custom.conf"

    echo "include_dir = 'conf.d'" >> "$PGDATA/postgresql.conf"
    echo "host all all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
}



if [ "$1" = './postgres' ]; then
    
    if [ ! -s "$PGDATA/PG_VERSION" ]; then
        chown -R postgres:postgres "$PGDATA"
        initialize_database
        configure_postgresql
    fi

    if [ ! -d "$PGSOCKET" ]; then
        mkdir -p $PGSOCKET
    fi
    chown postgres $PGSOCKET

    log "Starting PostgreSQL server..."
    exec gosu postgres ./postgres
fi

exec "$@"
