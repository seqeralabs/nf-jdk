ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ADD wait-for-it.sh /usr/local/bin/
## CVE-2026-91403: distrust the compromised eMudhra intermediate CAs ahead of a Corretto fix
ADD install-blocked-certs.sh blocked.certs /tmp/

RUN yum update -y \
    && yum install -y tar gzip procps which \
    && yum clean all \
    && bash /tmp/install-blocked-certs.sh /tmp/blocked.certs \
    && rm -f /tmp/install-blocked-certs.sh /tmp/blocked.certs
