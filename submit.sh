#!/bin/bash

# have to make sure the mpi environment has control_slaves TRUE
#  and allocation_rule $round_robin
# takes nmachines as 1st and only arg

NMACHINES=$1

qsub -N job -cwd -b y -pe mpi $NMACHINES /opt/openmpi/bin/mpirun inventory.sh

qsub -b y -N cleanup -hold_jid job -cwd ./inventory_results.sh

