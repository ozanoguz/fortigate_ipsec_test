# Fortinet IPsec Lab - AWS Infrastructure

This repository contains Terraform code for deploying a complete Fortinet IPsec testing lab environment on AWS. The lab includes two FortiGate appliances configured with IPsec VPN tunnels and multiple Ubuntu-based iPerf test instances for network performance testing.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
  - [Terraform Deployment](#terraform-deployment)
  - [CloudFormation Deployment](#cloudformation-deployment)
- [Configuration](#configuration)
- [Accessing Resources](#accessing-resources)
- [Testing the IPsec Tunnel](#testing-the-ipsec-tunnel)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Cost Estimation](#cost-estimation)

## 🎯 Overview

This lab environment provides a complete IPsec VPN testing setup with:

- **2x FortiGate DUT (Device Under Test)** instances with pre-configured IPsec VPN tunnels
- **9x Ubuntu iPerf instances** for network performance testing
- **Multi-subnet VPC** architecture with custom routing
- **Automated bootstrap configuration** for all instances

The FortiGate appliances are configured with:
- 8 IPsec Phase 1 tunnels aggregated into a single logical interface
- Network overlay mode for enhanced performance
- Static routes and firewall policies
- CPU affinity settings for optimal packet processing

## 🏗️ Architecture

### Network Topology

<img src=https://github.com/ozanoguz/fortigate_ipsec_test/blob/main/aws/topology/AWS_IPSEC_Lab.png width="600"/>

### IPsec Tunnel Configuration

- **Phase 1**: 8 tunnels between FGT1 and FGT2 on the shared subnet (172.16.1.0/24)
- **Phase 2**: Traffic from Client subnet (172.16.2.0/24) to Server subnet (172.16.3.0/24)
- **Aggregation**: All tunnels aggregated using L4 algorithm
- **Encryption**: AES128GCM with SHA1 PRF

### Routing

- **Client → Server**: Routes via FGT1 ENI3 (172.16.2.100)
- **Server → Client**: Routes via FGT2 ENI3 (172.16.3.101)
- **Default routes**: All subnets route 0.0.0.0/0 via Internet Gateway

## 📦 Prerequisites

### AWS Account Requirements

- Active AWS account with appropriate permissions
- EC2 service quotas sufficient for:
  - 2x `c7g.4xlarge` instances (FortiGate)
  - 9x `c6in.4xlarge` instances (Ubuntu)
- VPC and networking permissions
- Ability to create Elastic IPs (5 EIPs per region limit)

### Software Requirements

**For Terraform:**
- Terraform >= 1.6.0
- AWS CLI configured with credentials
- Terraform AWS provider >= 5.0

**For CloudFormation:**
- AWS CLI configured with credentials
- AWS Console access (optional)

### AWS Credentials

Configure AWS credentials using one of these methods:

```bash
# Option 1: AWS CLI configure
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=your_region

# Option 3: AWS Profile
export AWS_PROFILE=your_profile_name
```

### Required AWS Resources

- **EC2 Key Pair**: Create a key pair in your target region for SSH access
  ```bash
  aws ec2 create-key-pair --key-name OO_EUCENTRAL_KEY --query 'KeyMaterial' --output text > your_key.pem
  chmod 400 your_key.pem
  ```

## 🚀 Deployment Options

### Terraform Deployment

#### Step 1: Initialize Terraform

```bash
cd /path/to/ipsec-template-test
terraform init
```

#### Step 2: Review Configuration

Edit `terraform.tfvars` to customize settings:

```hcl
aws_region        = "YOUR-REGION"
availability_zone = "YOUR-AVAILABILITY-ZONE"
ssh_key_name      = "YOUR-KEY-PAIR-NAME"

# Optional: Override defaults
# fortigate_ami_id = "ami-xxxxxxxxx"
# ubuntu_instance_type = "c6in.4xlarge"
```

#### Step 3: Plan Deployment

```bash
terraform plan
```

Review the planned changes to ensure they match your expectations.

#### Step 4: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

#### Step 5: Retrieve Outputs

After deployment completes, retrieve important information:

```bash
terraform output
```

Key outputs:
- `vpc_id`: VPC identifier
- `fortigate_dut1_mgmt_ip`: FortiGate DUT1 management EIP
- `fortigate_dut2_mgmt_ip`: FortiGate DUT2 management EIP
- `iperf_public_ips`: Map of all iPerf instance public IPs

### CloudFormation Deployment

#### Step 1: Get Ubuntu AMI ID

First, retrieve the latest Ubuntu 22.04 AMI ID for your region:

```bash
# Replace eu-central-1 with your target region
aws ec2 describe-images \
  --region eu-central-1 \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text
```

Save the AMI ID (e.g., `ami-0a1b2c3d4e5f6g7h8`).

#### Step 2: Create Stack via AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name fortinet-ipsec-lab \
  --template-body file://cloudformation.yaml \
  --parameters \
    ParameterKey=UbuntuAmiId,ParameterValue=ami-xxxxxxxxx \
    ParameterKey=KeyName,ParameterValue=OO_EUCENTRAL_KEY \
    ParameterKey=AvailabilityZone,ParameterValue=eu-central-1a \
  --capabilities CAPABILITY_IAM \
  --region eu-central-1
```

#### Step 3: Monitor Stack Creation

```bash
aws cloudformation describe-stacks \
  --stack-name fortinet-ipsec-lab \
  --query 'Stacks[0].StackStatus' \
  --output text
```

Wait for status to become `CREATE_COMPLETE` (typically 15-20 minutes).

#### Step 4: Retrieve Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name fortinet-ipsec-lab \
  --query 'Stacks[0].Outputs'
```

#### Alternative: Deploy via AWS Console

1. Navigate to CloudFormation in AWS Console
2. Click "Create stack" → "With new resources"
3. Upload `cloudformation.yaml`
4. Fill in required parameters:
   - `UbuntuAmiId`: AMI ID from Step 1
   - `KeyName`: Your EC2 key pair name
5. Review and create stack

## ⚙️ Configuration

### Default Configuration Values

| Component | Default Value |
|-----------|--------------|
| VPC CIDR | 172.16.0.0/16 |
| Management Subnet | 172.16.0.0/24 |
| Shared Subnet | 172.16.1.0/24 |
| Client Subnet | 172.16.2.0/24 |
| Server Subnet | 172.16.3.0/24 |
| FortiGate Instance Type | c7g.4xlarge |
| Ubuntu Instance Type | c6in.4xlarge |
| FortiGate Root Volume | 8 GiB (gp3) |
| FortiGate Data Volume | 30 GiB (gp3) |

### FortiGate Private IPs

**FortiGate DUT1:**
- Management: 172.16.0.100
- Shared: 172.16.1.100
- Client: 172.16.2.100

**FortiGate DUT2:**
- Management: 172.16.0.101
- Shared: 172.16.1.101
- Server: 172.16.3.101

### iPerf Instance IPs

**Client Subnet (172.16.2.0/24):**
- IPERF_CLIENT1: 172.16.2.10
- IPERF_CLIENT2: 172.16.2.11
- IPERF_CLIENT3: 172.16.2.12

**Server Subnet (172.16.3.0/24):**
- IPERF_SERVER1: 172.16.3.10
- IPERF_SERVER2: 172.16.3.11
- IPERF_SERVER3: 172.16.3.12

**Shared Subnet (172.16.1.0/24):**
- IPERF_SHARED1: 172.16.1.10
- IPERF_SHARED2: 172.16.1.11
- IPERF_SHARED3: 172.16.1.12

### FortiGate Bootstrap Configuration

The FortiGate instances are automatically configured with:

- **Admin credentials**: `admin` / `fortinet`
- **Hostnames**: FortiGateDUT1, FortiGateDUT2
- **Timezone**: Europe/Istanbul
- **IPsec Configuration**: 8 aggregated tunnels
- **Firewall Policies**: Allow traffic between Client and Server subnets
- **Static Routes**: Routes to remote subnets via IPsec aggregate

Configuration files:
- `fortigatedut1.conf`: FortiGate DUT1 configuration
- `fortigatedut2.conf`: FortiGate DUT2 configuration

### Ubuntu Instance Packages

All Ubuntu instances automatically install:
- `telnet`
- `traceroute`
- `iperf3`
- `net-tools` (includes `ifconfig`)

## 🔐 Accessing Resources

### Accessing FortiGate Management Interface

```bash
# Get management EIP from outputs
FGT1_IP=$(terraform output -raw fortigate_dut1_mgmt_ip)
FGT2_IP=$(terraform output -raw fortigate_dut2_mgmt_ip)

# SSH to FortiGate (if SSH access is enabled)
ssh admin@$FGT1_IP

# Or access via HTTPS
# https://$FGT1_IP
# Username: admin
# Password: fortinet
```

### Accessing Ubuntu iPerf Instances

```bash
# Get instance IPs from outputs
terraform output iperf_public_ips

# SSH to an instance
ssh -i OO_EUCENTRAL_KEY.pem ubuntu@<PUBLIC_IP>
```

### Security Group

The default security group allows all traffic (0.0.0.0/0) for testing purposes. **Modify this for production use!**

## 🧪 Testing the IPsec Tunnel

### Verify IPsec Tunnel Status

1. **SSH to FortiGate DUT1:**
   ```bash
   ssh admin@<FGT1_MGMT_IP>
   ```

2. **Check IPsec tunnel status:**
   ```bash
   get vpn ipsec tunnel summary
   diagnose vpn ike gateway list
   diagnose vpn tunnel list
   ```

3. **Verify aggregate interface:**
   ```bash
   get system interface IPSEC_AGGREGATE
   ```

### Run iPerf Tests

1. **Start iPerf server on Server subnet:**
   ```bash
   ssh ubuntu@<IPERF_SERVER1_IP>
   iperf3 -s -p 5201
   ```

2. **Run iPerf client from Client subnet:**
   ```bash
   ssh ubuntu@<IPERF_CLIENT1_IP>
   iperf3 -c 172.16.3.10 -p 5201 -t 60
   ```

3. **Test with multiple parallel streams:**
   ```bash
   iperf3 -c 172.16.3.10 -p 5201 -P 8 -t 60
   ```

### Verify Traffic Flow

1. **Check FortiGate traffic logs:**
   ```bash
   # On FortiGate
   execute log filter category 0
   execute log display
   ```

2. **Monitor IPsec tunnel statistics:**
   ```bash
   diagnose vpn tunnel list
   diagnose ipsec aggregate status
   ```

3. **Test connectivity:**
   ```bash
   # From Client subnet
   ping 172.16.3.10
   traceroute 172.16.3.10
   ```

## 🧹 Cleanup

### Terraform Cleanup

```bash
# Destroy all resources
terraform destroy

# Confirm with 'yes'
```

**Note:** This will delete all resources including:
- EC2 instances
- VPC and networking components
- Elastic IPs
- Security groups

### CloudFormation Cleanup

```bash
# Delete the stack
aws cloudformation delete-stack --stack-name fortinet-ipsec-lab

# Monitor deletion
aws cloudformation describe-stacks \
  --stack-name fortinet-ipsec-lab \
  --query 'Stacks[0].StackStatus'
```

Or delete via AWS Console:
1. Navigate to CloudFormation
2. Select stack `fortinet-ipsec-lab`
3. Click "Delete"

## 🔧 Troubleshooting

### FortiGate Instances Not Accessible

**Issue:** Cannot SSH or access HTTPS to FortiGate management interface.

**Solutions:**
1. Verify security group allows inbound traffic on ports 22 (SSH) and 443 (HTTPS)
2. Check Elastic IP association:
   ```bash
   aws ec2 describe-addresses --filters "Name=tag:Name,Values=FortiGateDUT1-ENI1-EIP"
   ```
3. Verify instance is running:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Name,Values=FortiGateDUT1"
   ```

### IPsec Tunnels Not Establishing

**Issue:** IPsec tunnels show as down.

**Solutions:**
1. Verify FortiGate instances can reach each other on shared subnet:
   ```bash
   # On FGT1
   execute ping 172.16.1.101
   ```
2. Check IPsec configuration:
   ```bash
   show vpn ipsec phase1-interface
   show vpn ipsec phase2-interface
   ```
3. Review IPsec logs:
   ```bash
   diagnose vpn ike log-filter dst-addr4 172.16.1.101
   diagnose debug application ike -1
   diagnose debug enable
   ```

### Ubuntu Instances Not Installing Packages

**Issue:** Packages not installed after instance launch.

**Solutions:**
1. Check user data execution:
   ```bash
   ssh ubuntu@<INSTANCE_IP>
   sudo cat /var/log/cloud-init-output.log
   ```
2. Manually install packages:
   ```bash
   sudo apt-get update
   sudo apt-get install -y telnet traceroute iperf3 net-tools
   ```

### Route Issues

**Issue:** Traffic not routing through FortiGate.

**Solutions:**
1. Verify route tables:
   ```bash
   aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<VPC_ID>"
   ```
2. Check FortiGate routing:
   ```bash
   # On FortiGate
   get router static
   diagnose ip route list
   ```
3. Verify source/destination check is disabled on ENIs:
   ```bash
   aws ec2 describe-network-interfaces --filters "Name=tag:Name,Values=FortiGateDUT1-ENI3"
   ```

### CloudFormation Stack Creation Fails

**Issue:** Stack creation fails with parameter errors.

**Solutions:**
1. Verify Ubuntu AMI ID is correct for your region
2. Ensure key pair exists in target region
3. Check IAM permissions for EC2, VPC, and CloudFormation
4. Review CloudFormation events:
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name fortinet-ipsec-lab \
     --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
   ```

## 💰 Cost Estimation

### Instance Costs (Approximate, eu-central-1)

| Instance Type | Quantity | On-Demand/Hour | Monthly (730h) |
|--------------|----------|----------------|--------------|
| c7g.4xlarge (FortiGate) | 2 | ~$0.60 | ~$876 |
| c6in.4xlarge (Ubuntu) | 9 | ~$0.80 | ~$5,256 |
| **Total Compute** | **11** | **~$8.40/hr** | **~$6,132** |

### Additional Costs

- **EIPs**: 11 EIPs (free when attached, ~$0.005/hr if unattached)
- **Data Transfer**: Varies based on testing traffic
- **Storage**: 
  - FortiGate root volumes: 2 × 8 GiB × $0.10/GiB = $1.60/month
  - FortiGate data volumes: 2 × 30 GiB × $0.10/GiB = $6.00/month
  - Ubuntu root volumes: 9 × 8 GiB × $0.10/GiB = $7.20/month

### Cost Optimization Tips

1. **Use Spot Instances**: Can reduce costs by 50-90% (not recommended for FortiGate)
2. **Stop Instances**: Stop when not in use to save compute costs
3. **Use Smaller Instance Types**: For testing, consider smaller instance types
4. **Clean Up Promptly**: Destroy resources when not in use

**Estimated Total Monthly Cost**: ~$6,150-6,200 (for 24/7 operation)

## 📝 File Structure

```
.
├── cloudformation.yaml          # CloudFormation template
├── datasources.tf               # Terraform data sources (Ubuntu AMI lookup)
├── fortigate.tf                 # FortiGate instances and ENIs
├── fortigatedut1.conf           # FortiGate DUT1 bootstrap config
├── fortigatedut2.conf           # FortiGate DUT2 bootstrap config
├── locals.tf                    # Local variables and computed values
├── network.tf                   # VPC, subnets, routes, security groups
├── outputs.tf                  # Terraform outputs
├── provider.tf                  # AWS provider configuration
├── serverfarm.tf                # Ubuntu iPerf instances
├── terraform.tfvars            # Terraform variable overrides
├── variables.tf                 # Terraform variable definitions
└── ipseclab.md                 # This file
```

## 📚 Additional Resources

- [FortiGate Documentation](https://docs.fortinet.com/)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)

## ⚠️ Important Notes

1. **Security**: The default security group allows all traffic (0.0.0.0/0). This is for lab/testing purposes only. Modify security groups for production use.

2. **Costs**: This lab uses large instance types and can be expensive. Monitor costs and clean up resources when not in use.

3. **Region**: Ensure all resources are deployed in the same region and availability zone.

4. **Key Pair**: You must have the private key file for the specified key pair to access instances.

5. **FortiGate License**: Ensure your FortiGate AMI includes appropriate licensing for your use case.

6. **AMI Updates**: Ubuntu AMI IDs change frequently. Always use the latest AMI ID for your region.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Please feel free to submit a pull request.

## 📄 License

This project is provided as-is for educational and testing purposes.

---

**Last Updated**: 2024
**Maintained By**: Network Engineering Team


