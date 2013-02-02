#!/bin/bash

i=1
while [ "$i" -le 100 ]
do
    curl -X "POST" -H "nsp-sig: xxxx" -T "logs/filename" "http://localhost/test"
    i=$((i+1))
done
