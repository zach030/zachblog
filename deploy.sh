#!/bin/bash
hugo -D
git add . && git commit -m $0
git push origin $1
scp -r -i "~/.ssh/new_wsl.pem" ./public/* root@81.69.255.174:/root/hugo/public
