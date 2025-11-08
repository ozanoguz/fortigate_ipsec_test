# --- FortiGate ENI and EIP Definitions ---

# FortiGateDUT1 ENIs
resource "aws_eip" "fgt1_eni1_eip" {
  domain = "vpc"
  tags   = { Name = "FortiGateDUT1-ENI1-EIP" }
}
resource "aws_network_interface" "fgt1_eni1" {
  subnet_id         = aws_subnet.subnets["FORTIGATE_MANAGEMENT_SUBNET"].id
  private_ips       = [local.fortigate_dut_ips["fortigate_dut1"].management]
  security_groups   = [aws_security_group.all_vms_sg.id]
  source_dest_check = false
  tags              = { Name = "FortiGateDUT1-ENI1" }
}
resource "aws_network_interface" "fgt1_eni2" {
  subnet_id         = aws_subnet.subnets["SHARED_SUBNET"].id
  private_ips       = [local.fortigate_dut_ips["fortigate_dut1"].shared]
  security_groups   = [aws_security_group.all_vms_sg.id]
  source_dest_check = false
  tags              = { Name = "FortiGateDUT1-ENI2" }
}
resource "aws_network_interface" "fgt1_eni3" {
  subnet_id         = aws_subnet.subnets["CLIENT_SUBNET"].id
  private_ips       = [local.fortigate_dut_ips["fortigate_dut1"].client]
  security_groups   = [aws_security_group.all_vms_sg.id]
  source_dest_check = false
  tags              = { Name = "FortiGateDUT1-ENI3" }
}

# FortiGateDUT2 ENIs
resource "aws_eip" "fgt2_eni1_eip" {
  domain = "vpc"
  tags   = { Name = "FortiGateDUT2-ENI1-EIP" }
}
resource "aws_network_interface" "fgt2_eni1" {
  subnet_id         = aws_subnet.subnets["FORTIGATE_MANAGEMENT_SUBNET"].id
  private_ips       = [local.fortigate_dut_ips["fortigate_dut2"].management]
  security_groups   = [aws_security_group.all_vms_sg.id]
  source_dest_check = false
  tags              = { Name = "FortiGateDUT2-ENI1" }
}
resource "aws_network_interface" "fgt2_eni2" {
  subnet_id         = aws_subnet.subnets["SHARED_SUBNET"].id
  private_ips       = [local.fortigate_dut_ips["fortigate_dut2"].shared]
  security_groups   = [aws_security_group.all_vms_sg.id]
  source_dest_check = false
  tags              = { Name = "FortiGateDUT2-ENI2" }
}
resource "aws_network_interface" "fgt2_eni3" {
  subnet_id         = aws_subnet.subnets["SERVER_SUBNET"].id
  private_ips       = [local.fortigate_dut_ips["fortigate_dut2"].server]
  security_groups   = [aws_security_group.all_vms_sg.id]
  source_dest_check = false
  tags              = { Name = "FortiGateDUT2-ENI3" }
}

# Associate EIPs to FortiGate ENI1s
resource "aws_eip_association" "fgt1_eni1_assoc" {
  allocation_id        = aws_eip.fgt1_eni1_eip.id
  network_interface_id = aws_network_interface.fgt1_eni1.id
}
resource "aws_eip_association" "fgt2_eni1_assoc" {
  allocation_id        = aws_eip.fgt2_eni1_eip.id
  network_interface_id = aws_network_interface.fgt2_eni1.id
}


# --- FortiGate EC2 Instances Deployment ---
# NOTE: FortiGate AMI is configurable via var.fortigate_ami_id

resource "aws_instance" "fortigate_dut1" {
  ami                     = var.fortigate_ami_id
  instance_type           = var.fortigate_instance_type
  key_name                = var.ssh_key_name
  availability_zone       = var.availability_zone
  disable_api_termination = var.fortigate_disable_api_termination # Best practice for production/critical instances

  user_data = base64encode(local.fortigate_configs["fortigate_dut1"])

  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_size           = var.fortigate_data_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  root_block_device {
    volume_size           = var.fortigate_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.fgt1_eni1.id
    device_index         = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.fgt1_eni2.id
    device_index         = 1
  }
  network_interface {
    network_interface_id = aws_network_interface.fgt1_eni3.id
    device_index         = 2
  }

  tags = {
    Name = "FortiGateDUT1"
  }
}

resource "aws_instance" "fortigate_dut2" {
  ami                     = var.fortigate_ami_id
  instance_type           = var.fortigate_instance_type
  key_name                = var.ssh_key_name
  availability_zone       = var.availability_zone
  disable_api_termination = var.fortigate_disable_api_termination

  user_data = base64encode(local.fortigate_configs["fortigate_dut2"])

  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_size           = var.fortigate_data_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  root_block_device {
    volume_size           = var.fortigate_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.fgt2_eni1.id
    device_index         = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.fgt2_eni2.id
    device_index         = 1
  }
  network_interface {
    network_interface_id = aws_network_interface.fgt2_eni3.id
    device_index         = 2
  }

  tags = {
    Name = "FortiGateDUT2"
  }
}
