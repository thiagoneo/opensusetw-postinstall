#!/usr/bin/env bash

###################################################
# Script de Pós-instalação do openSUSE Tumbleweed #
# Autor: Thiago de S. Ferreira                    #
# E-mail: sousathiago@protonmail.com              #
###################################################

# Verificar se o usuário é o root
if [[ $EUID -ne 0 ]]; then
   echo "Este script precisa ser executado como root."
   exit 1
fi

#--------------------------------- VARIÁVEIS ----------------------------------#
SCR_DIRECTORY=`pwd`
STANDARD_USER=ts
USER_HOME=$(getent passwd "$STANDARD_USER" | cut -d: -f6)
ISO_DIR="$USER_HOME/etc/ISOs"
PACKAGES_REMOVE="packages_remove.txt"
PACKAGES_INSTALL="packages_install.txt"
FLATPAK_INSTALL="flatpak_install.txt"
STEAM_VERSION="flatpak"
# Cor das pastas do tema Papirus
# Opções disponíveis: adwaita black blue bluegrey breeze brown carmine cyan darkcyan deeporange
#  green grey indigo magenta nordic orange palebrown paleorange pink red teal violet white yaru yellow
FOLDER_COLORS="adwaita"

killall gnome-software

#--------------------------- ATUALIZAR REPOSITÓRIOS ---------------------------#
zypper --gpg-auto-import-keys refresh

#------------------- ADICIONAR REPOSITÓRIOS DE TERCEIROS ----------------------#
echo "Adicionando repositórios de terceiros..."
# Dead_Mozay (Pacotes: adw-gtk3, grub-customizer)
zypper --gpg-auto-import-keys ar \
https://download.opensuse.org/repositories/home:Dead_Mozay/openSUSE_Tumbleweed/home:Dead_Mozay.repo

# Packman Essentials (codecs multimídia)
# zypper --gpg-auto-import-keys ar -cfp 90 \
# http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials packman-essentials

zypper --gpg-auto-import-keys refresh

#------------------- HABILITAR DOWNLOADS PARALELOS ZYPPER ---------------------#
sudo tee /etc/profile.d/opensuse_repos.sh > /dev/null << 'EOF'
#!/bin/bash

export ZYPP_PCK_PRELOAD=1
export ZYPP_CURL2=1
EOF

sed -i \
  -e '/^ *download\.max_concurrent_connections *=/d' \
  -e '/^ *# *download\.max_concurrent_connections *=/d' \
  -e '$a download.max_concurrent_connections=8' \
  /etc/zypp/zypp.conf

#------------------------- INSTALAR O PACOTE "dialog" -------------------------#
# Instalar o pacote dialog, se não for encontrado no sistema
if ! command -v dialog &> /dev/null; then
    zypper install -y dialog
fi

#-------------------------- INSTALAR O PACOTE "git" ---------------------------#
# Instalar o pacote dialog, se não for encontrado no sistema
if ! command -v git &> /dev/null; then
    zypper install -y git
fi

#------------------------ REMOVER PACOTES INDESEJADOS -------------------------#
if [[ -f "$PACKAGES_REMOVE" ]]; then
    echo "🔧 Removendo pacotes..."
    zypper rm -y --clean-deps $(cat "${PACKAGES_REMOVE}")

    echo "🚫 Bloqueando pacotes..."
    zypper al $(cat "${PACKAGES_REMOVE}")

    echo "✅ Pacotes removidos e bloqueados com sucesso."
else
    echo "⚠️  Arquivo '$PACKAGES_REMOVE' não encontrado. Pulando etapa de remoção e bloqueio."
fi

#------------------------- INSTALAR PACOTES DIVERSOS --------------------------#
zypper install -y $(cat "${PACKAGES_INSTALL}")

