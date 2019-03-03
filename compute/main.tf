data "aws_ami" "centos" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_key_pair" "aws_key_pair_devops" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "aws_instance_k8s_minion" {
  ami                    = "${data.aws_ami.centos.id}"
  instance_type          = "t2.medium"
  count                  = 2
  subnet_id              = "${var.aws_subnet_subnet_01_devops_id}"
  vpc_security_group_ids = ["${var.aws_security_group_aws_security_group_devops_id}"]

  root_block_device = {
    volume_size           = "10"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name   = "k8s-minion"
    Server = "k8s-minion${count.index +1}"
    Group  = "DevOps"
  }

  key_name = "${aws_key_pair.aws_key_pair_devops.id}"

  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u centos --private-key ~/.ssh/id_rsa -i '${self.public_ip},' ./ansible/k8s_minion_main.yml"
  }

  depends_on = ["aws_instance.aws_instance_k8s_master"]
}

resource "aws_instance" "aws_instance_k8s_master" {
  ami                    = "${data.aws_ami.centos.id}"
  instance_type          = "t2.medium"
  count                  = 1
  subnet_id              = "${var.aws_subnet_subnet_01_devops_id}"
  vpc_security_group_ids = ["${var.aws_security_group_aws_security_group_devops_id}"]

  root_block_device = {
    volume_size           = "10"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name   = "k8s_master"
    Server = "k8s_master${count.index +1}"
    Group  = "DevOps"
  }

  key_name = "${aws_key_pair.aws_key_pair_devops.id}"

  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u centos --private-key ~/.ssh/id_rsa -i '${aws_instance.aws_instance_k8s_master.public_ip},' ./ansible/k8s_master_main.yml"
  }
}
