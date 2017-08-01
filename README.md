## echo "service"

small service to learn about ansible related stuff. It works on an empty server only after:

* adding your ssh key into the ```~/.ssh/authorized_keys``` file

* adding the ```~/.ssh/id_rsa.pub``` to your github account (for ssh cloning purposes) 

* linking ```/usr/bin/python``` to ```/usr/bin/python3``` (by default ansible checks for the python binary and if it can't find it, it won't run and ubuntu 17.04 only has python3 installed by default)

caveat(s): 

* the first time it runs, the hosts file should have the port 22 for ssh (the default ssh port) but since the port is changed in the sshd_config file, the next times you gotta use the port from the config file (only way I could find to handle port changes in ssh)

### ELK

The way I integrated ELK with this service is like so:

- Filebeat on the echo server reading from serveral log files and shipping to a Redis server
- Logstash reads from that Redis server, applies the filters in the `logstash.conf` file and inserts the data into ElasticSearch
- Kibana is used then for displaying metrics et al

### Terraform

Being the lazy person I am, I decided to look into [terraform](https://terraform.io). The idea is the following: 

- Terraform creates a DigitalOcean droplet
- Updates the DNS configuration on DigitalOcean with the newly created droplet
- Runs Ansible to install all the things
- When everything is done, I just navigate to my service's URL and see my app up and running as expected

At the moment of writing this (01/08/2017) it's still not quite working as I'd want it to so it's still WIP.