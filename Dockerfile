FROM ubuntu:12.04
MAINTAINER Devin Yang <devin@ccc.tc> 

ARG key

ENV KEY ${key:-nokey}

ARG user

ENV OSSH_USER ${user:-git}

RUN apt-get update&&apt-get install -y openssh-server git pwgen

RUN mkdir /var/run/sshd
RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config && \
    sed -ri 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

RUN mkdir /root/.ssh

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/${OSSH_USER} --gecos "User" ${OSSH_USER};echo "${OSSH_USER}:`pwgen`" |chpasswd

USER ${OSSH_USER}

RUN mkdir -p /home/${OSSH_USER}/.ssh&&chmod 700 /home/${OSSH_USER}/.ssh

RUN echo "${KEY}" > /home/${OSSH_USER}/.ssh/authorized_keys

RUN chmod 600 /home/${OSSH_USER}/.ssh/authorized_keys

USER root

RUN apt-get -y --purge remove pwgen

EXPOSE 22

CMD  ["/usr/sbin/sshd", "-D"]
