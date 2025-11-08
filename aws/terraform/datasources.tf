# --- Data Source for Ubuntu AMI ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ubuntu_ami_owner]

  filter {
    name   = "name"
    values = [var.ubuntu_ami_name_pattern]
  }

  filter {
    name   = "virtualization-type"
    values = [var.ubuntu_ami_virtualization_type]
  }

  filter {
    name   = "architecture"
    values = [var.ubuntu_ami_architecture]
  }
}