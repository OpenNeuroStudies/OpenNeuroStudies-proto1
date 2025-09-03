#!/bin/bash
#
# To determine which datasets were produced using heudiconv, and provide some
# information on them, such as versions if known and the date of the first
# commit

for ds in "$@"; do
    found=
    if [ -e "$ds/.heudiconv" ]; then
        found=".heudiconv "
    fi
    versions=$(git -C "$ds" grep -h HeudiconvVersion | sed -e 's,^ *,,g' | sort | uniq -c | tr '\n' ' ')
    if [ -n "$versions" ]; then
        found+=" versions: $versions"
    fi
    if git -C "$ds" grep randstr '**/*.tsv' | grep -q .; then
        found+=" randstr"
    fi
    if [ -z "$found" ]; then
        continue
    fi
    d=$(git -C "$ds" log --reverse --format="%ai" | head -1)
    echo "$ds: $d $found"
done

