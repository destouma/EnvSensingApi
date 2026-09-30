# Environmental Sensing  API

Basic Ruby On Rails API to store sensor readings

Ruby 4.0, Rails 8.1, PostgreSQL 17.

Using the following gems
- rails_admin (admin UI, served with Sprockets)
- rswag (API docs)
- carrierwave (picture uploads)
- rack-attack (rate limiting)
- annotaterb (schema comments in models)


Development:
============
``` shell script
$ bin/setup --skip-server    # bundle install + db:prepare
$ bin/rails db:seed
$ bin/rails server -b 0.0.0.0
```

Assuming Postgres SQL is running on local host and listening port 5432

Assuming role **_envsensing_** with passwd **_envsensing_** exists

Assuming the server is running on localhost port 3000

API doc: 
<br> http://localhost:3000/api-docs/index.html

Rails admin (open in development when ADMIN_USERNAME / ADMIN_PASSWORD are not set): 
<br>http://localhost:3000/admin/

Health check: http://localhost:3000/up

Tests and security scans:
```shell script
$ bundle exec rspec
$ bin/brakeman          # static analysis, reviewed warnings are in config/brakeman.ignore
$ bin/bundler-audit     # known vulnerable gems
```
Without a local Ruby 4.0, run them in the test image (needs a Postgres reachable through DATABASE_URL):
```shell script
$ docker build -f docker/app/Dockerfile --target build --build-arg BUNDLE_WITHOUT= -t envsensing-test .
$ docker run --rm -v "$PWD:/rails" -e RAILS_ENV=test -e DATABASE_URL=postgres://envsensing:envsensing@<db host>:5432/envsensing_test envsensing-test bundle exec rspec
```
CI (GitHub Actions) runs brakeman and bundler-audit on every push and pull request.


Production:
============

3 containers:
* app : ruby on rails app, using PUMA, running as a non-root user
* db  : postgres
* web : nginx

In the folder, create the `.env` file first (it is git-ignored, never commit it):
```shell script
$ cp .env.example .env
$ openssl rand -hex 64   # paste as SECRET_KEY_BASE, then set ADMIN_USERNAME / ADMIN_PASSWORD
```
`/admin` is protected by HTTP Basic auth and returns 403 in production when the admin credentials are not set.

```shell script
$ sudo docker compose up -d --build
```

The app container creates and migrates the database on start (`db:prepare`), no manual step needed.

The server will listen port 8080.

Authentication:
============

Every API endpoint except `GET /api/v1/time` requires an
`Authorization: Bearer <token>` header. There are two kinds of tokens, both shown only once
when created and stored as SHA-256 digests:

| Token | Prefix | Used by | Allows |
|---|---|---|---|
| Device token | `esd_` | a device (firmware) | posting readings and pictures for **its own** sensors |
| API key, scope `read` | `esk_` | people, scripts, dashboards | all GET endpoints |
| API key, scope `admin` | `esk_` | you | GET endpoints, creating devices and sensors |

Create the first admin key on the server:
```shell script
$ sudo docker compose exec app bin/rails "auth:create_api_key[my-laptop,admin]"
```

`POST /api/v1/devices` (admin key) returns the new device's token in `api_token`: flash it into the
device firmware. Other token tasks:
```shell script
# bin/rails "auth:issue_device_token[<device uuid>,firmware v2]"   # rotation: issue, reflash, then revoke the old one
# bin/rails "auth:list_device_tokens[<device uuid>]"
# bin/rails "auth:revoke_device_token[<id>]"
# bin/rails auth:list_api_keys
# bin/rails "auth:revoke_api_key[<id>]"
```
Tokens can also be revoked from Rails Admin (set `revoked_at`).

Requests are rate limited (429 with `Retry-After`): 300 requests per 5 minutes per token and
1000 per 5 minutes per IP address.

Pictures are stored per device in `storage/pictures/<device id>/`, under server generated file names.

API:
============

Full reference with request/response examples: `/api-docs` (generated from the specs in
`spec/integration`, regenerate with `RAILS_ENV=test bin/rails rswag:specs:swaggerize`).
All paths start with `/api/v1`.

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

Firmware migration from the previous API:

| Before | Now |
|---|---|
| `GET /api/v1/date_time/current_date_time.json` | `GET /api/v1/time` (also returns `epoch`) |
| `POST /api/v1/sensor_readings.json` `{sensor_uuid, sensor_value, sensor_date_time}` | `POST /api/v1/readings` `{readings: [{sensor_uuid, value, date_time}]}`, one request for all sensors |
| `POST /api/v1/pictures/upload.json` (file) then `POST /api/v1/pictures.json` `{sensor_uuid, file_name}` | `POST /api/v1/sensors/:uuid/pictures` multipart `file`, one request |
| `GET /api/v1/sensor_readings.json?sensor_uuid=` | `GET /api/v1/sensors/:uuid/readings` |
| `GET /api/v1/sensors.json?device_uuid=` | `GET /api/v1/devices/:uuid/sensors` |
| `GET /api/v1/pictures.json?sensor_uuid=`, `GET /api/v1/pictures/file.json?id=` | `GET /api/v1/sensors/:uuid/pictures`, `GET /api/v1/pictures/:id/file` |
| `POST /api/v1/sensors.json` `{device_id, sensor_type_id, ...}` | `POST /api/v1/devices/:uuid/sensors` `{sensor_type_id, ...}` |
| 200 on create, 400 for not found | 201 on create, 404 for not found, 422 for invalid data |

All requests except `GET /api/v1/time` need the `Authorization: Bearer <token>` header.
