#!/bin/bash

echo "Nodelist: " > Cluster_info.dat

for f in *.invent;
do
  cat $f | sort -g | uniq > $f.tmp
  echo $(head -n 1 $f.tmp) >> Cluster_info.dat
  head -n 2 $f.tmp | tail -n 1 >> all.tmp
  rm $f
done

tail -n 1 *invent.tmp | awk 'NR%3==2 {sum+=$1} END {print "\nTotal cores: ", sum "\n "}' >> Cluster_info.dat

tail -n 2 *invent.tmp | awk '/Total:/ {sum+=$(NF-1)} 
                             END {print "\nTotal Memory: ", sum"  kb \n              ", sum/1048576 " Gb" }' >> Cluster_info.dat

echo "Node type(s): " >> Cluster_info.dat
cat all.tmp | uniq >> Cluster_info.dat

rm all.tmp
rm *invent.tmp
