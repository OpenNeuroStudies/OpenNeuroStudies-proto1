#!/bin/bash

regex='http.*\(cognitiveatlas.org\|cogpo\)' ; 
for d in ds00*; do terms=$(( builtin cd "$d"; git grep -i -le "$regex" | while read f; do jq . < $f | grep "$regex" | grep -v TODO ; done; ) | sort | uniq | nl); if [ ! -z "$terms" ] ; then echo $d; echo "$terms"; fi; done

