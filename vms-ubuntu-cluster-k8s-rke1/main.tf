# Artefato: Provisiona maquinas virtuais via API do virtualizador Proxmox VE com Terraform
# Data: 10/01/2022 - Erivando Sena

# Variável de ambiente para logs
# TRACE ou DEBUG ou INFO ou WARN ou ERROR, Ex.: TF_LOG = export TRACE=ERROR
# export TF_LOG=off para desativar

# Instacao do provider para api proxmox
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=1.0.0"
    }
  }
  required_version = ">= 0.14"
}

provider "proxmox" {
  # Aqui inicia as chamandas ao arquivo vars
  # Url é o hostname (FQDN se você tiver um) para o host proxmox ao qual gostaria de se conectar para emitir os comandos 
  # Adicionar /api2/json no final para a API
  pm_api_url = var.proxmox_host

  # Api token id é na forma de: <username>@pam!<tokenId>
  pm_api_token_id = var.proxmox_api_token_id

  # Este é o hash do segredo emitido pela api proxmox
  pm_api_token_secret = var.proxmox_api_token_secret

  # Deixar tls_insecure definido como True a menos que hava uma situação de certificado Proxmox SSL totalmente resolvido (habilitando sabera)
  pm_tls_insecure = true
}

# O recurso é formatado por "[tipo]" "[name]" para nome(s) da entidade proxmox_vm_qemu criada
resource "proxmox_vm_qemu" "vm_name" {
  # Mapa do conjunto de nomes para instância(s)
  for_each = var.vms
  name = each.value["label"]

  # O target_node é qual nó hospeda o modelo, portanto, também qual nó hospedará a nova VM. pode ser diferente do host utilizado para se comunicar com a API
  target_node = var.proxmox_host_node

  # Variável referente ao nome do template "Ex.: debian11-cloudinit-template"
  clone = var.template_name

  # Configurações básicas da VM, discos, etc, refere-se ao agente convidado
  agent = 1
  os_type = "cloud-init"
  cores = 2
  sockets = 1
  cpu = "host"
  memory = 2048
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  disk {
    slot = 0
    size = var.tamanho_disco
    type = "scsi"
    storage = "local-lvm"
    iothread = 1
  }

  # Caso deseja dois NICs, basta copiar toda esta seção de rede e duplica-lo
  network {
    model = "virtio"
    bridge = "vmbr0"
  }

  # Este bloco, presumivelmente é algo sobre endereços MAC e ignorar mudanças de rede durante a vida do VM
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # Definicoes de rede
  # [gw=<GatewayIPv4>] [,gw6=<GatewayIPv6>] [,ip=<IPv4Format/CIDR>] [,ip6=<IPv6Format/CIDR>]
  # O numero do host que complemeenta o IP é formado pela soma do numero informado 
  # mais o valor da sequencia das instancias (Ex.: 1=11 ..., 5=51..., 10=101..., 20=201...)
  # Uma classe e faixa personalizada tambem pode ser informados e um gateway 
  
  #ipconfig0 = "ip=${var.ip_gateway}${each.value["sequence"]}/24,gw=${var.ip_gateway}"
  ipconfig0 = "ip=10.129.19.24${each.value["sequence"]}/24,gw=10.129.19.1"

  # Variavel definido para conter o texto da key.
  sshkeys = <<EOF
  ${var.ssh_key}
  EOF

  # Conexao necessaria para o(s) provisionamento(s) remoto(s)
  connection {
    type	= "ssh"
    user	= "ubuntu"
    host	= "10.129.19.24${each.value["sequence"]}"
    agent	= false
    private_key = "${var.ssh_key_private}"
  }

  # Provisionamentos remotos
  provisioner "remote-exec" {
    inline = [
	"sudo cloud-init status --wait", 
	"sudo echo ${var.ssh_key} /root/.ssh/authorized_keys",
	"sudo apt list --upgradable",
	"sudo apt upgrade -y",
	"sudo apt update",
	"sudo apt autoremove -y",
	"sudo curl https://releases.rancher.com/install-docker/20.10.sh | sh",
        "sudo openssl s_client -showcerts -connect 10.129.19.217:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > ca.crt",
        "sudo cat ca.crt | sudo tee -a /etc/ssl/certs/ca-certificates.crt",
        "sudo openssl s_client -showcerts -connect 10.129.19.222:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > ca.crt",
        "sudo cat ca.crt | sudo tee -a /etc/ssl/certs/ca-certificates.crt",
        "sudo service docker restart",
	]
  }

  # Provisionamento local
  provisioner "local-exec" {
    command = "echo > ~/.ssh/known_hosts && echo > /root/.ssh/known_hosts"
  }

}
