#!/bin/bash
# Emercoin Wallet Installation Script for Ubuntu

if [ `whoami` != 'root' ]; then echo "Run me as root"; exit 1; fi
getent passwd emc >/dev/null && { echo "User 'emc' already exists"; exit 1; }

apt-get -y install wget pwgen openssl

wget http://pilotfiber.dl.sourceforge.net/project/emercoin/0.5.1/emercoin-0.5.1-linux64.tar.gz
tar xvzf emercoin-0.5.1-linux64.tar.gz
rm emercoin-0.5.1-linux64.tar.gz
cp emercoin-0.5.1-linux64/bin/64/emercoind /usr/local/bin
rm -rf emercoin-0.5.1-linux64

mkdir /tmp/emcskel
groupadd --gid 500 emc
useradd -m -d /var/lib/emc -k /tmp/emcskel -s /bin/false --uid 500 --gid 500 emc
rmdir /tmp/emcskel

mkdir -p /var/lib/emc/ssl
openssl req -nodes -x509 -newkey rsa:4096 -keyout /var/lib/emc/ssl/emercoin.key -out /var/lib/emc/ssl/emercoin.crt -days 3560 -subj /C=US/ST=Oregon/L=Portland/O=IT/CN=emercoin.local

mkdir -p /var/lib/emc/.emercoin
cat<<EOF >/var/lib/emc/.emercoin/emercoin.conf
rpcuser=emccoinrpc
rpcpassword=`pwgen 50 1`
listen=1
server=1
rpcallowip=*
rpcport=6662
maxconnections=80
gen=0
daemon=1
rpcssl=1
rpcsslcertificatechainfile=/var/lib/emc/ssl/emercoin.crt
rpcsslprivatekeyfile=/var/lib/emc/ssl/emercoin.key
rpcsslciphers=HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4:!SSLv2
EOF

chmod 600 /var/lib/emc/.emercoin/emercoin.conf
chown -R emc.emc /var/lib/emc/.emercoin

cat<<EOF >/usr/local/bin/emc
#!/bin/sh
if [ ! \$1 ]; then
  echo "Usage $0 <options>"
  echo "Please ensure you are allowed to run the sudo"
  exit 1
fi
sudo -u emc emercoind -datadir=/var/lib/emc/.emercoin \$*
EOF
chmod +x /usr/local/bin/emc

wget https://dl.dropboxusercontent.com/u/15852900/emercoin/emercoind.initd
mv emercoind.initd /etc/init.d/emercoind
chmod +x /etc/init.d/emercoind
update-rc.d emercoind defaults
