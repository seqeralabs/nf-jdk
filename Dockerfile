ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ADD distrust-certs.sh wait-for-it.sh /usr/local/bin/

RUN yum update -y \
    && yum install -y tar gzip procps which \
    && bash /usr/local/bin/distrust-certs.sh \
    && yum clean all \
    && rm -f /usr/local/bin/distrust-certs.sh
