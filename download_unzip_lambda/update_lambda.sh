# exit when any command fails
set -e

# Bash script to  update related lambda functions with given tag container

REGION="eu-central-1"
REPONAME="download_unzip"
TAG="latest"

usage () {
	echo -e  "$0 -r region -rp reponame -t tag"
	echo -e "  ${BB}-r | --region the AWS region name cloudformation stack will be deployed (also S3 and ECR created)"
	echo -e "  ${BB}-rn | --reponame name of the AWS ECR repository name"
	echo -e "  ${BB}-t | --tag name of the container tag"
	exit 1
}

while true; do
  # Here we parse all parameters
case "$1" in
  -r | --region ) REGION=$2; shift 2;;
  -rn | --reponame ) REPONAME=$2; shift 2;;
  -t | --tag ) TAG=$2; shift 2;;
  * ) break;;
esac
done

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGISTRY_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Updating lambda functions with the new container: ${REPONAME}:${TAG}"
aws lambda update-function-code \
           --function-name download \
           --image-uri "$REGISTRY_URL"/"$REPONAME":"$TAG" \
           --region "$REGION"
aws lambda update-function-code \
           --function-name unzip \
           --image-uri "$REGISTRY_URL"/"$REPONAME":"$TAG" \
           --region "$REGION"