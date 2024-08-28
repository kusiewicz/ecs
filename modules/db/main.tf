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
  allocated_storage       = 20
  db_name                 = "appDB"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  username                = "adminuser"
  password                = var.db_password
  storage_encrypted       = true
  db_subnet_group_name    = aws_db_subnet_group.app.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  multi_az                = true
  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  depends_on = [aws_db_subnet_group.app]
}

// REPLICA
# resource "aws_db_instance" "replica" {
#   allocated_storage       = 20
#   db_name                 = "appDB-replica"
#   engine                  = "postgres"
#   instance_class          = "db.t3.micro"
#   username                = "adminuser"
#   password                = var.db_password
#   storage_encrypted       = true
#   db_subnet_group_name    = aws_db_subnet_group.app.name
#   vpc_security_group_ids  = [aws_security_group.db.id]
#   multi_az                = true
#   replicate_source_db     = aws_db_instance.app.id
#   backup_retention_period = 7
#   backup_window           = "03:00-04:00"

#   depends_on = [aws_db_subnet_group.app]
# }

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

resource "aws_db_snapshot" "db_snapshot" {
  db_instance_identifier = aws_db_instance.app.identifier
  db_snapshot_identifier = "db-snapshot"
}


resource "aws_elasticache_subnet_group" "app" {
  name       = "db-elasticache-subnet-group"
  subnet_ids = [var.db_first_subnet_group_id, var.db_second_subnet_group_id]
}


resource "aws_security_group" "elasticache" {
  name        = "elasticache"
  description = "Security group for ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
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


resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "app-redis-replication-group"
  node_type                  = "cache.t2.micro"
  description                = "Redis Replication Group"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.app.name
  security_group_ids         = [aws_security_group.elasticache.id]
  engine                     = "redis"
  engine_version             = "6.x"
  parameter_group_name       = "default.redis6.x"

  tags = {
    Name = "app-redis-replication-group"
  }
}
