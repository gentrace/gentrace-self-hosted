# packer/template.pkr.hcl
packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

# --- Variables --- 
variable "source_qcow_path" {
  type    = string
  # Path relative to the packer directory, or absolute path
  default = "./base_images/ubuntu-noble-server-cloudimg-amd64.img"
  description = "Path to the source Ubuntu QCOW2 cloud image."
}

variable "output_directory" {
  type    = string
  default = "output-ubuntu-docker"
}

variable "vm_name" {
  type    = string
  default = "ubuntu-docker-compose"
}

variable "disk_size" {
  type    = string
  # Cloud images have a default size; this will resize the copy if needed.
  # Ensure it's large enough for Docker images + OS + app data.
  default = "20G" 
}

# == Initial SSH Connection Settings (for Cloud Image) ==
variable "ssh_username" {
  type        = string
  default     = "ubuntu" # Ubuntu cloud images use 'ubuntu' as the default user
  description = "Initial SSH username Packer connects with."
}

# Packer QEMU builder uses key auth by default. ssh_password is only needed
# if key auth fails or ssh_private_key_file is unset. The default 'ubuntu'
# user typically has passwordless sudo and expects SSH key injection via
# cloud-init, which Packer handles with a temporary keypair.

# Cloud images often disable password auth and require SSH keys.
# Packer can generate a temporary keypair.
# variable "ssh_password" { type = string sensitive = true default = "..." } # Likely not used
variable "ssh_private_key_file" {
  type    = string
  default = "" # Let Packer generate a temporary key
}

# == Final User Credentials (from GitHub Actions Inputs) ==
variable "final_username" {
  type    = string
  default = "defaultuser" # Default for local testing if not overridden
}

variable "final_password" {
  type      = string
  sensitive = true
  default   = "changeme" # Default for local testing if not overridden
}

variable "headless" {
  type    = bool
  # Set headless=true for CI/automation, false for local debugging with GUI
  default = true 
}

variable "memory" {
  type    = number
  default = 4096
  description = "RAM for the build VM in MB."
}

# --- Source --- 
source "qemu" "ubuntu-docker" {
  # No ISO settings needed

  # --- Disk Configuration --- 
  output_directory    = var.output_directory
  vm_name             = "${var.vm_name}.qcow2" # Output format
  format              = "qcow2"
  disk_size           = var.disk_size # Packer will resize the copy
  disk_interface      = "virtio"
  
  # --- QEMU Machine Settings --- 
  headless            = var.headless
  memory              = var.memory
  net_device          = "virtio-net"
  # Accelerator is intentionally omitted for auto-detection (KVM/HVF/TCG)

  # Use qemuargs to specify the source drive
  # Creates a temporary overlay file based on the source image
  qemuargs = [
    [ "-drive", "file=${var.source_qcow_path},if=virtio,cache=writeback,discard=ignore,format=qcow2" ],
    [ "-serial", "file:serial.log" ]
  ]
  # QEMU will boot directly from this drive

  # --- SSH Communicator Settings --- 
  communicator        = "ssh"
  ssh_port            = 22
  ssh_wait_timeout    = "20m" # Increased timeout
  ssh_username        = var.ssh_username
  # Packer QEMU builder uses key auth by default.
  # ssh_password        = var.ssh_password
  ssh_handshake_attempts = "60" # Increased attempts
  ssh_bastion_host = "" # Optional

  # Shutdown command for Ubuntu (ubuntu user typically has passwordless sudo)
  shutdown_command    = "sudo /sbin/halt -p"

  # Provide a dummy ISO to satisfy Packer validation.
  # The actual boot device is specified via -drive in qemuargs.
  # Using iPXE bootloader ISO as a small, reliable target.
  iso_url             = "https://boot.ipxe.org/ipxe.iso"
  iso_checksum        = "sha256:6c92cf42a61ae8ad04640669274a6c22c1aa9ae96dea2cafd5d0ac267eb29fbb"
}


# --- Build --- 
build {
  sources = ["source.qemu.ubuntu-docker"]

  # --- Provisioners --- 
  
  # Upload application files FIRST (Added in next step)
  # provisioner "file" {
  #   source      = "../docker/docker-compose.yml" 
  #   destination = "/tmp/docker-compose.yml"
  # }
  # provisioner "file" {
  #   source      = "../docker/.env.template"
  #   destination = "/tmp/.env"
  # }

#   # Upload the setup script
#   provisioner "file" {
#     source      = "scripts/setup.sh"
#     destination = "/tmp/setup.sh"
#   }

#   # Execute the setup script
#   provisioner "shell" {
#     # Pass final user credentials into the script's environment
#     environment_vars = [
#       "FINAL_USERNAME=${var.final_username}",
#       "FINAL_PASSWORD=${var.final_password}"
#     ]
#     # Script runs as the ssh_user ('debian'), uses sudo internally
#     # Point to the LOCAL script path; Packer handles uploading it.
#     script = "scripts/setup.sh" 
#   }

  # Post-processors will be added later
} 