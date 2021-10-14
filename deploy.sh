#!/bin/bash
hugo -D
scp -r -i "~/.ssh/new_wsl.pem" ./public/* root@81.69.255.174:/root/hugo/public
