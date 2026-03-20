# --- Trust Policy for ECS Tasks ---
data "aws_iam_policy_document" "ecs_tasks_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# --- ECS Task Execution Role ---
# Used by the ECS agent to pull images and send logs
resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust_policy.json

}

# Attach common Amazon managed policy for execution
resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- ECS Task Role ---
# Used by the application inside the container to access other AWS services
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust_policy.json

}

# Note: In a real scenario, you'd attach specific permissions here 
# (e.g., access to S3, DynamoDB, etc.)
# resource "aws_iam_role_policy_attachment" "ecs_task_role_s3_example" { ... }
