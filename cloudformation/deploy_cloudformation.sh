# exit when any command fails
set -e

# Bash script to deploy cloudformation template

REGION="eu-central-1"
DATABUCKETNAME="sale-record"
ARTIFACTBUCKETNAME="sale-record-script"
REPONAME="download_unzip"
GLUECODEPREFIX="aws_glue/scripts"
STACKNAME="sales-record-etl"


usage () {
	echo -e  "$0 -r region -b bucket -rn reponame"
	echo -e "  ${BB}-r | --region the AWS region name cloudformation stack will be deployed (also S3 and ECR created)"
	echo -e "  ${BB}-b | --bucket name of the AWS S3 bucket all the code and data will be stored"
	echo -e "  ${BB}-rn | --reponame name of the AWS ECR repository name"
	echo -e "  ${BB}-s | --stackname name of the AWS Cloudformation stack will be created"
	exit 1
}


while true; do
  # Here we parse all parameters
case "$1" in
  -h | -help | --help) usage; exit;;
  -r | --region ) REGION=$2; shift 2;;
  -b | --bucket ) DATABUCKETNAME=$2; shift 2;;
  -rn | --reponame ) REPONAME=$2; shift 2;;
  -s | --stackname ) STACKNAME=$2; shift 2;;
  * ) break;;
esac
done

#### Resource pre-allocation ####
# create S3 script bucket before running cloudformation since cloudformation packing will upload the glue code to script bucket
echo "Creating S3 script bucket: ${ARTIFACTBUCKETNAME} on region: ${REGION}"
aws s3api head-bucket --bucket "$ARTIFACTBUCKETNAME" || aws s3api create-bucket --bucket "$ARTIFACTBUCKETNAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
# create ECR repository (if not exist) before cloudformation since lambda function container will be required while cloudformation lambda creation
echo "Creating ECR repository: ${REPONAME} on region: ${REGION}"
aws ecr describe-repositories --repository-names "$REPONAME" --region "$REGION" || aws ecr create-repository --repository-name "$REPONAME" --region "$REGION"
# build and push AWS lambda container
bash ../download_unzip_lambda/build_container.sh --region "$REGION" --reponame "$REPONAME" --dockercontext ../download_unzip_lambda
####

echo "Packing cloudformation stack"
# upload local artifact (glue ETL job script to s3 bucket) and output resolved URL
aws cloudformation package \
    --template-file cloudformation.yaml \
    --s3-bucket "$ARTIFACTBUCKETNAME" \
    --s3-prefix "$GLUECODEPREFIX" \
    --output-template-file cloudformation_packed.yaml

# https://github.com/aws-cloudformation/cloudformation-coverage-roadmap/issues/1242
# There is wrong drift detection on lambda function which hinder to create change set update
#echo "Creating cloudformation stack on region: ${REGION}"
## create stack
#aws cloudformation create-stack \
#    --stack-name "$STACKNAME" \
#    --template-body file://cloudformation_packed.yaml \
#    --parameters ParameterKey=DataBucketName,ParameterValue="$DATABUCKETNAME" ParameterKey=ArtifactBucketName,ParameterValue="$ARTIFACTBUCKETNAME" \
#    --region "$REGION" \
#    --capabilities CAPABILITY_NAMED_IAM
#
## wait until stack creation complete
#aws cloudformation wait stack-create-complete \
#  --stack-name "$STACKNAME" \
#  --region "$REGION"
#
## import s3 bucket and ecr resources into existing stack
#echo "Updating cloudformation stack on region: ${REGION}"
#resources="[
#{\"ResourceType\":\"AWS::ECR::Repository\",\"LogicalResourceId\":\"ECRRepository\",\"ResourceIdentifier\":{\"RepositoryName\":\"${REPONAME}\"}},
#{\"ResourceType\":\"AWS::S3::Bucket\",\"LogicalResourceId\":\"ArtifactBucket\",\"ResourceIdentifier\":{\"BucketName\":\"${ARTIFACTBUCKETNAME}\"}}
#]"
#CHANGESET_NAME="add-s3-ecr"
#aws cloudformation create-change-set \
#    --stack-name "$STACKNAME" \
#    --change-set-name "$CHANGESET_NAME" \
#    --change-set-type "IMPORT" \
#    --parameters ParameterKey=DataBucketName,ParameterValue="$DATABUCKETNAME" ParameterKey=ArtifactBucketName,ParameterValue="$ARTIFACTBUCKETNAME" \
#    --resources-to-import "$resources" \
#    --template-body file://cloudformation_s3_ecr.yaml \
#    --capabilities CAPABILITY_NAMED_IAM \
#    --region "$REGION"
#
#aws cloudformation describe-change-set --change-set-name "$CHANGESET_NAME" --stack-name "$STACKNAME" --region "$REGION"
#aws cloudformation execute-change-set --change-set-name "$CHANGESET_NAME" --stack-name "$STACKNAME" --region "$REGION"

# update lambda functions container
bash ../download_unzip_lambda/update_lambda.sh --region "$REGION" --reponame "$REPONAME"