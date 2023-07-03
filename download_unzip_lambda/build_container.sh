# exit when any command fails
set -e

# Bash script to build a container for lambda functions, push container to AWS ECR repo

REGION="eu-central-1"
REPONAME="download_unzip"
TAG="latest"
DOCKERCONTEXT="."

usage () {
	echo -e  "$0 -r region -rp reponame -t tag -d dockercontext"
	echo -e "  ${BB}-r | --region the AWS region name cloudformation stack will be deployed (also S3 and ECR created)"
	echo -e "  ${BB}-rp | --repo name of the AWS ECR repository name"
	echo -e "  ${BB}-t | --tag name of the container tag"
	echo -e "  ${BB}-d | --dockercontext a file path indicates the docker context directory"
	exit 1
}

while true; do
  # Here we parse all parameters
case "$1" in
  -r | --region ) REGION=$2; shift 2;;
  -rn | --reponame ) REPONAME=$2; shift 2;;
  -t | --tag ) TAG=$2; shift 2;;
  -d | --dockercontext ) DOCKERCONTEXT=$2; shift 2;;
  * ) break;;
esac
done

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGISTRY_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Building and Pushing lambda container to: ${REGISTRY_URL}/${REPONAME}:${TAG}"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY_URL"
docker build -t "$REPONAME":"$TAG" -f "$DOCKERCONTEXT"/Dockerfile "$DOCKERCONTEXT"
docker tag "$REPONAME":"$TAG" "$REGISTRY_URL"/"$REPONAME":"$TAG"
docker push "$REGISTRY_URL"/"$REPONAME":"$TAG"
