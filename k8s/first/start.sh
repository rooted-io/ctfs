#!/bin/bash

# generating flags
easy_rand=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
easy_flag=CTF{easy-flag-$easy_rand}
medium_rand=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
medium_flag=CTF{medium-flag-$medium_rand}

# start minikube cluster
minikube start --profile k8s-ctf-1

# creating namespaces
kubectl create namespace easy && kubectl create namespace medium

# creating flag secrets
kubectl create secret generic flag --namespace=easy --from-literal=flag="this is not the flag!"
kubectl create secret generic definitelynotaflag --namespace=easy --from-literal=flag="$easy_flag"
kubectl create secret generic flag --namespace=medium --from-literal=flag="this is not the flag!"
kubectl create secret generic db --namespace=medium --from-literal=flag="$medium_flag"
# retrieve a secret: kubectl get secret flag -n easy -o=jsonpath='{.data.flag}' | base64 --decode

# applying resources
kubectl apply --recursive -f manifests

# generating user certificates
mkdir cert && cd cert
openssl genrsa -out ctf1.key 2048
openssl req -new -key ctf1.key -out ctf1.csr -subj "/CN=ctf1/O=group1"
openssl x509 -req -in ctf1.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out ctf1.crt -days 10
kubectl config set-credentials ctf1 --client-certificate=ctf1.crt --client-key=ctf1.key
kubectl config set-context ctf1-context --cluster=k8s-ctf-1 --user=ctf1
kubectl config use-context ctf1-context
# kubectl config view
# return to 'admin' context: kubectl config use-context k8s-ctf-1