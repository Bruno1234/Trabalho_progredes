terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Imagem base Ubuntu
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-base.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  format = "qcow2"
}

# Disco do servidor DHCP
resource "libvirt_volume" "dhcp_disk" {
  name           = "dhcp-server.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  format         = "qcow2"
}

# Disco do cliente
resource "libvirt_volume" "client_disk" {
  name           = "dhcp-client.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  format         = "qcow2"
}

# Cloud-init para servidor
data "template_file" "cloudinit_dhcp_server" {
  template = file("${path.module}/cloud_init_dhcp_server.cfg")
}

resource "libvirt_cloudinit_disk" "dhcp_server_cloudinit" {
  name      = "cloudinit-dhcp-server.iso"
  user_data = data.template_file.cloudinit_dhcp_server.rendered
  pool      = "default"
}

# Cloud-init para cliente
data "template_file" "cloudinit_dhcp_client" {
  template = file("${path.module}/cloud_init_dhcp_client.cfg")
}

resource "libvirt_cloudinit_disk" "dhcp_client_cloudinit" {
  name      = "cloudinit-dhcp-client.iso"
  user_data = data.template_file.cloudinit_dhcp_client.rendered
  pool      = "default"
}

# Servidor DHCP
resource "libvirt_domain" "dhcp_server" {
  name   = "dhcp-server"
  memory = 1024
  vcpu   = 1

  disk {
    volume_id = libvirt_volume.dhcp_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.dhcp_server_cloudinit.id

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

# Cliente DHCP
resource "libvirt_domain" "dhcp_client" {
  name   = "dhcp-client"
  memory = 1024
  vcpu   = 1

  disk {
    volume_id = libvirt_volume.client_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.dhcp_client_cloudinit.id

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}
