#!/bin/bash

function display
{
    echo ""
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~ $*"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo ""
}

display "Welcome to the INDI and KStars 64 Bit Configuration Script with 32 bit KStars (for SBIG)."

display "This will update, install and configure your 64 bit Ubuntu-Mate system to work with 32 bit INDI and KStars to be a hub for Astrophotography.  The 32 bit KStars is because SBIG doesn't work in 64 bit right now.   If you do not plan to use an SBIG, please use the other 64 bit installer. Be sure to read the script first to see what it does and to customize it."

if [ "$(whoami)" != "root" ]; then
	display "Please run this script with sudo due to the fact that it must do a number of sudo tasks.  Exiting now."
	exit 1
fi

read -p "Are you ready to proceed (y/n)? " proceed

if [ "$proceed" != "y" ]
then
	exit
fi

#########################################################
#############  Updates

# This will prevent Firefox from being updated.  Right now when Firefox gets updated on Raspberry Pi, it breaks it. 
display "Currently (11/2017) there is an issue with Ubuntu-Mate on Raspberry Pi.  Updating Firefox Breaks it.  This might also be true for your system."
read -p "Do you want to prevent a Firefox update (y/n)? " preventUpdateFirefox
if [ "$preventUpdateFirefox" == "y" ]
then
	sudo apt-mark hold firefox
fi

# This adds armhf architecture if it doesn't exist on the system yet.
sudo dpkg --add-architecture armhf

# Updates the system to the latest packages.
display "Updating installed packages"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

#########################################################
#############  Configuration for Ease of Use/Access

# This will set your account to autologin.  If you don't want this. then put a # on each line to comment it out.
display "Setting account: "$SUDO_USER" to auto login."
##################
sudo cat > /usr/share/lightdm/lightdm.conf.d/60-lightdm-gtk-greeter.conf <<- EOF
[SeatDefaults]
greeter-session=lightdm-gtk-greeter
autologin-user=$SUDO_USER
EOF
##################

# Installs Synaptic Package Manager for easy software install/removal
display "Installing Synaptic"
sudo apt-get -y install synaptic

# This will enable SSH which is apparently disabled on Raspberry Pi by default, maybe this is true for you system.
display "Enabling SSH"
sudo apt-get -y purge openssh-server
sudo apt-get -y install openssh-server

# To view the computer Remotely, this installs RealVNC Servier and enables it to run by default.
display "Installing RealVNC Server"
wget https://www.realvnc.com/download/binary/latest/debian/arm/ -O VNC.deb
sudo dpkg -i VNC.deb
sudo systemctl enable vncserver-x11-serviced.service
rm VNC.deb

# This will make a folder on the desktop for the launchers
mkdir ~/Desktop/utilities
sudo chown $SUDO_USER ~/Desktop/utilities

# This will create a shortcut on the desktop for creating udev rules for Serial Devices
##################
sudo cat > ~/Desktop/utilities/SerialDevices.desktop <<- EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Icon[en_US]=mate-panel-launcher
Exec=sudo $(echo ~/)AstroPi3/udevRuleScript.sh
Name[en_US]=Create Rule for Serial Device
Name=Create Rule for Serial Device
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/SerialDevices.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/SerialDevices.desktop

#########################################################
#############  Configuration for Hotspot Wifi for Connecting on the Observing Field

# This will fix a problem where AdHoc and Hotspot Networks Shut down very shortly after starting them
# Apparently it was due to power management of the wifi network by Network Manager.
# If Network Manager did not detect internet, it shut down the connections to save energy. 
# If you want to leave wifi power management enabled, put #'s in front of this section
display "Preventing Wifi Power Management from shutting down AdHoc and Hotspot Networks"
##################
sudo cat > /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf <<- EOF
[connection]
wifi.powersave = 2
EOF
##################

