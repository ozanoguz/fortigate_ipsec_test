# --- VPC and Internet Gateway ---

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Main_VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main_IGW"
  }
}



# --- Security Group for All VMs (Open to Internet) ---

resource "aws_security_group" "all_vms_sg" {
  name        = "All_VMs_Open_SG"
  description = "Allow all inbound traffic for testing"
  vpc_id      = aws_vpc.main.id

  # Ingress: Allow all protocols from any IP (0.0.0.0/0)
  ingress {
    description = "Allow all inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.security_group_ingress_cidrs
  }


  # Egress: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.security_group_egress_cidrs
  }

  tags = {
    Name = "All_VMs_Security_Group"
  }
}

# --- Subnets and Route Tables ---

resource "aws_subnet" "subnets" {
  for_each                = local.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch


  tags = {
    Name = each.key
  }
}

resource "aws_route_table" "route_tables" {
  for_each = local.subnets
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${each.key}_RT"
  }
}

resource "aws_route" "default_internet_route" {
  for_each               = aws_route_table.route_tables
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "subnet_associations" {
  for_each       = aws_subnet.subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_tables[each.key].id
}

# --- FortiGate-specific Route Updates ---
# CLIENT_SUBNET routes traffic for SERVER_SUBNET through FortiGateDUT1 ENI3
# SERVER_SUBNET routes traffic for CLIENT_SUBNET through FortiGateDUT2 ENI3

# Route for CLIENT_SUBNET_RT
resource "aws_route" "client_to_server_via_fgt1" {
  route_table_id         = aws_route_table.route_tables["CLIENT_SUBNET"].id
  destination_cidr_block = local.subnets["SERVER_SUBNET"].cidr
  # This uses the private IP of FGT1's ENI3 as the Next Hop
  # NOTE: AWS requires using the Network Interface ID for an EC2/ENI next-hop
  network_interface_id = aws_network_interface.fgt1_eni3.id
  # We must ensure the EC2 instance is created before we reference the ENI in a route.
  depends_on = [aws_instance.fortigate_dut1]
}

# Route for SERVER_SUBNET_RT
resource "aws_route" "server_to_client_via_fgt2" {
  route_table_id         = aws_route_table.route_tables["SERVER_SUBNET"].id
  destination_cidr_block = local.subnets["CLIENT_SUBNET"].cidr
  # This uses the private IP of FGT2's ENI3 as the Next Hop
  # NOTE: AWS requires using the Network Interface ID for an EC2/ENI next-hop
  network_interface_id = aws_network_interface.fgt2_eni3.id
  depends_on           = [aws_instance.fortigate_dut2]
}