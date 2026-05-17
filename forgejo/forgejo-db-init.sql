SELECT format('CREATE ROLE %I LOGIN', 'forgejo')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'forgejo')\gexec

SELECT format('CREATE DATABASE %I OWNER %I', 'forgejo', 'forgejo')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'forgejo')\gexec
