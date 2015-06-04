#!/bin/bash

hostlist=$(grep compute /etc/hosts | awk '{print $3}')

echo "Nodelist: " > Cluster_info.dat

for host in $hostlist;
do
  echo $host >> Cluster_info.dat
  ssh $host 'head -n 1 /proc/meminfo && cat /proc/cpuinfo' > info.tmp

  model=$(grep 'model name' info.tmp | sort | uniq)
  mem=$(awk 'NR==1 {print $2}' info.tmp)
  #get speed from here since can't trust cpuinfo MHz which can be scaled
  if [ -e /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]
  then
    speed=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
    #put into MHz just like the other one
    speed=$(bc <<< "$speed / 1000")
  else
  #if we can't do it the right way, might as well do it the wrong way
    speed=$(grep MHz info.tmp | sort | uniq)
  fi
  speed=$(bc <<< "scale=2; $speed / 1000") #scale speed into GHz
  mem=$(bc <<< "scale=2;$mem/1048576") #scale mem into GiB
  echo $model " RAM: " $mem "GiB  CPUSpeed: " $speed "GHz" >> all.tmp

#I am so sorry about the following - has to be this way to account for 
# hyperthreading and possible multiple physical processors (with 
# multiple cores each)... 
  phys_cpus=$(grep -i 'physical id' info.tmp | sort | uniq | wc -l)
  cores_per_cpu=$(grep -i 'core id' info.tmp | sort | uniq | wc -l)
  numcores=$(($phys_cpus * $cores_per_cpu))
  echo $numcores >> corelist.tmp
  echo $mem >> memlist.tmp

#calculate the flops on a per-node basis in case of cluster heterogeneity  
#  numflops=$(($numcores*$speed*$instructs_per_cycle))
  rm info.tmp
done

#count number of cores
awk '{sum+=$1} END {print "\nTotal cores: ", sum}' corelist.tmp >> Cluster_info.dat
rm corelist.tmp

#sum RAM of cluster
awk '{sum+=$1} END {print "\nTotal Memory: ", sum" GiB \n" }' memlist.tmp >> Cluster_info.dat
rm memlist.tmp

#put processor names & memory into Cluster_info, sorted for uniqeness
echo "Node type(s): " >> Cluster_info.dat
uniq all.tmp >> Cluster_info.dat

rm all.tmp
