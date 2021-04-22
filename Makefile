hive_image = homemade/hive:3.1.0
root_dir = $$PWD
current_dir = $(root_dir)
aws_glue_libs_dir = $$PWD/aws-glue-libs

.PHONY: build create-docker-network persistence-up sleep10 metastore-up hive-server-up \
	trino-up up down setup-aws-glue-libs install setup-aws-glue-libs setup-apache-maven \
	setup-spark-hadoop set-env-variables

build:
	docker build -f docker/hive.dockerfile  -t ${hive_image} ./docker

create-docker-network:
	docker network create -d bridge hive-test || docker network ls | grep hive-test

persistence-up:
	docker-compose up -d minio database

minio-provision:
	docker-compose -f docker-compose.s3-provision.yml up

sleep10:
	sleep 10

sleep20:
	sleep 20

sleep40:
	sleep 40

metastore-up:
	docker-compose up -d hive-metastore

hive-server-up:
	docker-compose up -d hive-server

trino-up:
	docker-compose up -d trino

setup-aws-glue-libs:
	rm -rf ${aws_glue_libs_dir}
	git clone -b glue-1.0 https://github.com/awslabs/aws-glue-libs.git

setup-apache-maven:
	rm -rf apache-maven-3.6.0-bin.tar.gz
	wget https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-common/apache-maven-3.6.0-bin.tar.gz
	tar -xzvf apache-maven-3.6.0-bin.tar.gz
	rm apache-maven-3.6.0-bin.tar.gz

setup-spark-hadoop:
	wget https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-1.0/spark-2.4.3-bin-hadoop2.8.tgz
	tar -xzvf spark-2.4.3-bin-hadoop2.8.tgz
	rm spark-2.4.3-bin-hadoop2.8.tgz

set-env-variables:
ifeq ($(AWS_REGION),)
	@read -p "Enter absolute path of default shell profile (.zshrc, .bash_profile):" shell_profile && echo $${shell_profile} \
	&& echo "export PATH=${current_dir}/apache-maven-3.6.0-bin.tar.gz/bin:$$PATH" >> $${shell_profile} \
	&& echo "export SPARK_HOME=${current_dir}/spark-2.4.3-bin-hadoop2.8" >> $${shell_profile} \
	&& echo "export AWS_REGION=eu-west-1" >> $${shell_profile} \
	&& echo "export AWS_ACCESS_KEY_ID=minio" >> $${shell_profile} \
	&& echo "export AWS_SECRET_ACCESS_KEY=minio123" >> $${shell_profile} \
	&& read -p "Enter absolute path of awaazde/web/common/integrations/reports:" pythonpath \
	&& echo "export PYTHONPATH=$${pythonpath}:$${PYTHONPATH}" >> $${shell_profile}
endif

# automate
up: build create-docker-network persistence-up sleep10 minio-provision metastore-up hive-server-up sleep40 trino-up

down:
	docker-compose down
	docker network rm hive-test

install: setup-aws-glue-libs setup-apache-maven setup-spark-hadoop set-env-variables