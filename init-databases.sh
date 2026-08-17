#!/bin/bash
# Runs once on first boot of a fresh postgres volume.
# Creates one database + least-privilege user per service.
# Each service can only connect to its own database.
# Note: passwords must not contain single quotes.
set -e

PSQL="psql -v ON_ERROR_STOP=1 --username $POSTGRES_USER"

$PSQL -c "CREATE DATABASE identity_db;"
$PSQL -c "CREATE USER identity_user WITH PASSWORD '$IDENTITY_DB_PASSWORD';"
$PSQL -c "GRANT CONNECT, CREATE ON DATABASE identity_db TO identity_user;"
$PSQL -d identity_db -c "GRANT ALL ON SCHEMA public TO identity_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO identity_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO identity_user;"

$PSQL -c "CREATE DATABASE forum_db;"
$PSQL -c "CREATE USER forum_user WITH PASSWORD '$FORUM_DB_PASSWORD';"
$PSQL -c "GRANT CONNECT, CREATE ON DATABASE forum_db TO forum_user;"
$PSQL -d forum_db -c "GRANT ALL ON SCHEMA public TO forum_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO forum_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO forum_user;"

$PSQL -c "CREATE DATABASE finance_db;"
$PSQL -c "CREATE USER finance_user WITH PASSWORD '$FINANCE_DB_PASSWORD';"
$PSQL -c "GRANT CONNECT, CREATE ON DATABASE finance_db TO finance_user;"
$PSQL -d finance_db -c "GRANT ALL ON SCHEMA public TO finance_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO finance_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO finance_user;"

$PSQL -c "CREATE DATABASE notifications_db;"
$PSQL -c "CREATE USER notifications_user WITH PASSWORD '$NOTIFICATIONS_DB_PASSWORD';"
$PSQL -c "GRANT CONNECT, CREATE ON DATABASE notifications_db TO notifications_user;"
$PSQL -d notifications_db -c "GRANT ALL ON SCHEMA public TO notifications_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO notifications_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO notifications_user;"

$PSQL -c "CREATE DATABASE household_db;"
$PSQL -c "CREATE USER household_user WITH PASSWORD '$HOUSEHOLD_DB_PASSWORD';"
$PSQL -c "GRANT CONNECT, CREATE ON DATABASE household_db TO household_user;"
$PSQL -d household_db -c "GRANT ALL ON SCHEMA public TO household_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO household_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO household_user;"

$PSQL -c "CREATE DATABASE media_db;"
$PSQL -c "CREATE USER media_user WITH PASSWORD '$MEDIA_DB_PASSWORD';"
$PSQL -c "GRANT CONNECT, CREATE ON DATABASE media_db TO media_user;"
$PSQL -d media_db -c "GRANT ALL ON SCHEMA public TO media_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO media_user; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO media_user;"
