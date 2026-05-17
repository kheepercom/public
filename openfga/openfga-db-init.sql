SELECT format('CREATE ROLE %I LOGIN', 'openfga')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'openfga')\gexec

SELECT format('CREATE DATABASE %I OWNER %I', 'openfga', 'openfga')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'openfga')\gexec
