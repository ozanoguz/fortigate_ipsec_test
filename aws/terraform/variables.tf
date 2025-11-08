# --- Global AWS Configuration ---

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-central-1"
}

variable "availability_zone" {
  description = "Default Availability Zone for regional resources."
  type        = string
  default     = "eu-central-1a"
}

variable "aws_profile" {
  description = "Optional named AWS CLI profile to use for authentication."
  type        = string
  default     = null
}

variable "access_key" {
  description = "Optional AWS access key override. Prefer environment variables or profiles."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_key" {
  description = "Optional AWS secret key override. Prefer environment variables or profiles."
  type        = string
  default     = null
  sensitive   = true
}

variable "default_tags" {
  description = "Default tags applied to all supported AWS resources."
  type        = map(string)
  default = {
    Environment = "lab"
    Project     = "fortinet-ipsec"
  }
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for the primary VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "subnets" {
  description = "Subnet definitions keyed by logical name."
  type = map(object({
    cidr                    = string
    map_public_ip_on_launch = bool
  }))
  default = {
    FORTIGATE_MANAGEMENT_SUBNET = {
      cidr                    = "172.16.0.0/24"
      map_public_ip_on_launch = true
    }
    SHARED_SUBNET = {
      cidr                    = "172.16.1.0/24"
      map_public_ip_on_launch = true
    }
    CLIENT_SUBNET = {
      cidr                    = "172.16.2.0/24"
      map_public_ip_on_launch = true
    }
    SERVER_SUBNET = {
      cidr                    = "172.16.3.0/24"
      map_public_ip_on_launch = true
    }
  }

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet definition is required."
  }
}

variable "security_group_ingress_cidrs" {
  description = "CIDR blocks allowed inbound to the lab security group."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.security_group_ingress_cidrs) > 0
    error_message = "Provide at least one CIDR block for security group ingress."
  }
}

variable "security_group_egress_cidrs" {
  description = "CIDR blocks allowed outbound from the lab security group."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.security_group_egress_cidrs) > 0
    error_message = "Provide at least one CIDR block for security group egress."
  }
}

# --- FortiGate Instances ---

variable "ssh_key_name" {
  description = "Existing EC2 key pair used for SSH access to instances."
  type        = string
  default     = "OO_EUCENTRAL_KEY"

  validation {
    condition     = length(trimspace(var.ssh_key_name)) > 0
    error_message = "ssh_key_name cannot be empty."
  }
}

variable "fortigate_ami_id" {
  description = "FortiGate AMI identifier."
  type        = string
  default     = "ami-09cb7b775a32245f9"
}

variable "fortigate_instance_type" {
  description = "Instance type for FortiGate DUT appliances."
  type        = string
  default     = "c7g.4xlarge"
}

variable "fortigate_disable_api_termination" {
  description = "Protect FortiGate instances from accidental termination."
  type        = bool
  default     = true
}

variable "fortigate_root_volume_size" {
  description = "Size (GiB) of the FortiGate root volume."
  type        = number
  default     = 8
}

variable "fortigate_data_volume_size" {
  description = "Size (GiB) of the FortiGate secondary data volume."
  type        = number
  default     = 30
}

variable "fortigate_dut1_private_ips" {
  description = "Static private IPs for FortiGate DUT1 interfaces."
  type = object({
    management = string
    shared     = string
    client     = string
  })
  default = {
    management = "172.16.0.100"
    shared     = "172.16.1.100"
    client     = "172.16.2.100"
  }
}

variable "fortigate_dut2_private_ips" {
  description = "Static private IPs for FortiGate DUT2 interfaces."
  type = object({
    management = string
    shared     = string
    server     = string
  })
  default = {
    management = "172.16.0.101"
    shared     = "172.16.1.101"
    server     = "172.16.3.101"
  }
}

variable "fortigate_configs" {
  description = "Path to configuration files for each FortiGate instance."
  type        = map(string)
  default = {
    fortigate_dut1 = "fortigatedut1.conf"
    fortigate_dut2 = "fortigatedut2.conf"
  }

  validation {
    condition = alltrue([
      contains(keys(var.fortigate_configs), "fortigate_dut1"),
      contains(keys(var.fortigate_configs), "fortigate_dut2")
    ])
    error_message = "fortigate_configs must include keys for fortigate_dut1 and fortigate_dut2."
  }
}

# --- Ubuntu iPerf Farm ---

variable "ubuntu_instance_type" {
  description = "Instance type for Ubuntu iPerf nodes."
  type        = string
  default     = "c6in.4xlarge"
}

variable "ubuntu_associate_public_ip" {
  description = "Whether Ubuntu instances receive a public IP address."
  type        = bool
  default     = true
}

variable "ubuntu_packages" {
  description = "Packages installed on Ubuntu instances via cloud-init."
  type        = list(string)
  default     = ["telnet", "traceroute", "iperf3", "net-tools"]

  validation {
    condition     = length(var.ubuntu_packages) > 0
    error_message = "Specify at least one Ubuntu package to install."
  }
}

variable "ubuntu_ami_owner" {
  description = "Account ID owning the Ubuntu AMI."
  type        = string
  default     = "099720109477"
}

variable "ubuntu_ami_name_pattern" {
  description = "Name pattern used to locate the Ubuntu AMI."
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ubuntu_ami_architecture" {
  description = "Architecture of the Ubuntu AMI to select."
  type        = string
  default     = "x86_64"
}

variable "ubuntu_ami_virtualization_type" {
  description = "Virtualization type of the Ubuntu AMI to select."
  type        = string
  default     = "hvm"
}

variable "iperf_vms" {
  description = "Map of iPerf VM definitions keyed by instance name."
  type = map(object({
    subnet_key = string
    private_ip = string
  }))
  default = {
    IPERF_CLIENT1 = { subnet_key = "CLIENT_SUBNET", private_ip = "172.16.2.10" }
    IPERF_CLIENT2 = { subnet_key = "CLIENT_SUBNET", private_ip = "172.16.2.11" }
    IPERF_CLIENT3 = { subnet_key = "CLIENT_SUBNET", private_ip = "172.16.2.12" }
    IPERF_SERVER1 = { subnet_key = "SERVER_SUBNET", private_ip = "172.16.3.10" }
    IPERF_SERVER2 = { subnet_key = "SERVER_SUBNET", private_ip = "172.16.3.11" }
    IPERF_SERVER3 = { subnet_key = "SERVER_SUBNET", private_ip = "172.16.3.12" }
    IPERF_SHARED1 = { subnet_key = "SHARED_SUBNET", private_ip = "172.16.1.10" }
    IPERF_SHARED2 = { subnet_key = "SHARED_SUBNET", private_ip = "172.16.1.11" }
    IPERF_SHARED3 = { subnet_key = "SHARED_SUBNET", private_ip = "172.16.1.12" }
  }

  validation {
    condition     = length(var.iperf_vms) > 0
    error_message = "At least one iPerf VM definition is required."
  }
}