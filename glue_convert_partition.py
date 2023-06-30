# AWS GLue ETL job which partition a table by year and save as parquet file to s3

import sys

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

## @params: [JOB_NAME, db_name, table_name, target-bucket]


args = getResolvedOptions(sys.argv, ['JOB_NAME', 'source_path', 'target_path', 'partition_path'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

source_data = glueContext.create_dynamic_frame.from_options(connection_type='s3',
                                                            connection_options={'paths': [args['source_path']]},
                                                            format='csv',
                                                            format_options={"withHeader": True, "separator": ","}
                                                            )
transformer_pq = glueContext.write_dynamic_frame.from_options(frame=source_data,
                                                              connection_type='s3',
                                                              connection_options={'path': args['target_path']},
                                                              format='parquet')

transformer_partition = glueContext.write_dynamic_frame.from_options(frame=source_data,
                                                                     connection_type='s3',
                                                                     connection_options={'path': args['partition_path'],
                                                                                         'partitionKeys': ['country']},
                                                                     format='parquet',
                                                                     )
job.commit()
