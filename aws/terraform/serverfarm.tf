# --- User Data for Ubuntu VMs (Bootstrap) ---
# Installs packages defined in var.ubuntu_packages
data "cloudinit_config" "ubuntu_bootstrap" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "install.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOF
        #!/bin/bash
        set -xe
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y ${local.ubuntu_package_install}
    EOF
  }
}


resource "aws_instance" "iperf_vms" {
  for_each                    = local.iperf_vms
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ubuntu_instance_type
  key_name                    = var.ssh_key_name
  availability_zone           = var.availability_zone
  subnet_id                   = aws_subnet.subnets[each.value.subnet_key].id
  private_ip                  = each.value.private_ip
  vpc_security_group_ids      = [aws_security_group.all_vms_sg.id]
  user_data_base64            = data.cloudinit_config.ubuntu_bootstrap.rendered
  associate_public_ip_address = var.ubuntu_associate_public_ip # Required for fixed EIP (as it enables EIP to associate to the primary ENI)

  tags = {
    Name = each.key
  }
}

# --- Elastic IP (EIP) for all Ubuntu VMs ---

resource "aws_eip" "iperf_vms_eips" {
  for_each = aws_instance.iperf_vms
  domain   = "vpc"
  tags = {
    Name = "${each.key}-EIP"
  }
}

resource "aws_eip_association" "iperf_vms_eip_assoc" {
  for_each      = aws_eip.iperf_vms_eips
  instance_id   = aws_instance.iperf_vms[each.key].id
  allocation_id = each.value.id
}