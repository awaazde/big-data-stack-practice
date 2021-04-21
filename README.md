* * *
To develop and test Glue scripts in local environment, this package mocks underlying AWS functionalities. 
To make this application platform independant, core functionalities have been dockerized. 

Components
==========
1. [Hive](https://hive.apache.org/),
2. [Minio Object storage](https://min.io/) (minio, minio123) Local endpoint: [localhost:9000](http://localhost:9000),
3. [Trino database](https://trino.io/) (admin, no password) Local endpoint: [localhost:8080](http://localhost:8080),
4. [AWS glue libs](https://github.com/awslabs/aws-glue-libs)

Steps
=====
1. Install & run docker
2. Clone this repository,
3. Install the required dependencies & set enviornment variables using **make install** command,
4. Restart the terminal,
5. Once inside the directory, run **make up**

Commands
============
1. Installation: **make install**

        Note: After installation, one needs to restart the terminal. This ensures that all the required environment variables are set permanently.
2. To run: **make up**
3. To stop: **make down**


References
==========
1. [Mock AWS Athena for your ETL tests](https://towardsdatascience.com/mock-aws-athena-for-your-etl-tests-1f5447261705),
2. [Big data stack practice](https://github.com/zhenik-poc/big-data-stack-practice)
3. [Developing and Testing ETL Scripts Locally Using the AWS Glue ETL Library](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-libraries.html#develop-local-python)