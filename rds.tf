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
  engine_version         = "5.7.30"
  instance_class         = "db.t2.micro"
  name                   = "eventer-db"
  username               = "root"
  password               = "password"
  option_group_name      = aws_db_option_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [module.db-security-group.security_group_id]
  db_subnet_group_name   = "${aws_db_subnet_group.eventer-db.name}"
  skip_final_snapshot    = true
  publicly_accessible    = true
}

module "db-security-group" {
  source      = "./security_group"
  name        = "db-security-group"
  vpc_id      = aws_vpc.example.id
  port        = 3306
  cidr_blocks = ["0.0.0.0/0"]
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
  name = "db-parameter-group"
  # DBパラメータグループが適用されるファミリーを設定する。
  #  - 今回は、MySQL8.0を使用する。
  family = "mysql5.7"
  # スロークエリログを有効にする。
  parameter {
    name  = "slow_query_log"
    value = 1
  }
  # 一般クエリログを有効にする。
  parameter {
    name  = "general_log"
    value = 1
  }
  # スロークエリと判断する秒数を設定する。
  parameter {
    name  = "long_query_time"
    value = 5
  }
}

