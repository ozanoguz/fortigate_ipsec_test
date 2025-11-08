# --- Outputs (Optional but recommended) ---

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "fortigate_dut1_mgmt_ip" {
  description = "FortiGateDUT1 Management EIP (ENI1)"
  value       = aws_eip.fgt1_eni1_eip.public_ip
}

output "fortigate_dut2_mgmt_ip" {
  description = "FortiGateDUT2 Management EIP (ENI1)"
  value       = aws_eip.fgt2_eni1_eip.public_ip
}

output "all_vms_security_group_id" {
  description = "Security group protecting all lab instances."
  value       = aws_security_group.all_vms_sg.id
}

output "subnet_ids" {
  description = "Map of subnet IDs keyed by logical subnet name."
  value       = { for k, subnet in aws_subnet.subnets : k => subnet.id }
}

output "iperf_public_ips" {
  description = "Elastic IPs associated with each iPerf VM."
  value       = { for k, eip in aws_eip.iperf_vms_eips : k => eip.public_ip }
}
