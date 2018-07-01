# osshd

一個簡單的openssh server image，只有24MB。

我們可以透過他及docker volume分享的方式串接不同服務。

例如: gogs + ossh + D-Laravel

Build OpenSSH image to only with a public key.
<pre>
KEY=`cat ~/.ssh/id_rsa.pub`&&docker build --build-arg user="${USER}" --build-arg key="${KEY}" -t osshd .
</pre>
or 

#default user is git.

docker build  -t osshd . --build-arg key="your public key of ssh"

