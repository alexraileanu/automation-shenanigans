data "vault_generic_secret" "do_auth" {
    path = "secret/do_auth"
}

provider "digitalocean" {
    token = "${data.vault_generic_secret.do_auth.data["token"]}"
}

resource "digitalocean_droplet" "echo" {
    image    = "${var.os}"
    region   = "${var.region}"
    size     = "${var.size}"
    name     = "echo-web-1"
    ssh_keys = ["de:ac:a6:ec:46:e0:19:88:a4:d0:73:13:95:c0:7b:c9"]
}

resource "digitalocean_record" "echo" {
    domain  = "alexraileanu.me"
    type    = "A"
    name    = "echo"
    value   = "${digitalocean_droplet.echo.ipv4_address}"
    ttl     = "60"
}

resource "null_resource" "echo" {
    connection {
        host        = "${digitalocean_droplet.echo.ipv4_address}"
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
        # can't use the hosts file to connect with ansible because it's likely that the dns changes
        # haven't propagated yet so the connection is made directly with the ip received from digitalocean
        command = "ansible-playbook ansible/sites.yml -e 'ansible_host=${digitalocean_droplet.echo.ipv4_address}' -e 'ansible_ssh_user=root' --vault-password-file ~/.ansible/passwd"
    }
}

resource "digitalocean_firewall" "echo" {
    name = "echo-fw"

    inbound_rule = [
        {
            protocol    = "tcp"
            port_range  = "80"
        }, {
            protocol    = "tcp"
            port_range  = "443"
        }, {
            protocol         = "tcp"
            port_range       = "222"
            source_addresses = ["213.127.204.188"]
        }, {
            protocol = "icmp"
        }
    ]

    droplet_ids = ["${digitalocean_droplet.echo.id}"]
}