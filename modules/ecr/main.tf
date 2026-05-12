resource "aws_ecr_repository" "ollama" {
  name                 = "${var.project_name}/ollama"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ollama"
  }
}

resource "aws_ecr_lifecycle_policy" "ollama" {
  repository = aws_ecr_repository.ollama.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
