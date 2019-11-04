# Exercise 7 - Rolling out an Application Change with Zero Downtime

## Goals

* Learn about Kubernetes concepts: rolling updates, readiness and liveness probes
* Use Docker tags to version artifacts

## Acceptance Criteria

* Make a modification to the application home page
* Build and publish a new Docker image with a versioned tag `pet-app:step-7`
* Update pod definition to use new version
* Deploy change with zero downtime

## Step by Step Instructions

Update the `src/main/resources/messages/messages.properties` file to change the
welcome message to "Welcome to the DevOps PetClinic!":

```properties
welcome=Welcome to the DevOps PetClinic!
...
```

Rebuild the application jar:

```shell
$ ./mvnw package
[INFO] Scanning for projects...
[INFO]                                                                         
[INFO] ------------------------------------------------------------------------
[INFO] Building petclinic 2.0.0.BUILD-SNAPSHOT
[INFO] ------------------------------------------------------------------------

...

[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 01:03 min
[INFO] Finished at: 2018-04-12T00:57:22+01:00
[INFO] Final Memory: 91M/585M
[INFO] ------------------------------------------------------------------------
```

Rebuild the Docker image, specifying the `pet-app:step-7` versioned tag:

```shell
$ docker build --tag=pet-app:step-7 --build-arg JAR_FILE=target/spring-petclinic-2.0.0.BUILD-SNAPSHOT.jar .
Sending build context to Docker daemon  270.7MB
Step 1/4 : FROM openjdk:8-jdk-alpine
 ---> 224765a6bdbe
Step 2/4 : ARG JAR_FILE
 ---> Using cache
 ---> d1f9cda3b36d
Step 3/4 : ADD ${JAR_FILE} app.jar
 ---> 7f9e99d1c6a8
Step 4/4 : ENTRYPOINT java -Djava.security.egd=file:/dev/./urandom -jar /app.jar
 ---> Running in 3c601126dca3
 ---> cde1c0944753
Removing intermediate container 3c601126dca3
Successfully built cde1c0944753
Successfully tagged pet-app:step-7
```

Verify the new image was tagged properly:

```shell
$ docker image ls pet-app*
REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
pet-app             step-7              cde1c0944753        About a minute ago   140MB
pet-app             latest              1e84b0d0f8b1        36 hours ago         140MB
```

Now, let's update the deployment section on our `kubernetes/web.yml` definition
file to use rolling update strategy, reference the image with the new tag, and
configure liveness and readiness probes:

```yaml
...

spec:
  selector:
    matchLabels:
      app: pet
      tier: frontend
  strategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: pet
        tier: frontend
    spec:
      containers:
      - image: pet-app:step-7
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
        livenessProbe:
          httpGet:
            path: /manage/health
            port: pet-web
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /manage/health
            port: pet-web
          initialDelaySeconds: 30
```

Re-deploy and verify that the pods are updated to the new version on a rolling
fashion:

```shell
$ ./deploy.sh
+ kubectl apply -f kubernetes/mysql.yml
service "pet-db" unchanged
persistentvolumeclaim "db-pv-claim" unchanged
deployment "pet-db" unchanged
+ kubectl apply -f kubernetes/web.yml
service "pet-web" unchanged
deployment "pet-web" configured
$ kubectl rollout status deployment pet-web
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 old replicas are pending termination...
Waiting for rollout to finish: 1 old replicas are pending termination...
Waiting for rollout to finish: 1 old replicas are pending termination...
deployment "pet-web" successfully rolled out
$ kubectl get pod
NAME                       READY     STATUS        RESTARTS   AGE
pet-db-7997cf844-d584n     1/1       Running       2          1d
pet-web-6cdf7fcdff-bpxdt   1/1       Terminating   0          1m
pet-web-6cdf7fcdff-fx5b9   0/1       Terminating   0          1m
pet-web-6cdf7fcdff-vv9pc   0/1       Terminating   0          1m
pet-web-8c8d8769c-8b66p    1/1       Running       0          21s
pet-web-8c8d8769c-9xd5c    1/1       Running       0          13s
pet-web-8c8d8769c-szgf7    1/1       Running       0          5s
$ kubectl get replicaset
NAME                 DESIRED   CURRENT   READY     AGE
pet-db-7997cf844     1         1         1         1d
pet-web-6cdf7fcdff   0         0         0         1d
pet-web-8c8d8769c    3         3         3         10m
```

Get the service URL and open it in your browser (in this case
http://192.168.99.100:30596) to open the PetClinic application and make sure the
welcome message is updated:

```shell
$ minikube service pet-web --url
http://192.168.99.100:30596
```
