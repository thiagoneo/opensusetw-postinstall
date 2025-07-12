#!/usr/bin/env bash

###################################################
# Script de Pós-instalação do openSUSE Tumbleweed #
# Configurações do usuário. Executar este script  #
# após executar o system.sh                       #
# Autor: Thiago de S. Ferreira                    #
# E-mail: sousathiago@protonmail.com              #
###################################################

#--------------------------------- VARIÁVEIS ----------------------------------#
SCR_DIRECTORY=`pwd`
STANDARD_USER=ts
USER_HOME=$(getent passwd "$STANDARD_USER" | cut -d: -f6)
# Cor de destaque do GNOME:
ACCENT_COLOR='blue' # Opções disponíveis: blue, teal, green, yellow, orange, red, pink, purple, slate

#------------------------- INSTALAR EXTENSÕES DO GNOME -------------------------#
cd ${SCR_DIRECTORY}
cd gnome-extensions
# Download das extensões
echo "Baixando extensões..."
grep -v '^#' extensions_download.txt | wget -i -
echo "Instalando extensões..."
for file in *.zip; do
    gnome-extensions install "$file"
done
dconf load /org/gnome/shell/extensions/ < extensions.conf
echo "Extensões instaladas. Você ainda deve habilitá-las após encerrar a sessão e entrar novamente."

#------------------------ MAIS CONFIGURAÇÕES DO USUARIO -----------------------#
cd ${SCR_DIRECTORY}
cd user-confs
# Ordenar pastas antes dos arquivos
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"
gsettings set org.gnome.desktop.interface text-scaling-factor 1.05
gsettings set org.gnome.desktop.interface font-name 'Red Hat Display 10'
gsettings set org.gnome.desktop.interface document-font-name 'Red Hat Display 10'
gsettings set org.gnome.desktop.interface monospace-font-name 'Space Mono 10'
gsettings set org.gnome.desktop.interface icon-theme Papirus
gsettings set org.gnome.desktop.interface accent-color "$ACCENT_COLOR"
dconf load /org/gnome/nautilus/ < nautilus.conf
dconf load /org/gnome/TextEditor/ < text-editor.conf
