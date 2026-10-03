#!/bin/sh
# Arranque inicial de Postgres. Solo se ejecuta la PRIMERA vez (volumen vacío).
#  1. Crea el usuario sin privilegios con el que se conecta n8n.
#  2. Si LANGFUSE_DB_* está definido, deja creada la base de datos de Langfuse (parte 2).
# Si cambias estas variables después del primer arranque, no tienen efecto:
# borra el volumen postgres_data (perderás los datos) o crea el usuario a mano.
set -e

if [ -n "${POSTGRES_NON_ROOT_USER:-}" ] && [ -n "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
		CREATE USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';
		GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_NON_ROOT_USER};
		GRANT CREATE ON SCHEMA public TO ${POSTGRES_NON_ROOT_USER};
	EOSQL
	echo "init-data: usuario ${POSTGRES_NON_ROOT_USER} creado para n8n."
fi

if [ -n "${LANGFUSE_DB_NAME:-}" ] && [ -n "${LANGFUSE_DB_USER:-}" ] && [ -n "${LANGFUSE_DB_PASSWORD:-}" ]; then
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
		CREATE USER ${LANGFUSE_DB_USER} WITH PASSWORD '${LANGFUSE_DB_PASSWORD}';
		CREATE DATABASE ${LANGFUSE_DB_NAME} OWNER ${LANGFUSE_DB_USER};
	EOSQL
	echo "init-data: base de datos ${LANGFUSE_DB_NAME} creada para Langfuse."
else
	echo "init-data: LANGFUSE_DB_* vacío; no se crea la base de datos de Langfuse."
fi