# This will create a NetworkManager Wifi Hotspot File.  
# You can edit this file to match your settings now or after the script runs in Network Manager.
# If you prefer to set this up yourself, you can comment out this section with #'s.
# If you want the hotspot to start up by default you should set autoconnect to true.
display "Creating $(hostname -s)_FieldWifi, Hotspot Wifi for the observing field"
nmcli connection add type wifi ifname '*' con-name $(hostname -s)_FieldWifi autoconnect no ssid $(hostname -s)_FieldWifi
nmcli connection modify $(hostname -s)_FieldWifi 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
nmcli connection modify $(hostname -s)_FieldWifi 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk $(hostname -s)_password

nmcli connection add type wifi ifname '*' con-name $(hostname -s)_FieldWifi_5G autoconnect no ssid $(hostname -s)_FieldWifi_5G
nmcli connection modify $(hostname -s)_FieldWifi_5G 802-11-wireless.mode ap 802-11-wireless.band a ipv4.method shared
nmcli connection modify $(hostname -s)_FieldWifi_5G 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk $(hostname -s)_password

# This will make a link to start the hotspot wifi on the Desktop
##################
sudo cat > ~/Desktop/utilities/StartFieldWifi.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=mate-panel-launcher
Name[en_US]=Start $(hostname -s) Field Wifi
Exec=nmcli con up $(hostname -s)_FieldWifi
Name=Start $(hostname -s)_FieldWifi 
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/StartFieldWifi.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/StartFieldWifi.desktop
##################
sudo cat > ~/Desktop/utilities/StartFieldWifi_5G.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=mate-panel-launcher
Name[en_US]=Start $(hostname -s) Field Wifi 5G
Exec=nmcli con up $(hostname -s)_FieldWifi_5G
Name=Start $(hostname -s)_FieldWifi_5G
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/StartFieldWifi_5G.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/StartFieldWifi_5G.desktop

# This will make a link to restart Network Manager Service if there is a problem
##################
sudo cat > ~/Desktop/utilities/StartNmService.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=mate-panel-launcher
Name[en_US]=Restart Network Manager Service
Exec=gksu systemctl restart NetworkManager.service
Name=Restart Network Manager Service
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/StartNmService.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/StartNmService.desktop

# This will make a link to restart nm-applet which sometimes crashes
##################
sudo cat > ~/Desktop/utilities/StartNmApplet.desktop <<- EOF
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[en_US]=mate-panel-launcher
Name[en_US]=Restart Network Manager Applet
Exec=nm-applet
Name=Restart Network Manager
Icon=mate-panel-launcher
EOF
##################
sudo chmod +x ~/Desktop/utilities/StartNmApplet.desktop
sudo chown $SUDO_USER ~/Desktop/utilities/StartNmApplet.desktop

#########################################################
#############  File Sharing Configuration

display "Setting up File Sharing"

# Installs samba so that you can share files to your other computer(s).
sudo apt-get -y install samba

# Installs caja-share so that you can easily share the folders you want.
sudo apt-get -y install caja-share

# Adds yourself to the user group of who can use samba.
sudo smbpasswd -a $SUDO_USER


#########################################################
#############  Very Important Configuration Items

# This will create a swap file for an increased 2 GB of artificial RAM.  This is not needed on all systems, since different cameras download different size images, but if you are using a DSLR, it definitely is.
display "Creating SWAP Memory"
wget https://raw.githubusercontent.com/Cretezy/Swap/master/swap.sh -O swap
sh swap 2G
rm swap

# This should fix an issue where you might not be able to use a serial mount connection because you are not in the "dialout" group
display "Enabling Serial Communication"
sudo usermod -a -G dialout $SUDO_USER


#########################################################
#############  ASTRONOMY SOFTWARE

