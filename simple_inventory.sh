#!/bin/bash

#re-doing this to prompt user
# no more cron job needed! just call this from bashrc as xcbc_checker
# in rpm  run 
#  sed -i "su - xcbc_checker -c \"$HOME/simple_inventory.sh\"" /root/.bashrc
# new comment

filename="$HOME/Cluster_info.dat"
script="$HOME/simple_inventory.sh"
report_email="xsedecb@iu.edu"
invalid=true

echo -e "clear\n bold \n setaf 0" | tput -S
echo 'Thank you for installing the XCBC Rocks Roll!
This script will take inventory of your cluster and send mail back to the XSEDE
Campus Bridging group.
Please participate in order to help us continue to get funding from the NSF! 
If you have not yet added compute nodes, then please delay execution until you
have finished adding nodes.
If your organization blocks port 25 or sendmail, do not let this run 
automatically!  Instead, please send us an email with the resulting 
inventory file in $filename'
tput setaf 1
echo 'Enter "Y" to allow the script to run automatically
Enter "D" to run this next time, if you have not finished with insert-ethers yet
Enter "E" to generate a report to be emailed to $report_email
Enter "N" to never run this again (but please support the team that made this free for you!)'
tput setaf 0

shopt -s nocasematch

while [[ $invalid == "true" ]]; do

  invalid=false
  read option
  
  tput clear

  case $option in
   Y) echo "Thank you for participating! We really appreciate your feedback.";;
   D) echo 'Thank you for participating! 
This will run on your next terminal instance. 
Press any key to continue:';
   read dummyvar;
   echo -e "clear \n sgr0" | tput -S;
   exit;;
   E) echo "Thank you for participating!";;
   N) echo "Please reconsider; your feedback would help us get funding in the 
future. If you change your mind, please run this script from 
$script. 
Press any key to continue"; 
   touch $HOME/remove
   read dummyvar;
   echo -e "clear \n sgr0" | tput -S;
   exit;;
   *) echo "Invalid response: try again."; invalid=true;;
  esac
done

echo -n "Generating inventory report."

if [ -e Cluster_info.dat ]
then
  mv Cluster_info.dat Cluster_info_prev.dat
fi

hostlist=$(grep 'compute' /etc/hosts | awk '{print $3}')

numcores_total=0
mem_total=0
declare -i numcores_total

echo "Nodelist: " >> Cluster_info.dat

for host in $(hostname) $hostlist;
do
  echo -n '.'
  if [ $host == $(hostname) ] 
  then
#get the amount of RAM & cpuinfo without having to use ssh
# headnode example here makes the ssh command below clearer
    head -n 1 /proc/meminfo > info.tmp
    cat /proc/cpuinfo >> info.tmp
# have to get speed from here b/c of cpu scaling... this is getting ugly
    if [ -e /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]
    then
      cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq >> info.tmp
      query='head -n 1 /proc/meminfo && cat /proc/cpuinfo && cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq'
    else
      query='head -n 1 /proc/meminfo && cat /proc/cpuinfo'
    fi
  else
# for the compute nodes get it all from ssh in one shot
    ssh -q $host $query > info.tmp 2> /dev/null
  fi
#check that access was successful
  if [ -s info.tmp ]
  then
#get the processor name
  model=$(grep 'model name' info.tmp | sort | uniq | sed 's/model name//')
#get total RAM of current node ($host)
  mem=$(awk 'NR==1 {print $2}' info.tmp)
# assume that if the headnode has this file, the compute nodes will too
  if [ -e /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]
  then
    speed=$(tail -n 1 info.tmp)
    #put into MHz just like the other one
    speed=$(bc <<< "$speed / 1000")
  else
#if we can't do it the right way, might as well do it the wrong way
    speed=$(grep 'MHz' info.tmp | sort | uniq | awk '{print $4}')
  fi
  speed=$(bc <<< "scale=2; $speed / 1000") #scale speed into GHz
  mem=$(bc <<< "scale=2;$mem/1048576") #scale mem into GiB

# Has to be this way to account for 
# hyperthreading and possible multiple physical processors (with 
# multiple cores each)... 
  phys_cpus=$(grep -i 'physical id' info.tmp | sort | uniq | wc -l) 
  cores_per_cpu=$(grep -i 'cpu cores' info.tmp | awk '{print $4}' | uniq)
  numcores=$(($phys_cpus * $cores_per_cpu))

#these two for summing total cores and memory of cluster
  numcores_total=$(bc <<< "$numcores_total+$numcores")
  mem_total=$(bc <<< "scale=2; $mem_total + $mem")

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

echo -e "\nTotal cores and Memory found:" $numcores_total "cores" $mem_total "GB RAM"

echo -e "\n Total Cores: " $numcores_total >> Cluster_info.dat
echo -e "\n Total Memory: " $mem_total >> Cluster_info.dat

#put processor names & memory into Cluster_info, sorted for uniqeness
echo -e "\n Node type(s): " >> Cluster_info.dat
sort all.tmp | uniq -c >> Cluster_info.dat

rm all.tmp
touch $HOME/remove

if [[ $option == E ]]
then
 echo -e "Report generated! Please email the contents of 
$filename
to $report_email
Thank you again for using the XCBC Rocks Roll!
Press any key to continue."
 read dummyvar
echo -e "clear \n sgr0" | tput -S
 exit
fi

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
   echo "Inventory done! If you upgrade your cluster, and would like to update 
the CB team on your new capabilities, simply run this again from
$filename
Thanks again!
Press any key to continue:"
   read dummyvar
   echo -e "clear \n sgr0" | tput -S
   exit
  fi
  
else

/usr/sbin/sendmail -i -- $report_email<<EOF
subject: new cluster $hostname
from: xsede_inventory@$hostname

$(cat Cluster_info.dat)

EOF
fi

echo "Inventory done! If you upgrade your cluster, and would like to update 
the CB team on your new capabilities, simply run this again from
$filename
Thanks again!
Press any key to continue."

read dummyvar

echo -e "clear \n sgr0" | tput -S
