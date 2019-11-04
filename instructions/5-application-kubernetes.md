# Exercise 5 - Run Application on Kubernetes

## Goals

* Learn about Kubernetes concepts: connecting applications
* Learn to expose a service running on Kubernetes
* Deploy a single-instance Pet application in Kubernetes

## Acceptance Criteria

* Create a `web.yml` file in the `kubernetes` folder to define the k8s objects
required to deploy a single-instance Pet application and connect it to the MySQL
service
* Update the `deploy.sh` script at the root of the project to deploy the application
* Update the application to read database configuration from environment variables
* Application is exposed on the host and can be accessed on `http://<CLUSTER_IP>:8080`

## Step by Step Instructions

Kubernetes adds environment variables for every active service when launching
new pods, which allows us to perform service discovery. The relevant variables
for our MySQL database service are `PET_DB_SERVICE_HOST` and `PET_DB_SERVICE_PORT`,
so we can change our application's `src/main/resources/application-mysql.properties`
configuration to use that and other information that will be defined in the
Kubernetes definition file:

```properties
# database init, supports mysql too
database=mysql
spring.datasource.url=jdbc:mysql://${PET_DB_SERVICE_HOST}:${PET_DB_SERVICE_PORT}/${PET_DB_DATABASE}
spring.datasource.username=${PET_DB_USER}
spring.datasource.password=${PET_DB_PASSWORD}
spring.datasource.initialization-mode=always
```

Create the kubernetes definition file `kubernetes/web.yml`, which will define the
other environment variables and access the MySQL password secret:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: pet-web
  labels:
    app: pet
spec:
  ports:
    - port: 8080
  selector:
    app: pet
    tier: frontend
  type: LoadBalancer
---
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: pet-web
  labels:
    app: pet
spec:
  selector:
    matchLabels:
      app: pet
      tier: frontend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: pet
        tier: frontend
    spec:
      containers:
      - image: pet-app
        imagePullPolicy: Never
        name: pet-web
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: mysql
        - name: PET_DB_DATABASE
          value: petclinic
        - name: PET_DB_USER
          value: petclinic-user
        - name: PET_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: password
        ports:
        - containerPort: 8080
          name: pet-web
```

Now we can repackage our application with Maven:

```shell
$ ./mvnw package
[INFO] Scanning for projects...
[INFO]                                                                         
[INFO] ------------------------------------------------------------------------
[INFO] Building petclinic 2.0.0.BUILD-SNAPSHOT
[INFO] ------------------------------------------------------------------------
[INFO]

...

[INFO] --- spring-boot-maven-plugin:2.0.0.RELEASE:repackage (default) @ spring-petclinic ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 01:35 min
[INFO] Finished at: 2018-04-10T13:16:01+01:00
[INFO] Final Memory: 95M/591M
[INFO] ------------------------------------------------------------------------
```

We need to rebuild our image using the Docker daemon inside of minikube:

```shell
$ eval $(minikube docker-env)
$ docker build --tag=pet-app --build-arg JAR_FILE=target/spring-petclinic-2.0.0.BUILD-SNAPSHOT.jar .
Sending build context to Docker daemon  270.6MB
Step 1/4 : FROM openjdk:8-jdk-alpine
8-jdk-alpine: Pulling from library/openjdk
ff3a5c916c92: Already exists
5de5f69f42d7: Pull complete
fd869c8b9b59: Pull complete
Digest: sha256:4cd17a64b67df1a929a9c6dedf513afcdc48f3ca0b7fddee6489d0246a14390b
Status: Downloaded newer image for openjdk:8-jdk-alpine
 ---> 224765a6bdbe
Step 2/4 : ARG JAR_FILE
 ---> Running in 99e39c8f3b87
 ---> d1f9cda3b36d
Removing intermediate container 99e39c8f3b87
Step 3/4 : ADD ${JAR_FILE} app.jar
 ---> a59d14a26319
Step 4/4 : ENTRYPOINT java -Djava.security.egd=file:/dev/./urandom -jar /app.jar
 ---> Running in 20374bf0517b
 ---> 2e68f5165a1e
Removing intermediate container 20374bf0517b
Successfully built 2e68f5165a1e
Successfully tagged pet-app:latest
```

Check that the image was published to Minikube's Docker:

```shell
$ docker image ls pet*
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
pet-app             latest              2e68f5165a1e        3 minutes ago       140MB
```

Now we can update the `deploy.sh` script to apply the web k8s objects:

```bash
#!/usr/bin/env bash
set -xe
kubectl apply -f kubernetes/mysql.yml
kubectl apply -f kubernetes/web.yml
```

And re-deploy:

```shell
$ ./deploy.sh
+ kubectl apply -f kubernetes/mysql.yml
service "pet-db" unchanged
persistentvolumeclaim "db-pv-claim" unchanged
deployment "pet-db" unchanged
+ kubectl apply -f kubernetes/web.yml
service "pet-web" created
deployment "pet-web" created
```

Validate that the objects are created successfully:

```shell
$ kubectl get pods
NAME                       READY     STATUS    RESTARTS   AGE
pet-db-7997cf844-lsppt     1/1       Running   0          1h
pet-web-59cd5678b8-p7thk   1/1       Running   0          1h
$ kubectl get service
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP      10.96.0.1      <none>        443/TCP          4d
pet-db       ClusterIP      None           <none>        3306/TCP         1h
pet-web      LoadBalancer   10.104.27.46   <pending>     8080:30596/TCP   1h
```

Get the external service URL to test the application is working and accessible:

```shell
$ minikube service pet-web --url
http://192.168.99.100:30596
```

Visiting the URL in your browser (in this case http://192.168.99.100:30596)
should open the PetClinic application.
