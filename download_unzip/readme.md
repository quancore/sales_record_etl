aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 448303281314.dkr.ecr.eu-central-1.amazonaws.com

docker build -t download_unzip:latest .
docker tag download_unzip:latest 448303281314.dkr.ecr.eu-central-1.amazonaws.com/sales_record/download_unzip:latest
