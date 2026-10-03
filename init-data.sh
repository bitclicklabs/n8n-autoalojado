#!/bin/sh
# Arranque inicial de Postgres. Solo se ejecuta la PRIMERA vez (volumen vacío).
# Crea el usuario sin privilegios con el que se conecta n8n.
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
else
	echo "init-data: POSTGRES_NON_ROOT_* vacío; n8n no podrá conectarse."
fi
