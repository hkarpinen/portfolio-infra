-- init-databases.sql
-- Creates all three application databases on first docker compose up.
-- Mounted into /docker-entrypoint-initdb.d/ in the postgres container.

SELECT 'CREATE DATABASE identity_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'identity_db')\gexec

SELECT 'CREATE DATABASE forum_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'forum_db')\gexec

SELECT 'CREATE DATABASE bills_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bills_db')\gexec

SELECT 'CREATE DATABASE notifications_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'notifications_db')\gexec
