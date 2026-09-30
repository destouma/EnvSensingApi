# Environmental Sensing API

Ruby on Rails API that stores environmental sensor readings and camera pictures sent by
microcontrollers (an MKR1010 with a BME280, an ESP32 camera) and serves them to people and scripts.

Ruby 4.0, Rails 8.1, PostgreSQL 17, nginx. Main gems: rails_admin (admin UI), rswag (API docs),
carrierwave (picture uploads), rack-attack (rate limiting), annotaterb (schema comments in models).

```
devices / scripts ──HTTPS──> nginx (web) ──> Rails + Puma (app) ──> PostgreSQL (db)
                             TLS, rate limits,     tokens, API,        readings, devices,
                             picture files         admin UI            sensors, pictures
```

## API

All paths start with `/api/v1`. Full reference with request/response examples at `/api-docs`
(generated from the specs in `spec/integration`).

| Endpoint | Token | |
|---|---|---|
| `GET /time` | none | `{current_date_time, epoch}` |
| `GET /devices`, `GET /devices/:uuid` | read | devices with their sensors |
| `POST /devices` | admin | `{uuid, name, description}` → 201 with the device `api_token` |
| `GET /devices/:uuid/sensors`, `GET /sensors/:uuid` | read | |
| `POST /devices/:uuid/sensors` | admin | `{uuid, name, description, sensor_type_id}` → 201 |
| `GET /sensor_types` | read | |
| `GET /sensors/:uuid/readings` | read | newest first, `from`, `to`, `limit`, `cursor` |
| `POST /sensors/:uuid/readings` | device | `{value, date_time}` → 201 |
| `POST /readings` | device | `{readings: [{sensor_uuid, value, date_time}, ...]}` (1-100) → 201, all or nothing |
| `GET /sensors/:uuid/pictures` | read | newest first, same pagination as readings |
| `POST /sensors/:uuid/pictures` | device | multipart `file` (JPEG/PNG, 5 MB max) and optional `date_time` → 201 |
| `GET /pictures/:id/file` | read | the image |

- `value` is the raw integer reading: real value = `value * 10^pow10multi` of the sensor type.
- `date_time` (ISO 8601) is optional and defaults to the server time. It must be after 2000 and at most
  5 minutes in the future, so a device with an unset clock gets a 422 instead of storing wrong data.
