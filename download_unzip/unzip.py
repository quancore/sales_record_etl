import os
import logging
import zipfile

from io import BytesIO
from boto3 import resource, client
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

FILE_PREFIX = os.environ.get("FILE_PREFIX", "csv")
CRAWLER_NAME = os.environ.get("CRAWLER_NAME", "sales_crawler")

s3_resource = resource('s3')
glue_client = client(service_name='glue')


def trigger_crawler(crawler_name):
    try:
        logger.info(f'Crawler has been triggered: {crawler_name}')
        glue_client.start_crawler(Name=crawler_name)
    except ClientError as e:
        logger.exception(f'Error: Unable to trigger crawler: {e}')


def unzip_files(key, bucket_name):
    """
    Unzip a compressed file on AWS S3 bucket and register all files back to same S3 bucket

    :param key: S3 object key will be used for saving
    :param bucket_name: Name of the S3 bucket the file will be saved
    """

    logger.info(f"Un-zipping file: {bucket_name}/{key}")
    bucket = s3_resource.Bucket(bucket_name)
    try:
        zipped_file = s3_resource.Object(bucket_name=bucket_name, key=key)
        buffer = BytesIO(zipped_file.get()["Body"].read())
        zipped = zipfile.ZipFile(buffer)

        for file in zipped.namelist():
            logger.info(f'current file in zipfile: {file}')
            bucket.upload_fileobj(
                Fileobj=zipped.open(file),
                Key=f'{FILE_PREFIX}/{file}'
            )

    except Exception as e:
        logger.exception(f'Error: Unable to uncompress & upload file: {e}')


def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    zip_key = event['Records'][0]['s3']['object']['key']
    unzip_files(zip_key, bucket)
    trigger_crawler(CRAWLER_NAME)

    return {
        'statusCode': 200
    }