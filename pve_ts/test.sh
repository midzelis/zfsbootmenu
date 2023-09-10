#!/bin/bash
# set -x 

# hello() {
#     echo 1 $1
#     v=$(printf "$1\n" hi)
#     echo 2 "$v"
#     echo 3 $(printf "$1\n" hi)
#     echo 4 "$(printf "$1" "hi ok")"
# }

# hello "hi there '%s'"

hi() {
    echo $1
    if [[ "$1" == pattern* ]]; then
        echo "match"
    else 
        echo "no"
    fi
}

hi "patern:there"
hi "nomatch"

