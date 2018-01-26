FROM centos:7

LABEL io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

# Install hugo
RUN cd /tmp && \
    curl -L https://github.com/gohugoio/hugo/releases/download/v0.34/hugo_0.34_Linux-64bit.tar.gz --output hugo.tar.gz && \
    tar xzvf hugo.tar.gz && \
    mv hugo /usr/bin/hugo && \
    mkdir -p /usr/libexec/s2i && \
    mkdir -p /opt/app-root/src && \
    chown -R 1001:0 /opt/app-root && \
    chmod -R og+rwx /opt/app-root

WORKDIR /opt/app-root/src

COPY ./s2i/* /usr/libexec/s2i/
USER 1001
