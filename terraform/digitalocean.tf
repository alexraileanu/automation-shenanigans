data "vault_generic_secret" "do_auth" {
    path = "secret/do_auth"
}

provider "digitalocean" {
    token = "${data.vault_generic_secret.do_auth.data["token"]}"
}

resource "digitalocean_droplet" "echo-cluster" {
    count    = 2
    image    = "${var.os}"
    region   = "${var.region}"
    size     = "${var.size}"
    name     = "${var.echo_cluster_names[count.index]}"
    ssh_keys = ["de:ac:a6:ec:46:e0:19:88:a4:d0:73:13:95:c0:7b:c9"]
    private_networking = true
}

resource "digitalocean_record" "echo" {
    domain  = "alexraileanu.me"
    type    = "A"
    name    = "echo"
    value   = "${element(digitalocean_droplet.echo-cluster.*.ipv4_address, 0)}"
    ttl     = "60"
}

resource "null_resource" "echo-cluster" {
    count = 2

    connection {
        host        = "${element(digitalocean_droplet.echo-cluster.*.ipv4_address, count.index)}"
        type        = "ssh"
        user        = "root"
        private_key = "${file("~/.ssh/id_rsa")}"
    }

    provisioner "remote-exec" {
        inline = [
            "sleep 30s",
            "ln -s /usr/bin/python3 /usr/bin/python"
        ]
         # The only reason for this to fail in this setup is if the file already exists
         # which means this terraform has already ran on the server, so it's ok to ignore it
        on_failure = "continue"
    }

    provisioner "local-exec" {
        # Creates a hosts file with the name of the droplet to be a tiny bit more organized i guess
        command = "touch ansible/hosts/${var.host_names[count.index]} && echo '[${var.host_names[count.index]}]\n${element(digitalocean_droplet.echo-cluster.*.ipv4_address, count.index)} ansible_ssh_user=root' > ansible/hosts/${var.host_names[count.index]}"
    }

    provisioner "local-exec" {
        # i know this will add the variables echo_ip and redis_ip to both ansible hosts but idk how to do it otherwise
        # i'd only need this variable on one of the iterations of the loop and i'd rather not have if/else
        # TODO: find a better solution
        command = "${var.ansible_commands[count.index]} -e 'echo_ip=${element(digitalocean_droplet.echo-cluster.*.ipv4_address, 0)}' -e 'redis_ip=${element(digitalocean_droplet.echo-cluster.*.ipv4_address, 1)}'"
    }
}


resource "digitalocean_firewall" "echo" {
    name = "echo-fw"

    inbound_rule = [
        {
            protocol         = "tcp"
            port_range       = "80"
            source_addresses = ["0.0.0.0/0", "::/0"]
        }, {
            protocol         = "tcp"
            port_range       = "443"
            source_addresses = ["0.0.0.0/0", "::/0"]
        }, {
            protocol         = "tcp"
            port_range       = "222"
            source_addresses = ["213.127.204.188"]
        }, {
            protocol         = "tcp"
            port_range       = "22"
            source_addresses = ["213.127.204.188"]
        }, {
            protocol         = "icmp"
            source_addresses = ["0.0.0.0/0", "::/0"]
        }, {
            protocol         = "tcp"
            port_range       = "6379"
            source_addresses = ["${element(digitalocean_droplet.echo-cluster.*.ipv4_address, 0)}"]
        }
    ]

    outbound_rule = [
        {
            protocol              = "icmp"
            destination_addresses = ["0.0.0.0/0", "::/0"]
        },
        {
            protocol              = "tcp"
            port_range            = "all"
            destination_addresses = ["0.0.0.0/0", "::/0"]
        },
        {
            protocol              = "udp"
            port_range            = "all"
            destination_addresses = ["0.0.0.0/0", "::/0"]
        }
    ]

    droplet_ids = ["${digitalocean_droplet.echo-cluster.*.id}"]
}