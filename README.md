# osshd

一個簡單的openssh server image，約有30MB。

我們可以透過他及docker volume分享的方式串接不同服務。

例如: gogs + ossh + D-Laravel

Build OpenSSH image to only with a public key authentication.

# Setup up auhtorzied_keys (option)
You can setup authorized_keys before build an image.

# default user is git and uid is 1000.
docker build -t ossh . 

# Create container with specified port.
docker run --rm --name ossh -dp 2222:22 ossh

# Setup your authorized_keys in runing container.
<pre>
docker exec -ugit -ti ossh sh
cd ~/.ssh
echo "your_open_ssh_public_key" > authorized_keys
</pre>

# Build an user with speceified uid, gid and name
<pre>
docker build \
--build-arg uid=48 \
--build-arg gid=48 \
--build-arg user=apach \
-t ossh48 \
.
</pre>

# build ossh image for current user 
# step1 cat your public key to authorized_keys file.
<pre>
    cat ~/.ssh/id_ed25519.pub > authorized_keys
</pre>
# step2 build ossh image for current user with your key.
<pre>
docker build \
--build-arg uid=$(id -u) \
--build-arg gid=$(id -g) \
--build-arg user=$USER \
-t ossh \
.
</pre>

Or, You can build specified docker file as below command. (this one can run VS Code with Remote - SSH)
<pre>
docker build \
--build-arg uid=1000 \
--build-arg gid=1000 \
--build-arg user=dlaravel \
-t ossh \
-f Dockerfile-ubuntu \
.
</pre>

# step 3 create container and mount volume where you want to access.
<pre>
docker run --name ossh -v $(pwd):/var/www/html -dp 2222:22 ossh
</pre>
