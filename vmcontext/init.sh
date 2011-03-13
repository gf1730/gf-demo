#!/bin/bash

if [ -f /mnt/context.sh ]; then
  . /mnt/context.sh
fi

CTIER_HOST=mmsbnectl01
CTIER_FQDN=mmsbnectl01.root.tequinox.com
CTIER_IP=192.55.198.10

# Create ctier user and gerenate SSH keys
/bin/egrep  -i "^${VM_USERNAME}" /etc/passwd >/dev/null 2>&1
if [ $? -eq 1 ]; then
   echo "Adding user ${VM_USERNAME}"
   /usr/sbin/useradd -c "ControlTier Administrator" -m -s /bin/bash -p '$1$xMU2E/ju$HBiyh7bSaz5ldIZ6ZcIb0/' ${VM_USERNAME}
   /bin/su -l -c "/usr/bin/ssh-keygen -q -t dsa -f ~/.ssh/id_dsa -P \"\"" ${VM_USERNAME}
   /bin/su -l -c "/bin/cat /mnt/ctier.id_dsa.pub >> ~/.ssh/authorized_keys" ${VM_USERNAME}
   /bin/su -l -c "/bin/chmod 600 ~/.ssh/authorized_keys" ${VM_USERNAME}
fi

# RHEL
if [ -f /etc/redhat-release ]; then

   # Confiugre networking
   /bin/egrep -i "^IPADDR=${VM_ETH0_IPADDR}" /etc/sysconfig/network-scripts/ifcfg-eth0 >/dev/null 2>&1
   if [ $? -eq 1 ]; then
      echo "Configuring network interface: eth0"
      /sbin/ifdown eth0

      # /etc/sysconfig/network-scripts/ifcfg-eth0
      /bin/echo -e "BOOTPROTO=none\nDEVICE=eth0\nDNS1=${VM_ETH0_DNS1}\nDNS2=${VM_ETH0_DNS2}\nGATEWAY=${VM_ETH0_GATEWAY}" > /tmp/ifcfg-eth0
      /bin/egrep -i "^HWADDR" /etc/sysconfig/network-scripts/ifcfg-eth0 >> /tmp/ifcfg-eth0
      /bin/echo -e "IPADDR=${VM_ETH0_IPADDR}\nNETMASK=${VM_ETH0_NETMASK}\nONBOOT=yes\nPEERDNS=yes\nUSERCTL=no" >> /tmp/ifcfg-eth0
      /bin/mv -f /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.bak
                /bin/mv /tmp/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0

      # /etc/sysconfig/network
      /bin/echo -e "NETWORKING=yes\nNETWORKING_IPV6=no\nHOSTNAME=${VM_HOSTNAME}.${VM_DOMAIN}" > /tmp/network
      /bin/mv -f /etc/sysconfig/network /etc/sysconfig/network.bak
      /bin/mv /tmp/network /etc/sysconfig/network

      # /etc/hosts
      /bin/echo -e "${VM_ETH0_IPADDR}\t${VM_HOSTNAME}.${VM_DOMAIN}\t${VM_HOSTNAME}" > /tmp/hosts
      /bin/grep "localhost" /etc/hosts >> /tmp/hosts
      /bin/echo -e "\n# MMS BNE ControlTier Instance\n${CTIER_IP}\t${CTIER_FQDN}\t${CTIER_HOST}" >> /tmp/hosts
      /bin/mv -f /etc/hosts /etc/hosts.bak
      /bin/mv /tmp/hosts /etc/hosts
      /bin/hostname ${VM_HOSTNAME}.${VM_DOMAIN}

      /sbin/ifup eth0
      # /etc/resolv.conf
      echo "Updating /etc/resolv.conf"
      /bin/echo -e "search ${VM_SEARCH}" > /tmp/resolv.conf
      /bin/grep "nameserver" /etc/resolv.conf >> /tmp/resolv.conf
      /bin/mv -f /etc/resolv.conf /etc/resolv.conf.bak
      /bin/mv /tmp/resolv.conf /etc/resolv.conf
   fi

   # /etc/yum.repos.d/cteir.repo
   if [ ! -f /etc/yum.repos.d/ctier.repo ]; then
      echo "Adding ctier repo"
      /bin/cp /mnt/ctier.repo /etc/yum.repos.d/ctier.repo
      /bin/chown 644 /etc/yum.repos.d/ctier.repo
      /usr/bin/yum clean all >/dev/null 2>&1
      /usr/bin/yum makecache >/dev/null 2>&1 &
   fi

   # Configure NTP
   if [ -f /etc/ntp.conf ]; then

      for NTPSERVER in $VM_NTP1 $VM_NTP2; do

         echo "Adding NTP Server: $NTPSERVER"
         grep -ic "server $NTPSERVER" /etc/ntp.conf >/dev/null 2>&1
         if [ $? -ne 0 ]; then
            echo "" >> /etc/ntp.conf
            echo "server $NTPSERVER" >> /etc/ntp.conf
         fi

         grep -ic "restrict $NTPSERVER" /etc/ntp.conf >/dev/null 2>&1
         if [ $? -ne 0 ]; then
            echo "restrict $NTPSERVER mask 255.255.255.255 nomodify notrap noquery" >> /etc/ntp.conf
         fi

      done
   fi

   # Configure TimeZone
   if [ ! -z "${TIMEZONE}" ] && [ -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
      echo "Setting Time Zone: $TIMEZONE"
      /bin/ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
      /bin/sed -i "s#^ZONE.*#ZONE=\"${TIMEZONE}\"#" /etc/sysconfig/clock
   fi

fi
