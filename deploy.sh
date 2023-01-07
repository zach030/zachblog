#!/bin/bash
echo "Hugo Bot is Auto-push and deploy for you......"
hugo -D
git add . && git commit -m $1
git push origin master
# scp -r -i "~/.ssh/mba.cer" ./public/* root@81.69.255.174:/root/hugo/public
