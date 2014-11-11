#!/bin/bash
export RIPPLED="$HOME/rippled2/build/gcc.debug/rippled"
export conf="$PWD/$1/rippled.cfg"

function launch ()
{
    $RIPPLED --net --fg --conf $conf&
    export ripd=$!
}

launch
echo $conf;
echo $ripd;

while true;
do
    inotifywait -e close_write $conf;
    echo "conf changed!";
    kill -9 $ripd
    sleep 3
    launch
done

echo "DONE!"

