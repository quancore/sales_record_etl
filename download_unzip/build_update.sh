# Bash script to build a container for lambda functions, push container to AWS ECR repo and update related lambda functions with latest container

REGISTRY_URL="448303281314.dkr.ecr.eu-central-1.amazonaws.com"
REPO_NAME="download_unzip"
TAG="latest"

aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $REGISTRY_URL
docker build -t $REPO_NAME:$TAG .
docker tag $REPO_NAME:$TAG $REGISTRY_URL/$REPO_NAME:$TAG
docker push $REGISTRY_URL/$REPO_NAME:$TAG

aws lambda update-function-code \
           --function-name download \
           --image-uri $REGISTRY_URL/$REPO_NAME:$TAG
aws lambda update-function-code \
           --function-name unzip \
           --image-uri $REGISTRY_URL/$REPO_NAME:$TAG
