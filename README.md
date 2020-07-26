# osshd

一個簡單的openssh server image，約有30MB。

我們可以透過他及docker volume分享的方式串接不同服務。

例如: gogs + ossh + D-Laravel

Build OpenSSH image to only with a public key authentication.

#Setup up auhtorzied_keys (option)
You can setup authorized_keys before build an image.

#default user is git.
docker build -t ossh . 

#Create container with specified port.
docker run --rm --name ossh -dp 2222:22 ossh

#Setup your authorized_keys in runing container.
<pre>
docker exec -ugit -ti ossh sh
cd ~/.ssh
echo <your_open_ssh_public_key> > authorized_keys
</pre>

#Build an user with speceified uid and gid
<pre>
docker build \
--build-arg uid=48 \
--build-arg gid=48 \
--build-arg user=apach \
-t ossh48 \
.
</pre>
