#!/bin/zsh
for n in {0..$1};
  do  $RIPPLED --conf $PWD/N$n/rippled.cfg server_state |& grep -e "peers";
done