#!/bin/bash

if [ -e Cluster_info.dat ]
then
  mv Cluster_info.dat Cluster_info_prev.dat
fi

hostlist=$(grep compute /etc/hosts | awk '{print $3}')

echo "Nodelist: " >> Cluster_info.dat

for host in $(hostname) $hostlist;
do
  if [ $host == $(hostname) ] 
  then
#get the amount of RAM & cpuinfo without having to use ssh
    head -n 1 /proc/meminfo > info.tmp
    cat /proc/cpuinfo >> info.tmp
    cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq >> info.tmp
  else
# have to get speed from here b/c of cpu scaling... this is getting ugly
    ssh -q $host 'head -n 1 /proc/meminfo && cat /proc/cpuinfo && cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq' > info.tmp
  fi
#check that access was successful
  if [ -s info.tmp ]
  then
  model=$(grep 'model name' info.tmp | sort | uniq | sed 's/model name//')
  mem=$(awk 'NR==1 {print $2}' info.tmp)
  #get speed from here since can't trust cpuinfo MHz which can be scaled
  # assume that if the headnode has this file, the compute nodes will too
  if [ -e /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]
  then
    speed=$(tail -n 1 info.tmp)
    #put into MHz just like the other one
    speed=$(bc <<< "$speed / 1000")
  else
  #if we can't do it the right way, might as well do it the wrong way
    speed=$(grep MHz info.tmp | sort | uniq)
  fi
  speed=$(bc <<< "scale=2; $speed / 1000") #scale speed into GHz
  mem=$(bc <<< "scale=2;$mem/1048576") #scale mem into GiB

#I am so sorry about the following - has to be this way to account for 
# hyperthreading and possible multiple physical processors (with 
# multiple cores each)... 
  phys_cpus=$(grep -i 'physical id' info.tmp | sort | uniq | wc -l) 
  cores_per_cpu=$(grep -i 'cpu cores' info.tmp | awk '{print $4}' | uniq)
  numcores=$(($phys_cpus * $cores_per_cpu))
#these two for summing total cores and memory of cluster
  echo $numcores >> corelist.tmp
  echo $mem >> memlist.tmp
# put into all.tmp for later counted list of node types
  echo " X "$model " RAM: " $mem "GiB  CPUSpeed: " $speed "GHz, with" $phys_cpus "cpus and " $numcores "cores" >> all.tmp

#get the naming right for the headnode...
  if [ $host == $(hostname) ] 
  then
    name_string=$(echo "  Headnode - " $host)
  else
    name_string=$(echo "  "$host)
  fi

#gather the node info for the brief summary
  info_string=$(echo " has " $phys_cpus " cpus with " $cores_per_cpu " cores each")
  else #from the -s info.tmp test above - this means access failed
    name_string=$(echo "  "$host)
    info_string="access failed"
  fi
  echo "  "$name_string $info_string >> Cluster_info.dat

done

#count number of cores
awk '{sum+=$1} END {print "\nTotal cores: ", sum}' corelist.tmp >> Cluster_info.dat
rm corelist.tmp

#sum RAM of cluster
awk '{sum+=$1} END {print "\nTotal Memory: ", sum" GiB \n" }' memlist.tmp >> Cluster_info.dat
rm memlist.tmp

#put processor names & memory into Cluster_info, sorted for uniqeness
echo "Node type(s): " >> Cluster_info.dat
sort all.tmp | uniq -c >> Cluster_info.dat

rm all.tmp

report_email="jecoulte@iu.edu"

if [ -e Cluster_info_prev.dat ]
then
 change_test=$(diff Cluster_info.dat Cluster_info_prev.dat)
  if [ -n "$change_test" ]
  then
/usr/sbin/sendmail -i -- $report_email<<EOF
subject: cluster update $hostname
from: xsede_inventory@$hostname

$(cat Cluster_info.dat)

Changelog:
$change_test

EOF
  else
    exit
  fi
  
else

/usr/sbin/sendmail -i -- $report_email<<EOF
subject: new cluster $hostname
from: xsede_inventory@$hostname

$(cat Cluster_info.dat)

EOF
fi

