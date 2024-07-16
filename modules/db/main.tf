resource "aws_db_subnet_group" "app" {
  name       = "app-db-subnet-group"
  subnet_ids = [var.db_first_subnet_group_id, var.db_second_subnet_group_id]
}

resource "aws_security_group" "db" {
  name        = "db"
  description = "Security group for DB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id, aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "app" {
  allocated_storage      = 20
  db_name                = "appDB"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  username               = "adminuser"
  password               = var.db_password
  storage_encrypted      = true
  db_subnet_group_name   = "app-db-subnet-group"
  vpc_security_group_ids = [aws_security_group.db.id]

  depends_on = [aws_db_subnet_group.app]
}

resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Security group for bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "bastion" {
  key_name   = "app_ssh_key_pair"
  public_key = file("~/.ssh/tf-key.pub")
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_instance" "bastion" {
  ami                         = var.bastion_ami
  instance_type               = "t2.micro"
  subnet_id                   = var.bastion_subnet
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]

  provisioner "remote-exec" {
    inline = [
      "echo '${tls_private_key.bastion.private_key_pem}' > ~/.ssh/tf-key",
      "chmod 0600 ~/.ssh/tf-key"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file("~/.ssh/tf-key")
      timeout     = "2m"
    }
  }

  tags = {
    Name = "bastion"
  }
}

