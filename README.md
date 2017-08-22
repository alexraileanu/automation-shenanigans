## echo "service"

small service to learn about ansible related stuff. It works on an empty server without any prior config just by running ansible.

caveat(s): 

* the first time it runs, the hosts file should have the port 22 for ssh (the default ssh port) but since the port is changed in the sshd_config file, the next times you gotta use the port from the config file (only way I could find to handle port changes in ssh)

### ELK

The way I integrated ELK with this service is like so:

- Filebeat on the echo server reading from serveral log files and shipping to a Redis server
- Logstash reads from that Redis server, applies the filters in the `logstash.conf` file and inserts the data into ElasticSearch
- Kibana is used then for displaying metrics et al

### Terraform

Being the lazy person I am, I decided to look into [terraform](https://terraform.io). The idea is the following: 

- Terraform spawns one EC2 instance and runs ansible on it and creates a DynamoDB table (used in the application for logging purposes)
- Terraform updates the DNS configuration on DigitalOcean with the newly created EC2 instance's IP (I chose to use DigitalOcean to manage the DNS config because it's free while AWS charges for that as far as I can tell)
- Terraform creates the needed security groups in AWS so that there's no funny stuff regarding access from and to the instance
- Ansible then installs and configures the instance so that my service runs on it
- When everything is done, I just navigate to my service's URL and see my app up and running as expected