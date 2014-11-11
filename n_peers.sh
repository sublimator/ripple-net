#!/usr/bin/zsh
for n in {0..$1}
$HOME/rippled2/build/gcc.debug/rippled --conf $PWD/N$n/rippled.cfg server_state | grep -e "peers"

