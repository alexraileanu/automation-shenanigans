data "vault_generic_secret" "do_auth" {
    path = "secret/do_auth"
}

provider "aws" {
    region   = "eu-central-1"
    profile  = "default"
}

provider "digitalocean" {
    token = "${data.vault_generic_secret.do_auth.data["token"]}"
}

resource "aws_security_group" "echo_web_sg" {
    name    = "echo_web_sg"
    description = "Rules for echo"

    ingress = [
        {
            to_port = 22
            from_port = 22
            protocol = "tcp"
            cidr_blocks = ["213.127.204.188/32"]
        }, {
            to_port = 222
            from_port = 222
            protocol = "tcp"
            cidr_blocks = ["213.127.204.188/32"]
        }, {
            to_port = 80
            from_port = 80
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }, {
            to_port = 443
            from_port = 443
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    ]

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_dynamodb_table" "echo_dynamodb" {
    name = "echo"
    read_capacity = 5
    write_capacity = 5
    hash_key = "id"

    attribute {
        name = "id"
        type = "S"
    }
}

resource "aws_key_pair" "auth" {
  key_name   = "echo"
  public_key = "${file("~/.ssh/echo.pub")}"
}

resource "aws_instance" "echo_web" {
    ami           = "ami-1e339e71"
    instance_type = "t2.nano"
    key_name      = "echo-key"
    vpc_security_group_ids = ["${aws_security_group.echo_web_sg.id}"]
    key_name = "${aws_key_pair.auth.id}"

    connection {
        user = "ubuntu"
    }

    provisioner "local-exec" {
        command = "echo 'waiting for the instance to be up before attempting to ssh into it' && sleep 30s"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo ln -s /usr/bin/python3 /usr/bin/python"
        ]
         # The only reason for this to fail in this setup is if the file already exists
         # which means this terraform has already ran on the server, so it's ok to ignore it
        on_failure = "continue"
    }

    provisioner "local-exec" {
        command = "echo '[echo-web]\n${aws_instance.echo_web.public_ip} ansible_ssh_user=ubuntu' > ansible/hosts/echo"
    }

    tags {
        Name = "echo-web"
    }
}

resource "digitalocean_record" "echo" {
    domain  = "alexraileanu.me"
    type    = "A"
    name    = "echo"
    value   = "${aws_instance.echo_web.public_ip}"
    ttl     = "60"
}

resource "null_resource" "echo-web" {
    connection {
        user = "ubuntu"
        host = "${aws_instance.echo_web.public_ip}"
    }

    provisioner "local-exec" {
        command = "ansible-playbook ansible/web.yml -i ansible/hosts/echo -e 'ansible_ssh_user=ubuntu' --vault-password-file ~/.ansible/passwd"
    }
}