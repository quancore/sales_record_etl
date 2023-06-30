FROM public.ecr.aws/lambda/python:3.9

RUN yum update -y && yum install -y wget && yum clean all

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh  \
    && sh Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda

COPY environment.yml /tmp/environment.yml

RUN /opt/miniconda/bin/conda env create --file /tmp/environment.yml --prefix /opt/conda-env

RUN /opt/conda-env/bin/pip install awslambdaric

RUN mv /var/lang/bin/python3.9 /var/lang/bin/python3.9-clean && ln -sf /opt/conda-env/bin/python /var/lang/bin/python3.9
COPY download.py unzip.py /opt/my-code/
ENV PYTHONPATH "/var/lang/lib/python3.9/site-packages:/opt/my-code"

CMD ["download.lambda_handler"]