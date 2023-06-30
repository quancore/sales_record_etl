import os
import logging
import zipfile

from io import BytesIO
from boto3 import resource, client
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

FILE_PREFIX = os.environ.get("FILE_PREFIX", "data/csv")
#CRAWLER_NAME = os.environ.get("CRAWLER_NAME", "sales_crawler")
#JOB_NAME = os.environ.get("JOB_NAME", "sales_convert_partition")
WORKFLOW_NAME = os.environ.get("WORKFLOW_NAME", "sales_etl")

s3_resource = resource('s3')
glue_client = client(service_name='glue')


def trigger_crawler(crawler_name):
    try:
        glue_client.start_crawler(Name=crawler_name)
        logger.info(f'Crawler has been triggered: {crawler_name}')
    except ClientError as e:
        logger.exception(f'Error: Unable to trigger crawler: {e}')


def trigger_job(job_name, source_path):
    try:
        glue_client.start_job_run(JobName=job_name, Arguments={"--source_path": source_path})
        logger.info(f'Job has been triggered: {job_name}')
    except ClientError as e:
        logger.exception(f'Error: Unable to trigger job: {e}')


def trigger_workflow(workflow_name):
    try:
        glue_client.start_workflow_run(Name=workflow_name)
    except ClientError as e:
        logger.exception(f'Error: Unable to workflow job: {e}')


def unzip_files(input_key, bucket_name, output_prefix=None):
    """
    Unzip a compressed file on AWS S3 bucket and register all files back to same S3 bucket

    :param input_key: S3 object key will be used for unzipping
    :param bucket_name: Name of the S3 bucket the file will be saved
    :param output_prefix: S3 object prefix all unzipped files will be stored on
    """

    logger.info(f"Un-zipping file: {bucket_name}/{input_key}")
    bucket = s3_resource.Bucket(bucket_name)
    try:
        zipped_file = s3_resource.Object(bucket_name=bucket_name, key=input_key)
        buffer = BytesIO(zipped_file.get()["Body"].read())
        zipped = zipfile.ZipFile(buffer)

        for file in zipped.namelist():
            logger.info(f'current file in zipfile: {file}')
            bucket.upload_fileobj(
                Fileobj=zipped.open(file),
                Key=f'{output_prefix}/{file}' if output_prefix is not None else file
            )

    except Exception as e:
        logger.exception(f'Error: Unable to uncompress & upload file: {e}')


def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    zip_key = event['Records'][0]['s3']['object']['key']
    unzip_files(zip_key, bucket, output_prefix=FILE_PREFIX)
    # trigger_crawler(CRAWLER_NAME)
    # source_path = f's3://{bucket}/{FILE_PREFIX}/' if FILE_PREFIX is not None else f's3://{bucket}//'
    # trigger_job(JOB_NAME, source_path)
    trigger_workflow(WORKFLOW_NAME)

    return {
        'statusCode': 200
    }