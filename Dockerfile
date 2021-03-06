#FROM centos/s2i-base-centos7
#FROM centos:centos7 
FROM openshift/base-centos7

MAINTAINER Flannon Jackson <flannon@flannon@nyu.edu>

ENV NGINX_VERSION=1:1.12.2-2
ENV RELEASE=el7

# Install required packages here:
RUN export ARCH=$(arch) && \
    yum install -y epel-release --setopt=tsflags=nodocs && \
    PACKAGES="nginx-${NGINX_VERSION}.${RELEASE}.${ARCH}" && \
    yum install -y --setopt=tsflags=nodocs ${PACKAGES} && \
    rpm -V ${PACKAGES} && \
    yum clean all -y

#RUN sed -i 's/80/8080/' /etc/nginx/nginx.conf
#RUN sed -i 's/user nginx;//' /etc/nginx/nginx.conf

# Create a non root account called 'default' to be the owner of all the
# files which the Apache httpd server will be hosting. This account
# needs to be in group 'root' (gid=0) as that is the group that the
# Apache httpd server would use if the container is later run with a
# unique user ID not present in the host account database, using the
# command 'docker run -u'.

ENV HOME=/opt/app-root

RUN mkdir -p ${HOME} && \ 
    [[ $(grep default /etc/passwd) ]] || \
        useradd -u 1001 -r -g 0 -d ${HOME} -s /sbin/nologin \
        -c "Default Application User" default 

ENV PORT=8080

RUN mkdir -p ${HOME}/html && \
    mkdir -p ${HOME}/etc/nginx.conf.d 

COPY ./etc/ ${HOME}/etc/

RUN mv -f /opt/app-root/etc/nginx.server.sample.conf ${HOME}/etc/nginx.conf.d/default.conf && \
    chown -R 1001:1001 $HOME


# Set the default port for applications built using this image
EXPOSE 8080


# Copy the s2i builder scripts into place
COPY ./s2i ${HOME}/s2i
COPY ./run ${HOME}/run

#RUN  chmod -R 777 /var/log/nginx /var/cache/nginx/ /var/run \
RUN  chmod -R 777 /var/lib/nginx && \
     chmod -R 777 /var/log /var/run ${HOME}/run && \
     chmod 777 ${HOME}/etc ${HOME}/etc/nginx.conf.d && \
     #&& chmod 644 /etc/nginx/* \
     chmod 755 /etc/nginx/conf.d && \
     chmod 755 ${HOME}/s2i/bin && \
     chmod -R 777 /opt/ && \
     chmod -R 777 /sbin /usr/sbin
     #&& chmod 644 /etc/nginx/conf.d/default.conf

# TODO: Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building nginx" \
      io.k8s.display-name="nginx 1.2.12" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,webserver,html,nginx" \
      #io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"
      io.openshift.s2i.scripts-url="image://${HOME}/s2i/bin"

#(optional): Copy the builder files into /opt/app-root
#COPY ./s2i/bin/ /opt/app-root


#Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
#COPY ./s2i/bin/ /usr/libexec/s2i
COPY ./s2i /usr/libexec/s2i

#Drop the root user and make the content of /opt/app-root owned by user 1001
#RUN chown -R 1001:1001 /opt/app-root && \
RUN chown -R 1001:0 /opt/app-root && \
    find ${HOME} -type d -exec chmod g+ws {} \;

# Ensure container runs as non-root user

WORKDIR ${HOME}

USER 1001

# Set the default CMD for the image
CMD ["/usr/libexec/s2i/bin/run"]
