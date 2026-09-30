# Environmental Sensing  API

Basic Ruby On Rails API to store sensor readings

Database: posgresql

Using the folowing gems
- annotate
- rswag
- rails_admin


Development:
============
``` shell script
$ bundle install
$ bundle exec rake db:create
$ bundle exec rake db:migrate
$ bundle exec rake db:seed
$ rails s -b 0.0.0.0
```

Assuming Postgres SQL is running on local host and listening port 5432

Assuming role **_envsensing_** with passwd **_envsensing_** exists
              
              
Assuming the server is running on localhost port 3000

API doc: 
<br> http://localhost:3000/api-docs/index.html

Rails admin: 
<br>http://localhost:3000/admin/
<br></br>
```

Production:
============

3 containers:
* app : ruby on rails app, using PUMA
* db  : postgres
* web : nginx

In the folder, create the `.env` file first (it is git-ignored, never commit it):
```shell script
$ cp .env.example .env
$ openssl rand -hex 64   # paste as SECRET_KEY_BASE, then set ADMIN_USERNAME / ADMIN_PASSWORD
```
`/admin` is protected by HTTP Basic auth and returns 403 in production when the admin credentials are not set.

```shell script
$ sudo docker-compose up -d
$ sudo docker-compose exec app bash
```

In the app container:
```shell script
# rake db:create
# rake db:migrate
# rake db:seed
```

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

Create the first admin key on the server (in the app container):
```shell script
# rake "auth:create_api_key[my-laptop,admin]"
```

`POST /api/v1/devices` (admin key) returns the new device's token in `api_token`: flash it into the
device firmware. Other token tasks:
```shell script
# rake "auth:issue_device_token[<device uuid>,firmware v2]"   # rotation: issue, reflash, then revoke the old one
# rake "auth:list_device_tokens[<device uuid>]"
# rake "auth:revoke_device_token[<id>]"
# rake auth:list_api_keys
# rake "auth:revoke_api_key[<id>]"
```
Tokens can also be revoked from Rails Admin (set `revoked_at`).

Requests are rate limited (429 with `Retry-After`): 300 requests per 5 minutes per token and
1000 per 5 minutes per IP address.

Pictures are stored per device in `storage/pictures/<device id>/`.
