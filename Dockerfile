ARG VERSION=24-al2023
FROM public.ecr.aws/amazoncorretto/amazoncorretto:$VERSION

ADD wait-for-it.sh /usr/local/bin/

RUN yum update -y \
    && yum install -y tar gzip procps which \
    && yum clean all
