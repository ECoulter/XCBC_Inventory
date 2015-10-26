Script(s) to call 'roll' on XCBC cluster with 
basic installation. 

The rpm install takes the following steps: 

 Creates a new user 'xcbc_checker' to handle running the script 
  -that user not allowed to login; homedir is set to /opt/xcbc_inventory
 Copies simple_inventory.sh into /opt/xcbc_inventory
 Adds lines in .bashrc to run inventory script on install; informs user
 and asks permission, explaining problems if port 25 is blocked.

New Version (simple_inventory.sh):
Currently:
   - finds list of compute nodes from /etc/hosts
   - grabs information from nodes over ssh
   - turns into nice data sheet
   - emails out to $report_email
   - does NOT support GPU nodes yet
   - does NOT deal with schedulers
