# check=skip=InvalidDefaultArgInFrom
# BASE_IMAGE is always passed by the Makefile (pinned per version)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ADD wait-for-it.sh /usr/local/bin/

RUN yum update -y \
    && yum install -y tar gzip procps which \
    && yum clean all
