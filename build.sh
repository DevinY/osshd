#!/bin/bash
#Example for build image for php and ssh
docker build \
--build-arg uid=1000 \
--build-arg gid=1000 \
--build-arg user=dlaravel \
-t ossh \
-f Dockerfile-ubuntu \
.
