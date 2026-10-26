ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ADD wait-for-it.sh /usr/local/bin/

RUN yum update -y \
    && yum install -y tar gzip procps which \
    && yum clean all
