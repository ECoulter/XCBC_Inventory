#!/bin/bash

# have to make sure the mpi environment has control_slaves TRUE
#  and allocation_rule $round_robin
# takes nmachines as 1st and only arg

NODEFILE=.machines.txt

rocks list host | awk '$2=="Compute" {print substr($1,1,length($1)-1)}' > $NODEFILE

qsub -N Job1 -cwd -b y /opt/openmpi/bin/mpirun -machinefile $NODEFILE inventory.sh

qsub -b y -N cleanup -hold_jid Job1 -cwd ./inventory_results.sh $NODEFILE

