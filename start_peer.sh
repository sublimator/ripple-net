#!/usr/bin/env bash
export conf="$PWD/N$1/rippled.cfg"
export extraArgs="${@:2}"

function launch ()
{
    $RIPPLED $extraArgs --fg --conf $conf&
    export ripd=$!
}

launch
echo $conf;
echo $ripd;

while true;
do
    fswatch -o $conf | echo
    echo "conf changed!";
    kill -9 $ripd
    sleep 3
    launch
done

echo "DONE!"