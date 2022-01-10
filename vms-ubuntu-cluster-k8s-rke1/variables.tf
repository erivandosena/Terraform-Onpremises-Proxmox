# Chave SSH publica
variable "ssh_key" {
  default = <<EOT
<CHAVE-PUBLICA-SSH-ESTACAO-TRABALHO>
<CHAVE-PUBLICA-SSH-HOST-RANCHER>
  EOT
}

# Chave SSH privada
variable "ssh_key_private" {
  default = <<EOT
-----BEGIN OPENSSH PRIVATE KEY-----
<CHAVE-PRIVADA-SSH-ESTACAO-TRABALHO>
-----END OPENSSH PRIVATE KEY-----
  EOT
}

# Host proxmox
variable "proxmox_host" {
    default = "https://192.168.200.100:8006/api2/json"
}

# Nome do nó destino no cluster proxmox
variable "proxmox_host_node" {
    default = "proxmox-rt-01"
}

# ID do token da API proxmox
variable "proxmox_api_token_id" {
    default = "terraform_provider@pam!proxmox_token_id"
}

# Token secreto do cliente da API proxmox
variable "proxmox_api_token_secret" {
    default = "<TOKEN-SECRETO-API-PROXMOX>"
}

# Nome da imagem template
variable "template_name" {
    default = "ubuntu20-cloudinit-v1"
}

# Tamanho do dimensionamento do disco em Gigabytes
variable "tamanho_disco" {
    default = "12G"
}

 # Numero do gateway da rede
 variable "ip_gateway" {
     default = "10.129.19.1"
 }

# Mapa com detalhes de formatacao de maquinas virtuais
variable "vms" {
  type = map(object({
    sequence = number
    label = string
    cidr = string
  }))
  default = {
    "vm1" = {
          sequence = 1
	  label = "ubuntu-k8s-1"
          cidr = "0.0.0.0/24"
	}
    "vm2" = {
          sequence = 2
          label = "ubuntu-k8s-2"
          cidr = "0.0.0.0/24"
	}
    "vm3" = {
          sequence = 3
          label = "ubuntu-k8s-3"
          cidr = "0.0.0.0/24"
        }
   }
}
