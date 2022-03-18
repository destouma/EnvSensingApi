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

In the folder:
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

Dont forget to create the folder /storage/pictures in the app root folder