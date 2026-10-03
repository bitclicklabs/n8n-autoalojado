# n8n autoalojado con Docker — BitclickLabs

Stack del vídeo "Autoalójate n8n": n8n + Postgres en Docker, con webhooks públicos
y conexión a Claude como MCP. Funciona en local o en un VPS propio.

```
internet ───► Caddy (perfil vps) ──┐
internet ───► cloudflared (tunnel) ┼──► n8n :5678 ──► Postgres
tu máquina ─► 127.0.0.1:5678 ──────┘
```

## Instálalo con Claude Code (recomendado)

Deja que Claude Code lo gestione todo por ti. Te hará las preguntas necesarias (dónde instalarlo,
tu dominio, tu email…) y te dará los pasos claros. Nunca te pedirá contraseñas ni claves:
los secretos los genera él directamente en tu equipo o servidor.

1. Instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) y [Claude Code](https://docs.claude.com/en/docs/claude-code/overview).
2. Abre una terminal en una carpeta vacía y ejecuta `claude`.
3. Pega este prompt:

```text
Quiero autoalojar n8n con Docker. Clona https://github.com/bitclicklabs/n8n-autoalojado en una subcarpeta llamada n8n-autoalojado, lee su archivo SETUP-CLAUDE.md y sigue esas instrucciones de principio a fin. Pregúntame lo que necesites, de una en una, pero nunca me pidas contraseñas, tokens ni claves.
```

Si prefieres hacerlo a mano, sigue leyendo.

## Antes de empezar

- Docker con Docker Compose (Docker Desktop en local; en el VPS, `curl -fsSL https://get.docker.com | sh`).
- Para webhooks públicos: un dominio. En local, además, una cuenta gratuita de Cloudflare.

## 1. Configura el `.env`

```bash
cp .env.example .env
```

1. En la sección 1 del `.env`, deja activo **un solo bloque**: A (local), B (local + túnel) o C (VPS).
2. Genera cada secreto con `openssl rand -hex 32` y sustituye cada `REPLACE_WITH_...` (en el bloque B, `CLOUDFLARE_TUNNEL_TOKEN` es el token del túnel, no un `openssl`).
3. Comprueba que no queda ninguno:

   ```bash
   grep REPLACE_WITH_ .env
   ```

   Si el comando no muestra nada, el `.env` está completo (las líneas comentadas de los bloques que no usas también cuentan: bórralas o rellénalas).
4. Guarda `N8N_ENCRYPTION_KEY` en tu gestor de contraseñas. Si la pierdes, pierdes todas las credenciales de n8n.

> **Importante:** `init-data.sh` solo se ejecuta la primera vez que arranca Postgres. Si cambias
> las contraseñas de Postgres después, borra el volumen `postgres_data` o cámbialas a mano en la base de datos.

## 2. Arranca

| Escenario | Comando | URL |
|---|---|---|
| A. Local, solo tú | `docker compose up -d` | http://localhost:5678 |
| B. Local + webhooks públicos | `docker compose --profile tunnel up -d` | https://n8n.tudominio.com |
| C. VPS con HTTPS | `docker compose --profile vps up -d` | https://n8n.tudominio.com |

Comprueba que todo responde:

```bash
docker compose ps
curl http://127.0.0.1:5678/healthz/readiness
```

La respuesta esperada es `{"status":"ok"}`.

> **Precaución:** quien rellene primero el formulario de alta de n8n se queda con la instancia.
> Crea la cuenta de propietario nada más arrancar y activa la verificación en dos pasos.

### B. Túnel de Cloudflare (local)

1. En Cloudflare, ve a **Zero Trust → Networks → Tunnels** y crea un túnel.
2. Añade un *public hostname* `n8n.tudominio.com` con el servicio `http://n8n:5678`.
3. Copia el token del túnel en `CLOUDFLARE_TUNNEL_TOKEN`.

### C. VPS (IONOS)

1. Crea un registro DNS **A** `n8n.tudominio.com` que apunte a la IP del VPS.
2. En el panel de IONOS, abre los puertos **80** y **443** en la política de firewall del servidor.
3. En el VPS, deja abierto solo lo imprescindible:

   ```bash
   ufw allow OpenSSH && ufw allow 80 && ufw allow 443 && ufw enable
   ```

4. Para la primera vez, Caddy tarda uno o dos minutos en emitir el certificado:

   ```bash
   docker compose logs caddy | grep -i "certificate obtained"
   ```

n8n solo escucha en `127.0.0.1`, así que nunca queda expuesto sin HTTPS. Para entrar sin dominio,
usa un túnel SSH: `ssh -L 5678:127.0.0.1:5678 root@IP_DEL_VPS`.

## 3. Prueba el webhook

1. Crea un workflow con un nodo **Webhook** (método POST) y actívalo.
2. Copia la **Production URL**. Debe empezar por tu dominio, no por `localhost`.
3. Lánzale una petición:

   ```bash
   curl -X POST https://n8n.tudominio.com/webhook/prueba -H "Content-Type: application/json" -d '{"hola":"bitclick"}'
   ```

## 4. Conecta n8n a Claude como MCP

1. En n8n, ve a **Settings → Instance-level MCP** y activa el acceso.
2. Copia la URL del servidor y el token que te da n8n.
3. En cada workflow que quieras exponer, activa la opción de MCP en su configuración.
4. Añádelo a Claude Code:

   ```bash
   claude mcp add --transport http n8n <URL_MCP_DE_N8N> --header "Authorization: Bearer <TOKEN>"
   ```

5. Comprueba la conexión con `claude mcp list`.

> **Nota:** el nombre exacto del menú y de la ruta de la URL cambia entre versiones de n8n.
> Copia siempre la URL de la pantalla de n8n en lugar de escribirla a mano.

## Mantenimiento

```bash
# Actualizar n8n (fija antes N8N_IMAGE_TAG a una versión concreta)
docker compose pull n8n && docker compose up -d n8n

# Copia de seguridad de la base de datos
docker compose exec -T postgres pg_dump -U postgres n8n > backup-n8n-$(date +%F).sql
```

Una copia de la base de datos no sirve sin la `N8N_ENCRYPTION_KEY` que corresponde a esos datos.

## Licencia

[MIT](LICENSE). Úsalo, cámbialo y móntalo para tus clientes.
