# AWS GLue ETL job which partition a table by year and save as parquet file to s3

import sys

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

## @params: [JOB_NAME, db_name, table_name, target-bucket]


args = getResolvedOptions(sys.argv, ['JOB_NAME', 'db_name', 'table_name', 'target_bucket'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)


source_data = glueContext.create_dynamic_frame.from_catalog(database=args['db_name'], table_name=args['table_name'])
transformer = glueContext.write_dynamic_frame.from_options(frame=source_data,
                                                           connection_type='s3',
                                                           connection_options={'path': args['target_bucket'],
                                                                               'partitionKeys': ['year']},
                                                           format='parquet',
                                                           transformation_ctx='transformer')
job.commit()
