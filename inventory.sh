#!/bin/bash
host=$host$(hostname)

mem=$(head -n 1 /proc/meminfo)
echo $host >> $host.invent
model=$(cat /proc/cpuinfo | grep 'model name' | uniq)
mhz=$(cat /proc/cpuinfo | grep 'MHz' | uniq)
echo $model " , " $mhz " , " $mem >> $host.invent
cat /proc/cpuinfo | grep processor | wc -l >> $host.invent
