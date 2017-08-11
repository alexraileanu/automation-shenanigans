variable "os" {
    description = "Key for Ubuntu 17.04"
    default     = "ubuntu-17-04-x64"
}

variable "region" {
    description = "Key for the region"
    default     = "ams2"
}

variable "size" {
    description = "Size of the droplet"
    default     = "512mb"
}

variable "ansible_commands" {
    default = {
        "0" = "ansible-playbook ansible/web.yml -i ansible/hosts/echo-web -e 'ansible_ssh_user=root' --vault-password-file ~/.ansible/passwd"
        "1" = "ansible-playbook ansible/redis.yml -i ansible/hosts/echo-redis -e 'ansible_ssh_user=root' --vault-password-file ~/.ansible/passwd"
    }
}

variable "echo_cluster_names" {
    default = {
        "0" = "echo-web-1"
        "1" = "echo-redis-1"
    }
}

variable "host_names" {
    default = {
        "0" = "echo-web"
        "1" = "echo-redis"
    }
}