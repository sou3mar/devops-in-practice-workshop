# Exercise 2 - Running with a Persistent Database

## Goals

* Decouple database service from the application
* Run a MySQL database on Docker
* Learn about Docker persistent volumes and networking

## Acceptance Criteria

* Application configuration modified to connect to MySQL database
* Docker image is rebuilt and tagged as `pet-app`
* MySQL running in Docker
* User-defined network created in Docker
* Application running in Docker and linked to MySQL container
* Application can be accessed on http://localhost:8080
* New owner is created, with at least 1 pet
* Kill and restart application container
* Owner created in previous step is still available

## Step by Step Instructions

First of all we will create a `data` folder to use as the container persistent
volume, and then start an image of the MySQL 5.7 container and pass a few
environment variables to create a new database, user, and password:

```shell
$ mkdir data
$ docker run -d --name pet-db -v $PWD/data:/var/lib/mysql -e MYSQL_RANDOM_ROOT_PASSWORD=yes -e MYSQL_DATABASE=petclinic -e MYSQL_USER=petclinic-user -e MYSQL_PASSWORD=S3cr3t mysql:5.7
```

Now we will create a user-defined network for the containers to be able to
connect to each other, and attach the running MySQL container to the network:

```shell
$ docker network create pet-net
c8e9dd492b9f9d73216ab71bc73277c44e99b057814821c2f083dc48f27e5dd8
$ docker network connect pet-net pet-db
```

Now we can start our application container, but this time enabling the `mysql`
Spring profile with an environment variable, and also adding the `--network` option
to connect to the user-defined network:

```shell
$ docker run --name=pet-app-prod -d -p 8080:8080 -e "SPRING_PROFILES_ACTIVE=mysql" --network pet-net pet-app
ff776db53488ff18644bfd79e39f7101501dbfd4cc0216f041051a1155a8adaf
```

Then you should be able to access the application by going to http://localhost:8080.

Use the application to create a new owner with a pet. Then we can test that the
persistence is working by restarting the containers with `docker stop` and
`docker rm` commands.

After testing, stop and remove both containers, as well as the user-defined
network, to prepare for the next step:

```shell
$ docker stop pet-app-prod
pet-app-prod
$ docker stop pet-db
pet-db
$ docker rm pet-app-prod
pet-app-prod
$ docker rm pet-db
pet-db
$ docker network rm pet-net
pet-net
```
