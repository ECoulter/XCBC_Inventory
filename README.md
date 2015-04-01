Script(s) to call 'roll' on XCBC cluster with 
basic installation. 

Use at your own risk! 

Currently does the following:
   - Asks Rocks for list of hosts
   - Runs inventory on those, asks for hostname, cpuinfo, and memory
   - Compares Rocks list of hosts to those returned from inventory

Could be improved: 

 - make submit.sh clearer?

 - take queue as cmdline option as well?

 - why so slow through the queue? 

 - make output format nicer?
