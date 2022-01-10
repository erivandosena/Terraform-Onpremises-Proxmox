# Artefato: Provisiona maquinas virtuais via API do virtualizador Proxmox VE
# Referecias: https://austinsnerdythings.com/
# Com adaptacoes: Erivando Sena
# Data: 10/01/2022

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
# O recurso é formatado para ser "[tipo]" "[entity_name]" então, neste caso, busca-se criar uma entidade proxmox_vm_qemu chamada VM-IaC
resource "proxmox_vm_qemu" "VM-IaC" {
  # Neste caso apenas 1 por enquanto, definir para 0 para destruir VM ao "aplicar" (Apply)
  # === QUANTIDAE DE VM's ===
  count = 2
  # O count.index começa em 0, então + 1 significa que esta VM será nomeada VM-IaC-1 no proxmox
  name = "VM-IaC-${count.index + 1}"
  # O target_node é qual nó hospeda o modelo, portanto, também qual nó hospedará a nova VM. pode ser diferente do host utilizado para se comunicar com a API
  target_node = var.proxmox_host_node
  # Variável referente ao nome do template "Ex.: debian11-cloudinit-template"
  clone = var.template_name
  # Configurações básicas da VM aqui, refere-se ao agente convidado
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
    # Definir o tamanho do disco aqui. deixá-lo menor para testes facilita, porque expandir o disco demanda tempo.
    size = "12G"
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
  # Esta trecho ${count.index + 1} anexa texto até o final do endereço ip
  # neste caso, se, somenetese, adicionando uma única VM, o IP (exemplo) vai
  # ser 10.98.1.91 desde que a contagem.índice começa em 0. e assim
  # é possivel criar várias VMs e ter um IP atribuído a cada um (Ex.: .91, .92, .93, ...)
  ipconfig0 = "ip=10.129.19.${count.index + 1}/24,gw=10.129.19.1"
  
  # Variavel definido para conter o texto da key.
  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}
