ARG VERSION

FROM amazoncorretto:$VERSION

RUN yum update -y && yum update ca-certificates && yum install -y tar gzip procps

# Create the user
RUN groupadd --gid 1000 non-root \
    && useradd --uid 1000 --gid 1000 -m non-root

RUN curl -L https://github.com/patric-r/jvmtop/releases/download/0.8.0/jvmtop-0.8.0.tar.gz | tar xz \
 && chmod +x jvmtop.sh \
 && mv jvmtop.jar /usr/local/bin/ \
 && mv jvmtop.sh /usr/local/bin/jvmtop

USER non-root
