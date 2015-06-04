#!/bin/bash
# takes as input the machinefile from MPI
# could set as an environment variable instead?

echo "Nodelist: " > Cluster_info.dat

for f in *.invent;
do
#clean up duplicate lines from multiple processes per node
  cat $f | sort -g | uniq > $f.tmp
#take only hostnames into Cluster_info
  echo $(head -n 1 $f.tmp) >> Cluster_info.dat
#put the rest into all for cleanup of node types later
  head -n 2 $f.tmp | tail -n 1 >> all.tmp
  rm $f
done

#count number of cores
tail -n 1 *invent.tmp | awk 'NR%3==2 {sum+=$1} END {print "\nTotal cores: ", sum "\n "}' >> Cluster_info.dat

#sum RAM of cluster
tail -n 2 *invent.tmp | awk '/Total:/ {sum+=$(NF-1)} 
                             END {print "\nTotal Memory: ", sum"  kb \n              ", sum/1048576 " Gb" }' >> Cluster_info.dat

#put processor names into Cluster_info, sorted for uniqeness
echo "Node type(s): " >> Cluster_info.dat
cat all.tmp | uniq >> Cluster_info.dat

#take list of nodes from MPI & compare to the machinefile
# have to run cut b/c the format from Cluster_info has 'compute-0-0.local' and machinefile has only 'compute-0-0'
awk 'NR>1&&!/Total cores:/ {print $0} /Total cores:/ {exit}' Cluster_info.dat | cut -f 1 -d'.' > mpinodes.txt

badnodes=$(diff $1 mpinodes.txt)

if [ ! -z "$badnodes" ];
then
  echo "MISMATCH IN NODES FROM ROCKS AND MPI!" >> Cluster_info.dat
  echo $badnodes >> Cluster_info.dat
fi

rm all.tmp
rm mpinodes.txt
rm *invent.tmp
