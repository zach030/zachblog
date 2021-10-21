#!/bin/bash
hugo -D
git add . && git commit -a 'new posts'
git push origin master
scp -r -i "~/.ssh/new_wsl.pem" ./public/* root@81.69.255.174:/root/hugo/public
