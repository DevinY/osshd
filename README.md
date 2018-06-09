# osshd

Build OpenSSH image to only with a public key.

KEY=`cat ~/.ssh/id_rsa.pub`&&docker build --build-arg user="${USER}" --build-arg key="${KEY}" -t osshd .
