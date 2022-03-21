# nf-jdk

Base Java JDK container for backend execution. 

Pushed both to AWS ECR and Docker hub: 
* 195996028523.dkr.ecr.eu-west-1.amazonaws.com/nf-jdk
* seqeralabs/nf-jdk

## Get start 

```
make build 
make push
```


## AWS Login 

```
aws ecr get-login --region eu-west-1 --no-include-email
```

or 

```
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 195996028523.dkr.ecr.eu-west-1.amazonaws.com/nf-jdk
```
