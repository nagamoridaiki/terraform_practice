# ECR リポジトリの定義
resource "aws_ecr_repository" "example" {
  name = "eventer-node"
}
# ECR ライフサイクルポリシーの定義
resource "aws_ecr_lifecycle_policy" "example_repo" {
  repository = aws_ecr_repository.example.name
  policy     = <<EOF
    {
        "rules": [
            {
                "rulePriority": 1,
                "description": "Expire last 30 release tagged images",
                "selection": {
                    "tagStatus": "tagged",
                    "tagPrefixList": ["release"],
                    "countType": "imageCountMoreThan",
                    "countNumber": 30
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }
EOF
}