- Pagination: pass the `next_cursor` of a page as `cursor` to get the next one (`null` on the last page).
- Errors always look like `{"error": {"code": "validation_failed", "message": "...", "details": {"field": ["..."]}}}`
  with status 400 (malformed request), 401, 403, 404 (including another device's sensor), 409, 422 or 429.
- A device posts to its own sensors only; pictures are stored per device under server generated names.

## Authentication

Every endpoint except `GET /api/v1/time` requires an `Authorization: Bearer <token>` header.
Tokens are shown only once, when created, and stored as SHA-256 digests.

| Token | Prefix | Used by | Allows |
|---|---|---|---|
| Device token | `esd_` | a device (firmware) | posting readings and pictures for **its own** sensors |
| API key, scope `read` | `esk_` | people, scripts, dashboards | all GET endpoints |
| API key, scope `admin` | `esk_` | you | GET endpoints, creating devices and sensors |

`POST /api/v1/devices` (admin key) returns the new device's token in `api_token`: store it in the
device firmware. Tokens are managed with rake tasks (in production, prefix them with
`sudo docker compose exec app`):
```shell script
$ bin/rails "auth:create_api_key[my-laptop,admin]"                  # scope: read or admin
$ bin/rails "auth:issue_device_token[<device uuid>,firmware v2]"    # rotation: issue, reflash, revoke the old one
$ bin/rails "auth:list_device_tokens[<device uuid>]"
$ bin/rails "auth:revoke_device_token[<id>]"
$ bin/rails auth:list_api_keys
$ bin/rails "auth:revoke_api_key[<id>]"
```
Tokens can also be revoked from Rails Admin (set `revoked_at`).

Rate limits (429 with `Retry-After`): 300 requests per 5 minutes per token and 1000 per 5 minutes per
IP address in Rails; in front of it, nginx allows 20 requests/s per IP (burst 40).

`/admin` (Rails Admin) and, in production, `/api-docs` use HTTP Basic auth with `ADMIN_USERNAME` /
`ADMIN_PASSWORD`. In production they are closed when those are not set.

## Development

Requires Ruby 4.0 and a PostgreSQL on localhost:5432 with a role `envsensing` / `envsensing`
(or set `DATABASE_URL`).

```shell script
$ bin/setup --skip-server    # bundle install + db:prepare
$ bin/rails db:seed          # demo devices; prints a token per device and an admin API key
$ bin/rails server -b 0.0.0.0
```

- API docs: http://localhost:3000/api-docs/index.html
- Rails Admin: http://localhost:3000/admin/ (open in development when the admin credentials are not set)
- Health check: http://localhost:3000/up

Seeds are idempotent (running them again only adds what is missing, nothing is deleted). In production
they only create the sensor types.

Checks, all run by CI (GitHub Actions) on every push and pull request, and together by `bin/ci`:
```shell script
$ bundle exec rspec     # specs in random order; reproduce a run with --seed
$ bin/rubocop           # style (rails-omakase)
$ bin/brakeman          # static security analysis, reviewed warnings are in config/brakeman.ignore
$ bin/bundler-audit     # gems with known vulnerabilities
```
CI also builds both Docker images. After changing the API, regenerate the docs from the specs:
`RAILS_ENV=test bin/rails rswag:specs:swaggerize`.

Without a local Ruby 4.0, run the checks in the test image (needs a Postgres reachable through `DATABASE_URL`):
```shell script
$ docker build -f docker/app/Dockerfile --target build --build-arg BUNDLE_WITHOUT= -t envsensing-test .
$ docker run --rm -v "$PWD:/rails" -e RAILS_ENV=test -e DATABASE_URL=postgres://envsensing:envsensing@<db host>:5432/envsensing_test envsensing-test bundle exec rspec
```

## Production

3 containers (`docker-compose.yml`):
* app: Rails with Puma, running as a non-root user
* db: PostgreSQL; the app connects as its own non-superuser role (`envsensing`)
* web: nginx, terminates HTTPS and serves picture files

Volumes: `postgres_data` (database) and `pictures` (uploaded pictures), both kept across rebuilds.

1. Create the `.env` file (git-ignored, never commit it) and fill it in, see `.env.example`:
   ```shell script
   $ cp .env.example .env
   $ openssl rand -hex 64   # SECRET_KEY_BASE
   $ openssl rand -hex 24   # ADMIN_PASSWORD, POSTGRES_PASSWORD, DATABASE_PASSWORD (one each)
   ```
   Set `APP_HOSTS` to the addresses clients use, e.g. `192.168.1.238`.
2. Create the TLS certificate for the same addresses (see HTTPS below):
   ```shell script
   $ bin/generate-lan-cert 192.168.1.238
   ```
3. Start, then create your admin API key:
   ```shell script
   $ sudo docker compose up -d --build
   $ sudo docker compose exec app bin/rails "auth:create_api_key[my-laptop,admin]"
   ```

The API is served on **https://<host>:8443** (`HTTPS_PORT`); **http://<host>:8080** (`HTTP_PORT`) only
redirects to HTTPS. The app container creates and migrates the database on start (`db:prepare`).
Optionally create the standard sensor types with `sudo docker compose exec app bin/rails db:seed`.

### HTTPS (LAN, private CA)

`bin/generate-lan-cert <host>...` creates a private CA (`docker/web/ca/`, valid 10 years) and a server
certificate signed by it (`docker/web/certs/`, valid 825 days) for every IP address / host name given.
Both folders are git- and docker-ignored; only the server certificate and key are mounted (read-only)
into nginx. Keep `docker/web/ca/ca.key` private: it is only needed to issue a new server certificate.

Clients trust the **CA certificate** `docker/web/ca/ca.crt`, so renewing the server certificate or
adding a host (run the script again, then `sudo docker compose restart web`) does not require updating devices.

- ESP32 (`WiFiClientSecure`): `client.setCACert(ca_pem);` with the content of `ca.crt`, and connect
  with the same host as in the certificate (the IP address).
- MKR1010 (WiFiNINA): add `ca.crt` to the NINA module's certificate store with the Arduino IDE
  firmware updater ("Upload SSL root certificates"), then use `WiFiSSLClient`.
- Browsers / computers: import `ca.crt` as a trusted root. HSTS is deliberately off, so without
  the CA installed you can still click through the certificate warning.
- curl: `curl --cacert docker/web/ca/ca.crt https://192.168.1.238:8443/up` (on Windows add
  `--ssl-no-revoke`: Windows' TLS library wants revocation information a private CA does not publish).

nginx accepts TLS 1.2 and 1.3 only, drops slow clients and hides its version. Requests whose `Host` is
not in `APP_HOSTS` are rejected (403).

### Upgrading an existing installation

- Database role: `POSTGRES_PASSWORD` / `DATABASE_PASSWORD` are only applied when the database volume
  is created. For a database created before (app connected as `postgres` / `postgres`), run once after
  adding them to `.env`:
  ```shell script
  $ sudo docker compose up -d db
  $ sudo docker compose exec -T db bash -s < docker/db/adopt-app-role.sh
  $ sudo docker compose up -d
  ```
- Pictures: they now live in the `pictures` volume. Copy existing ones from the old container before
  recreating it: `sudo docker compose cp app:/rails/storage/pictures ./pictures-backup`, then after the
  upgrade `sudo docker compose cp ./pictures-backup/. app:/rails/storage/pictures/`.
- Data: missing reading/picture dates are filled from the time the row was stored and missing
  device/sensor names from their uuid. If rows cannot be fixed automatically (for example a reading
  without a sensor), the migration stops, lists them and changes nothing: fix or delete those rows and
  restart the app container.

### Data volume

One reading per minute and per sensor is about 525,000 rows a year. Readings are read through a
`(sensor_id, date_time, id)` index, so a page takes well under a millisecond whatever the table size
(measured on 2 million rows). Partitioning or TimescaleDB is not needed before hundreds of millions of rows.

## Firmware migration from the previous API

| Before | Now |
|---|---|
| `http://<host>:8080` | `https://<host>:8443`, trusting `ca.crt` |
| no authentication | `Authorization: Bearer <device token>` on every request except `/time` |
| `GET /api/v1/date_time/current_date_time.json` | `GET /api/v1/time` (also returns `epoch`) |
| `POST /api/v1/sensor_readings.json` `{sensor_uuid, sensor_value, sensor_date_time}` | `POST /api/v1/readings` `{readings: [{sensor_uuid, value, date_time}]}`, one request for all sensors |
| `POST /api/v1/pictures/upload.json` (file) then `POST /api/v1/pictures.json` `{sensor_uuid, file_name}` | `POST /api/v1/sensors/:uuid/pictures` multipart `file`, one request |
| `GET /api/v1/sensor_readings.json?sensor_uuid=` | `GET /api/v1/sensors/:uuid/readings` |
| `GET /api/v1/sensors.json?device_uuid=` | `GET /api/v1/devices/:uuid/sensors` |
| `GET /api/v1/pictures.json?sensor_uuid=`, `GET /api/v1/pictures/file.json?id=` | `GET /api/v1/sensors/:uuid/pictures`, `GET /api/v1/pictures/:id/file` |
| `POST /api/v1/sensors.json` `{device_id, sensor_type_id, ...}` | `POST /api/v1/devices/:uuid/sensors` `{sensor_type_id, ...}` |
| 200 on create, 400 for not found | 201 on create, 404 for not found, 422 for invalid data |

A Postman collection for the current API is in `postman/`.

## License

See [license.txt](license.txt).
