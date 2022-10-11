ARG VERSION
ARG USERNAME=non-root
ARG USER_UID=1000
ARG USER_GID=$USER_UID


FROM amazoncorretto:$VERSION

RUN yum update -y && yum update ca-certificates && yum install -y tar gzip procps

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

USER $USERNAME

RUN curl -L https://github.com/patric-r/jvmtop/releases/download/0.8.0/jvmtop-0.8.0.tar.gz | tar xz \
 && chmod +x jvmtop.sh \
 && mv jvmtop.jar /usr/local/bin/ \
 && mv jvmtop.sh /usr/local/bin/jvmtop
