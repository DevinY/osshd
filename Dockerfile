FROM alpine
MAINTAINER Devin Yang <devin@ccc.tc> 

ARG key

ENV KEY ${key:-nokey}

ARG user

ENV OSSH_USER ${user:-git}

#RUN apt-get update&&apt-get install -y openssh-server git pwgen
RUN apk update&&apk add openssh git pwgen rsync


RUN mkdir /var/run/sshd
RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config && \
    sed -ri 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

RUN mkdir /root/.ssh

RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa &&\  
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa &&\
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa &&\
    ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
#RUN apt-get clean &&  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/${OSSH_USER} --gecos "User" ${OSSH_USER};echo "${OSSH_USER}:`pwgen`" |chpasswd
RUN adduser -D -s /bin/sh -h /home/${OSSH_USER} ${OSSH_USER};echo "${OSSH_USER}:`pwgen`" |chpasswd > /dev/null 2>&1

USER ${OSSH_USER}

RUN mkdir -p /home/${OSSH_USER}/.ssh&&chmod 700 /home/${OSSH_USER}/.ssh

RUN echo "${KEY}" > /home/${OSSH_USER}/.ssh/authorized_keys

RUN chmod 600 /home/${OSSH_USER}/.ssh/authorized_keys

USER root

#RUN apt-get -y --purge remove pwgen
RUN apk del pwgen

EXPOSE 22

CMD  ["/usr/sbin/sshd", "-D"]
