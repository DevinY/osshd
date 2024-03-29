FROM alpine

ARG DEBIAN_FRONTEND=noninteractive

ARG user

ENV OSSH_USER ${user:-git}

ARG uid

ENV OSSH_UID ${uid:-1000}

ARG gid

ENV OSSH_GID ${gid:-1000}

ARG shell

ENV OSSH_SHELL ${shell:-/bin/sh}

RUN apk update&&apk add openssh git pwgen rsync bash

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

RUN adduser -D -u ${OSSH_UID} -g ${OSSH_GID} -s ${OSSH_SHELL} -h /home/${OSSH_USER} ${OSSH_USER};echo "${OSSH_USER}:`pwgen`" |chpasswd > /dev/null 2>&1

USER ${OSSH_USER}

ADD motd /etc/motd

COPY authorized_keys /home/${OSSH_USER}/.ssh/authorized_keys


USER root

RUN chmod 600 /home/${OSSH_USER}/.ssh/authorized_keys

RUN chmod 700 /home/${OSSH_USER}/.ssh

RUN chown ${OSSH_UID}:${OSSH_GID} /home/${OSSH_USER}/.ssh/authorized_keys&&chmod 700 /home/${OSSH_USER}

RUN chown ${OSSH_UID}:${OSSH_GID} /home/${OSSH_USER} -R

RUN apk del pwgen

EXPOSE 22

CMD    ["/usr/sbin/sshd", "-D"]
