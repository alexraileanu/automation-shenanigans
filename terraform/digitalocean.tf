provider "digitalocean" {
    token = "${var.do_token}"
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
            "ln -s /usr/bin/python3 /usr/bin/python"
        ]

    }

    provisioner "local-exec" {
        command = "ansible-playbook ansible/sites.yml -e 'ansible_host=${digitalocean_droplet.echo.ipv4_address}'"
    }
}