# Installs INDI, Kstars, and Ekos bleeding edge and debugging
display "Installing INDI and KStars"
sudo apt-add-repository ppa:mutlaqja/ppa -y
sudo apt-get update
sudo apt-get -fy install
sudo apt-get -y install unity-gtk2-module:armhf
sudo apt-get -y install gtk2-engines-murrine:armhf
sudo apt-get -y install topmenu-gtk2:armhf
sudo apt-get -y install topmenu-gtk3:armhf
sudo apt-get -y install libcanberra-gtk-module:armhf
sudo apt-get -y install libatk-adaptor:armhf
sudo apt-get -y install indi-full:armhf
sudo apt-get -y install libkf5auth5:armhf
sudo apt-get -y install libkf5configgui5:armhf
sudo apt-get -y install libkf5configwidgets5:armhf
sudo apt-get -y install libkf5crash5:armhf
sudo apt-get -y install libkf5kiocore5:armhf
sudo apt-get -y install libkf5kiowidgets5:armhf
sudo apt-get -y install libkf5newstuff5:armhf
sudo apt-get -y install libkf5notifications5:armhf
sudo apt-get -y install libkf5notifyconfig5:armhf
sudo apt-get -y install libkf5plotting5:armhf
sudo apt-get -y install libkf5widgetsaddons5:armhf
sudo apt-get -y install libkf5xmlgui5:armhf
sudo apt-get -y install libqt5gui5:armhf
sudo apt-get -y install libqt5printsupport5:armhf
sudo apt-get -y install libqt5quick5:armhf
sudo apt-get -y install libqt5svg5:armhf
sudo apt-get -y install libqt5widgets5:armhf
sudo apt-get -y install kstars-bleeding-data:all
sudo apt-get -y install kded5:armhf
sudo apt-get -y install kinit:armhf
sudo apt-get -y install qml-module-qtquick-controls:armhf
cd ~/Downloads
mkdir kstars32bit
cd kstars32bit
apt-get download kstars-bleeding:armhf
apt-get download kstars-bleeding-dbg
sudo dpkg --force-all -i *.deb

# Installs the General Star Catalog if you plan on using the simulators to test (If not, you can comment this line out with a #)
display "Installing GSC"
sudo apt-get -y install gsc

# Installs the Astrometry.net package for supporting offline plate solves.  If you just want the online solver, comment this out with a #.
display "Installing Astrometry.net"
sudo apt-get -y install astrometry.net

# Installs PHD2 if you want it.  If not, comment each line out with a #.
display "Installing PHD2"
sudo apt-add-repository ppa:pch/phd2 -y
sudo apt-get update
sudo apt-get -y install phd2

# This will copy the desktop shortcuts into place.  If you don't want  Desktop Shortcuts, of course you can comment this out.
display "Putting shortcuts on Desktop"

sudo cp /usr/share/applications/org.kde.kstars.desktop  ~/Desktop/
sudo chmod +x ~/Desktop/org.kde.kstars.desktop
sudo chown $SUDO_USER ~/Desktop/org.kde.kstars.desktop

sudo cp /usr/share/applications/phd2.desktop  ~/Desktop/
sudo chmod +x ~/Desktop/phd2.desktop
sudo chown $SUDO_USER ~/Desktop/phd2.desktop

#########################################################
#############  INDI WEB MANAGER

display "Installing and Configuring INDI Web Manager"

# This will install INDI Web Manager
sudo pip install indiweb

# This will prepare the indiwebmanager.service file
##################
sudo cat > /etc/systemd/system/indiwebmanager.service <<- EOF
[Unit]
Description=INDI Web Manager
After=multi-user.target

[Service]
Type=idle
User=$SUDO_USER
ExecStart=/usr/local/bin/indi-web -v
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
##################

# This will change the indiwebmanager.service file permissions and enable it.
sudo chmod 644 /etc/systemd/system/indiwebmanager.service
sudo systemctl daemon-reload
sudo systemctl enable indiwebmanager.service

# This will make a link to the Web Manager on the Desktop
##################
sudo cat > ~/Desktop/INDIWebManager.desktop <<- EOF
[Desktop Entry]
Encoding=UTF-8
Name=INDI Web Manager
Type=Link
URL=http://localhost:8624
Icon=/usr/local/lib/python2.7/dist-packages/indiweb/views/img/indi_logo.png
EOF
##################
sudo chmod +x ~/Desktop/INDIWebManager.desktop
sudo chown $SUDO_USER ~/Desktop/INDIWebManager.desktop

#########################################################

# This will make the udev in the folder executable in case the user wants to use it.
chmod +x ~/AstroPi3/udevRuleScript.sh

display "Script Execution Complete.  Your Single Board Computer should now be ready to use for Astrophotography.  You should restart it."