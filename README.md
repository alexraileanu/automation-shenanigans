## echo "service"

small service to learn about ansible related stuff. It works on an empty server only after:

* adding your ssh key into the ```~/.ssh/authorized_keys``` file

* adding the ```~/.ssh/id_rsa.pub``` to your github account (for ssh cloning purposes) 

* linking /usr/bin/python to /usr/bin/python3 (by default ansible checks for the python binary and if it can't find it, it won't run and ubuntu 17.04 only has python3 installed by default)

caveat(s): 

* the first time it runs, the hosts file should have the port 22 for ssh (the default ssh port) but since the port is changed in the sshd_config file, the next times you gotta use the port from the config file (only way I could find to handle port changes in ssh)