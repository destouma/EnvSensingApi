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

Every API endpoint except `GET /api/v1/date_time/current_date_time` requires an
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

Pictures are stored per device in `storage/pictures/<device id>/`.