#------------------------ INSTALAR PACOTES RPM LOCAIS -------------------------#
echo "Baixando pacotes..."
wget -c https://filestore.fortinet.com/forticlient/downloads/forticlient_vpn_7.4.3.1736_x86_64.rpm -P rpms
echo "📦 Instalando pacotes RPM locais..."
zypper --no-gpg-checks install -y rpms/*.rpm

#--------------------------- DEFINIR NOVO HOSTNAME ----------------------------#
OLD_HOSTNAME=`hostname`
NEW_HOSTNAME=$(\
    dialog --no-cancel --title "Definir hostname"\
        --inputbox "Insira o nome do computador:" 8 40\
    3>&1 1>&2 2>&3 3>&- \
)
echo ""
sed -i "s/${OLD_HOSTNAME}/${NEW_HOSTNAME}/g" /etc/hosts
hostnamectl set-hostname ${NEW_HOSTNAME}
echo "Novo HOSTNAME definido como ${NEW_HOSTNAME}"

#--------------------- INSTALAR PACOTE DE FONTES MICROSOFT --------------------#
echo "Instalando fontes Microsoft..."
zypper install -y fetchmsttfonts
# SegoeUI
cd src
git clone https://github.com/mrbvrz/segoe-ui-linux.git
cd segoe-ui-linux
bash install.sh
rm -fv /usr/share/fonts/Microsoft/TrueType/SegoeUI/seguiemj.ttf
# Atualizar o cache de fontes
echo "Atualizando cache de fontes..."
fc-cache --force
cd ${SCR_DIRECTORY}

#--------------------------- INSTALAR OUTRAS FONTES ---------------------------#
cd src
# Red Hat Display
wget -c https://font.download/dl/font/red-hat-display-2.zip -O RedHatDisplay.zip
mkdir -p /usr/share/fonts/truetype/RedHatDisplay/
unzip RedHatDisplay.zip -d /usr/share/fonts/truetype/RedHatDisplay/
chown -R root:root /usr/share/fonts/truetype/RedHatDisplay/
chmod 644 /usr/share/fonts/truetype/RedHatDisplay/*

# Space Mono
wget -c https://font.download/dl/font/space-mono.zip -O SpaceMono.zip
mkdir -p /usr/share/fonts/truetype/SpaceMono
unzip SpaceMono.zip -d /usr/share/fonts/truetype/SpaceMono/
chown -R root:root /usr/share/fonts/truetype/SpaceMono/
chmod 644 /usr/share/fonts/truetype/SpaceMono/*

# Atualizar o cache de fontes
echo "Atualizando cache de fontes..."
fc-cache --force
cd ${SCR_DIRECTORY}

#-------------------------- INSTALAR CODECS MULTIMÍDIA ------------------------#
# zypper  dist-upgrade -y --from packman-essentials --allow-downgrade --allow-vendor-change

# zypper install -y --from packman-essentials ffmpeg gstreamer-plugins-bad \
# gstreamer-plugins-libav gstreamer-plugins-ugly libavcodec58 libavdevice58 \
# libavfilter7 libavformat58 libavresample4 libavutil56 vlc-codecs

#------------------------------- INSTALAR STEAM -------------------------------#
if [[ "$STEAM_VERSION" == "flatpak" ]]; then
    echo "Instalando Steam via Flatpak..."
    flatpak -y install flathub com.valvesoftware.Steam
elif [[ "$STEAM_VERSION" == "rpm" ]]; then
    echo "Instalando Steam via RPM..."
    zypper install -y steam
else
    echo "Versão do Steam desconhecida. Por favor, verifique a variável STEAM_VERSION."
fi

#---------------------- INSTALAR SUPORTE A VIRTUALIZAÇÃO ----------------------#
zypper install -y libvirt virt-manager
usermod -aG libvirt ${STANDARD_USER}
systemctl enable --now libvirtd

if [ ! -d "$ISO_DIR" ]; then
    echo "Criando diretório $ISO_DIR"
    mkdir -p "$ISO_DIR"
    chmod ${STANDARD_USER}:${STANDARD_USER} ${ISO_DIR}
fi

# Aplicar permissões de acesso ao emulador
setfacl -m u:qemu:x "$(dirname "$USER_HOME")"
setfacl -m u:qemu:x "$USER_HOME"
setfacl -m u:qemu:x "$USER_HOME/etc"
setfacl -m u:qemu:rx "$ISO_DIR"

# iniciar rede
virsh net-start --network default
virsh net-autostart --network default

# Adicionar pool de ISOs
virsh pool-define-as --name ISOs --type dir --target $ISO_DIR
virsh pool-start ISOs
virsh pool-autostart ISOs

#----------------------------- INSTALAR FLATPAKS ------------------------------#
flatpak update -y
flatpak -y install flathub $(cat "${FLATPAK_INSTALL}")

#------------------------ CUSTOMIZAR APARÊNCIA DO GRUB ------------------------#
cd src
git clone https://github.com/vinceliuice/grub2-themes.git
mv background-stylish.jpg grub2-themes/backgrounds/1080p/background-stylish.jpg
cd grub2-themes
bash install.sh -t stylish
sudo sed -i 's/^GRUB_GFXMODE=1920x1080,auto$/GRUB_GFXMODE=1600x900,auto/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
cd ${SCR_DIRECTORY}

#-------------------------- INSTALAR CERTIFICADO CA ---------------------------#
trust anchor --store ca.crt

#------------------------- CONFIGURAÇÕES DO FIREWALL ---------------------------#
echo "🛡️ Configurando Firewall..."
firewall-cmd --set-default-zone=home
firewall-cmd --reload
firewall-cmd --add-service=kdeconnect --permanent
firewall-cmd --reload

#--------------------- CUSTOMIZAR COR DAS PASTAS PAPIRUS -----------------------#
echo "Configurando cores das pastas do Papirus..."
papirus-folders -C ${FOLDER_COLORS}

#----------------------------- CONFIGURAR SNAPPER ------------------------------#
cp -fv snapper_root /etc/snapper/configs/root


#------------------------------------ FIM -------------------------------------#

dialog --erase-on-exit --yesno "Chegamos ao fim. É necessário reiniciar o computador para aplicar as alterações. Deseja reiniciar agora?" 8 60
REBOOT=$?
case $REBOOT in
    0) systemctl reboot;;
    1) echo "Por favor reinicie o sistema assim que possível.";;
    255) echo "[ESC] key pressed.";;
esac
