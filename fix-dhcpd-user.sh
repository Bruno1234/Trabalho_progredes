#!/bin/bash

# Criar grupo dhcpd se não existir
if ! getent group dhcpd > /dev/null; then
  echo "[+] Criando grupo dhcpd..."
  sudo groupadd --system dhcpd
else
  echo "[=] Grupo dhcpd já existe."
fi

# Criar usuário dhcpd se não existir
if ! id dhcpd > /dev/null 2>&1; then
  echo "[+] Criando usuário dhcpd..."
  sudo useradd --system --no-create-home --shell /usr/sbin/nologin --gid dhcpd dhcpd
else
  echo "[=] Usuário dhcpd já existe."
fi

# Reiniciar o serviço
echo "[*] Reiniciando o serviço isc-dhcp-server..."
sudo systemctl restart isc-dhcp-server

# Verificar status
echo "[*] Status atual do serviço:"
sudo systemctl status isc-dhcp-server --no-pager
