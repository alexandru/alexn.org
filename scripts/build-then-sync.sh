#!/usr/bin/env bash

cd `dirname $0`/..

bundle exec middleman build
mkdir -p $HOME/.ssh
cp scripts/travis_rsa $HOME/.ssh
chmod -R go-rwx $HOME/.ssh

rsync --delete-excluded -Pacv \
  -e "ssh -p 223 -o 'StrictHostKeyChecking no' -i $HOME/.ssh/travis_rsa" \
  build/ alex@alexn.org:/var/www/alexn.org/
