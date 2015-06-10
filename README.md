Script(s) to call 'roll' on XCBC cluster with 
basic installation. 

The rpm install takes the following steps: 

 Creates a new user 'xcbc_checker' to handle running the script 
  -that user not allowed to login; homedir is set to /opt/xcbc_inventory
 Creates a cron job in /etc/cron.d/xcbc_inventory to run once a month  
  on (day of installation) + 1 to allow time for compute nodes
  to come online
 Copies simple_inventory.sh into /opt/xcbc_inventory

New Version (simple_inventory.sh):
Currently:
   - finds list of compute nodes from /etc/hosts
   - grabs information from nodes over ssh
   - turns into nice data sheet
   - does NOT support GPU nodes yet
   - does NOT deal with schedulers

Old Version:
Currently does the following:
   - Asks Rocks for list of hosts
   - Runs inventory on those, asks for hostname, cpuinfo, and memory
   - Compares Rocks list of hosts to those returned from inventory

Could be improved: 

 - make submit.sh clearer?

 - take queue as cmdline option as well?

 - why so slow through the queue? 

 - make output format nicer?
