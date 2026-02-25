#!/bin/zsh --no-rcs

if [[ ${cached:-0} -ne 1 ]]; then
    open -b "com.runningwithcrayons.Alfred" alfred://runtrigger/com.zeitlings.mkfile/build
    echo -n cache
else
    echo -n "$1"
fi
