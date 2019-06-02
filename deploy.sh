#!/usr/bin/env bash
set -xe
kubectl apply -f kubernetes/mysql.yml
kubectl apply -f kubernetes/web.yml
