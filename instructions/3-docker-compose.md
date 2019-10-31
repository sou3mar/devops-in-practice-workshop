# Exercise 3 - Bundling containers with Docker Compose

## Goals

* Define and run multi-container Docker application with Docker Compose

## Acceptance Criteria

* Running `docker-compose up` should rebuild and launch MySQL and application containers

## Step by Step Instructions

Create a file called `docker-compose.yml` at the root of the project with the
following content:

```yaml
version: '3.7'

networks:
  pet-net:
    driver: bridge

services:
  pet-app:
    build:
      context: .
      args:
        JAR_FILE: "./target/spring-petclinic-2.0.0.BUILD-SNAPSHOT.jar"
    image: pet-app
    ports:
      - "8080:8080"
    networks:
      - pet-net
    depends_on:
      - pet-db
    environment:
      SPRING_PROFILES_ACTIVE: "mysql"
  pet-db:
    image: mysql:5.7
    expose:
      - 3306
    networks:
      - pet-net
    volumes:
      - ./data:/var/lib/mysql
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: "yes"
      MYSQL_DATABASE: "petclinic"
      MYSQL_USER: "petclinic-user"
      MYSQL_PASSWORD: "S3cr3t"
```

Then you can use `docker-compose build` to rebuild the application container:

```shell
$ docker-compose build
database uses an image, skipping
Building pet-app
Step 1/4 : FROM openjdk:11-oracle
 ---> 224765a6bdbe
Step 2/4 : ARG JAR_FILE
 ---> Using cache
 ---> d21d87bb325b
Step 3/4 : ADD ${JAR_FILE} app.jar
 ---> 05b4e0502c2e
Step 4/4 : ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
 ---> Running in 116e70b2b89e
Removing intermediate container 116e70b2b89e
 ---> 66d4ecdaae23
Successfully built 66d4ecdaae23
Successfully tagged devopsinpracticeworkshop_pet-app:latest
```

Once the container image is built and tagged, you can start all the containers
with a single `docker-compose up` command:

```shell
$ docker-compose up
Creating network "devops-in-practice-workshop_pet-net" with driver "bridge"
Creating devops-in-practice-workshop_pet-db_1 ... done
Creating devops-in-practice-workshop_pet-app_1 ... done
Attaching to devops-in-practice-workshop_pet-db_1, devops-in-practice-workshop_pet-app_1
pet-db_1   | 2019-05-08T09:22:51.846466Z 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).

...
```

Then you should be able to access the application by going to http://localhost:8080

Once you tested that everything is working, you can stop the containers by
pressing `Ctrl+C` and cleaning up using the `docker-compose down` command:

```shell
$ docker-compose down
Removing devops-in-practice-workshop_pet-app_1 ... done
Removing devops-in-practice-workshop_pet-db_1  ... done
Removing network devops-in-practice-workshop_pet-net
```
