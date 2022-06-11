ARG VERSION
FROM amazoncorretto:$VERSION

RUN yum update -y && yum update ca-certificates && yum install -y tar gzip procps
RUN curl -L https://github.com/patric-r/jvmtop/releases/download/0.8.0/jvmtop-0.8.0.tar.gz | tar xz \
 && chmod +x jvmtop.sh \
 && mv jvmtop.jar /usr/local/bin/ \
 && mv jvmtop.sh /usr/local/bin/jvmtop
