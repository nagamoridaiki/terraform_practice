# RDS
resource "aws_db_subnet_group" "eventer-db" {
  name       = "eventer-db"
  subnet_ids = ["${aws_subnet.private_a.id}", "${aws_subnet.private_c.id}"]
  tags = {
    Name = "eventer-db"
  }
}

resource "aws_db_instance" "eventer-db" {
  identifier             = "eventer-db"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  name                   = "eventer-db"
  username               = "root"
  password               = "password"
  option_group_name      = aws_db_option_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = ["${aws_security_group.db.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.eventer-db.name}"
  skip_final_snapshot    = true
  publicly_accessible    = true
}

resource "aws_security_group" "db" {
  name        = "db-security-group"
  description = "Allow DB inbound traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.allow.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "db-security-group"
  }
}

resource "aws_security_group" "allow" {
  name        = "allow"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.example.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}


resource "aws_db_option_group" "main" {
  name = "db-option-group"
  # DBインスタンスに使用するエンジンを設定する。
  #  - MySQLを設定。
  engine_name = "mysql"
  # エンジンのメジャーバージョンを設定する。
  #  - MySQL8.0のため、「8.0」を設定する。
  major_engine_version = "5.7"
}

resource "aws_db_parameter_group" "main" {
  name   = "db-parameter-group"
  family = "mysql5.7"
}

