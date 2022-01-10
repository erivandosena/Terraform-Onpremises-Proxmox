variable "ssh_key" {
  default = "<CHAVE-PUBLICA-SSH-ESTACAO-TRABALHO>"
}

variable "proxmox_host" {
    default = "https://192.168.200.100:8006/api2/json"
}

variable "proxmox_host_node" {
    default = "proxmox-rt-03"
}

variable "proxmox_api_token_id" {
    default = "terraform_provider@pam!proxmox_token_id"
}

variable "proxmox_api_token_secret" {
    default = "<API-TOKEN-SECRETO-PROXMOX>"
}

variable "template_name" {
    default = "debian10-cloudinit"
}

