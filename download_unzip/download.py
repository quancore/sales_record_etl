import os
import logging
import requests

from io import BytesIO
from boto3 import resource

logger = logging.getLogger()
logger.setLevel(logging.INFO)

headers = {
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36',
}

BUCKET_NAME = os.environ.get("BUCKET_NAME", "sale-record")
URL = os.environ.get("URL", "https://eforexcel.com/wp/wp-content/uploads/2020/09/2m-Sales-Records.zip")
CONTENT_KEY = os.environ.get("CONTENT_KEY", "data/original_sales_record.zip")
s3_resource = resource('s3')


def download_file(url, bucket_name, key):
    """
    Download a file from URL and save it to S3 bucket in stream

    :param url: URL of the file
    :param bucket_name: Name of the S3 bucket the file will be saved
    :param key: S3 object key will be used for saving
    """
    logger.info(f"File download initiated: {url}")
    bucket = s3_resource.Bucket(bucket_name)

    with requests.get(url, stream=True, verify=False, headers=headers) as response:
        response.raise_for_status()
        bucket.upload_fileobj(BytesIO(response.content), key)


def lambda_handler(event, context):
    download_file(URL, BUCKET_NAME, CONTENT_KEY)

    return {
        'statusCode': 200
    }