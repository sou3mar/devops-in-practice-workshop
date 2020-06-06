#!/usr/bin/env bash
set -xe
kubectl apply -f kubernetes/mysql.yml --namespace default
kubectl apply -f kubernetes/web.yml --namespace default
