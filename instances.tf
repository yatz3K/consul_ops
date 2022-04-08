
resource "aws_instance" "consul_server" {

  ami           = var.ami
  instance_type = "t2.micro"
  count = 3
  key_name      = aws_key_pair.opsschool_consul_key.key_name
  subnet_id                   = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.opsschool_consul.id]
  #user_data            = "./run_server.sh" 

  tags = {
    Name = "consul-server-${count.index}"
    consul_server = "true"
  }

}

resource "aws_instance" "consul_agent" {

  ami           = var.ami
  instance_type = "t2.micro"
  key_name      = aws_key_pair.opsschool_consul_key.key_name
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  vpc_security_group_ids = [aws_security_group.opsschool_consul.id]
  user_data            = "./run_agent.sh"  

  tags = {
    Name = "consul-agent-nginx"
  }

}

output "server" {
  value = aws_instance.consul_server.public_ip
}

output "agent" {
  value = aws_instance.consul_agent.public_ip
}
 
resource "aws_security_group" "opsschool_consul" {
  name        = "opsschool-consul"
  vpc_id = aws_vpc.consul_vpc.id

}

resource "aws_security_group_rule" "allow_ssh_single_ip" {
    description = "allow ssh only from my IP"
    from_port = 22
    protocol = "tcp"
    security_group_id = aws_security_group.opsschool_consul.id
    to_port = 22
    type = "ingress"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
}

resource "aws_security_group_rule" "allow_consul_ui_single_ip" {
    description = "allow consul UI only from my IP"
    from_port = 8500
    protocol = "tcp"
    security_group_id = aws_security_group.opsschool_consul.id
    to_port = 8500
    type = "ingress"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  
}

resource "aws_security_group_rule" "all_outbound" {
    description = "allow outbound traffic to anywhere"
    from_port = 0
    protocol = "-1"
    security_group_id = aws_security_group.opsschool_consul.id
    to_port = 0
    type = "egress"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "all_inside_security_group" {
  description = "Allow all inside security group"
  from_port = 0
  to_port = 0
  protocol = "-1"
  self = true
}
