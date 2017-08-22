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

resource "aws_key_pair" "auth" {
  key_name   = "echo"
  public_key = "${file("~/.ssh/echo.pub")}"
}

resource "aws_instance" "echo_web" {
    ami           = "ami-82be18ed"
    instance_type = "t2.nano"
    key_name      = "echo-key"
    vpc_security_group_ids = ["${aws_security_group.echo_web_sg.id}"]
    key_name = "${aws_key_pair.auth.id}"

    connection {
        user        = "ec2-user"
    }

    provisioner "local-exec" {
        command = "echo 'waiting for the instance to be up before attempting to ssh into it' && sleep 30s"
    }

    provisioner "remote-exec" {
        inline =  [
            "mkdir /home/ec2-user/.aws"
        ]
    }

    provisioner "file" {
        source      = "~/.dynamodb/*"
        destination = "/home/ec2-user/.aws"
    }

    provisioner "local-exec" {
        # Creates a hosts file with the name of the droplet to be a tiny bit more organized i guess
        command = "echo '[echo-web]\n${aws_instance.echo_web.public_ip} ansible_ssh_user=ec2-user' > ansible/hosts/echo"
    }

    provisioner "local-exec" {
        # i know this will add the variables echo_ip and redis_ip to both ansible hosts but idk how to do it otherwise
        # i'd only need this variable on one of the iterations of the loop and i'd rather not have if/else
        # TODO: find a better solution
        command = "ansible-playbook ansible/web.yml -i ansible/hosts/echo -e 'ansible_ssh_user=ec2-user' --vault-password-file ~/.ansible/passwd"
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