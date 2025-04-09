#!/bin/bash
DNS_SERVER=192.168.56.9
MYIP=$(hostname -I | awk '{print $2}')
MYHOST=$(hostname)
sudo chown vagrant id_ed25519
sed -i "s/#DNS=/DNS=$DNS_SERVER/" /etc/systemd/resolved.conf
sed -i "s/nameserver 127.0.0.53/nameserver $DNS_SERVER/" /etc/resolv.conf
sudo systemctl restart systemd-resolved

sudo chown vagrant id_ed25519
ssh-keyscan -H $DNS_SERVER >> ~/.ssh/known_hosts
ssh -i id_ed25519 student@$DNS_SERVER "grep -q '$MYHOST' /etc/dnsmasq.conf || echo 'address=/$MYHOST.vmnet/$MYIP' | sudo tee -a /etc/dnsmasq.conf && sudo systemctl restart dnsmasq"

sudo groupadd sftpgroup
sudo useradd -G sftpgroup -d /srv/sftpuser -s /bin/bash sftpuser
mkdir -p /srv/sftpuser
sudo chown root /srv/sftpuser
sudo chmod g+rx /srv/sftpuser
mkdir -p /srv/sftpuser/data
chown sftpuser:sftpuser /srv/sftpuser/data

sudo mkdir /srv/sftpuser/.ssh
sudo cp ./.ssh/authorized_keys /srv/sftpuser/.ssh/
sudo chown -R sftpuser:sftpuser /srv/sftpuser/.ssh
sudo chmod 700 /srv/sftpuser/.ssh
sudo chmod 600 /srv/sftpuser/.ssh/authorized_keys

cp /vagrant/scheduler.sh /home/vagrant
chmod +x /home/vagrant/scheduler.sh
echo "*/5 * * * * vagrant /home/vagrant/scheduler.sh" >> "/etc/crontab"

export DEBIAN_FRONTEND=noninteractive
apt update
echo "postfix postfix/mailname string vm1.localdomain" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'No configuration'" | debconf-set-selections
apt install -y rkhunter postfix
sed -i 's/^WEB_CMD="\\/bin\\/false"/#WEB_CMD="\\/bin\\/false"/' /etc/rkhunter.conf
rkhunter --update
rkhunter --propupd -y
rkhunter --check --skip-keypress

cp /vagrant/archivator.sh /home/vagrant
chmod +x /home/vagrant/archivator.sh
echo "0 0 * * * root /home/vagrant/archivator.sh" >> "/etc/crontab"
