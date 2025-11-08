# --- Consolidated Locals ---

locals {
  subnets   = var.subnets
  iperf_vms = var.iperf_vms

  fortigate_configs = {
    fortigate_dut1 = file(var.fortigate_configs["fortigate_dut1"])
    fortigate_dut2 = file(var.fortigate_configs["fortigate_dut2"])
  }

  fortigate_dut_ips = {
    fortigate_dut1 = var.fortigate_dut1_private_ips
    fortigate_dut2 = var.fortigate_dut2_private_ips
  }

  ubuntu_package_install = join(" ", var.ubuntu_packages)
}