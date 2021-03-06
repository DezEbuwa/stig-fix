#!/bin/bash

## (GEN005500: CAT I) (Previously – G701) The IAO and SA will ensure SSH 
## Protocol version 1 is not used, nor will Protocol version 1 compatibility 
## mode be used.
echo '==================================================='
echo ' Patching GEN005500: Disallow SSH Protocol version 1'
echo '==================================================='
if [ `grep -c "^Protocol" /etc/ssh/sshd_config` -gt 0 ]; then
	sed -i "/^Protocol/ c\Protocol 2" /etc/ssh/sshd_config
else
	echo "Protocol 2" >> /etc/ssh/sshd_config
fi

if [ `grep -c "^Ciphers" /etc/ssh/sshd_config` -gt 0 ]; then
	sed -i "/Ciphers/d" /etc/ssh/sshd_config
	echo 'Ciphers aes256-ctr,aes192-ctr,aes128-ctr' >> /etc/ssh/sshd_config
else
	echo 'Ciphers aes256-ctr,aes192-ctr,aes128-ctr' >> /etc/ssh/sshd_config
fi

if [ `grep -c "^MACs" /etc/ssh/sshd_config` -gt 0 ]; then
	sed -i "/MACs/d" /etc/ssh/sshd_config
	echo 'MACs hmac-sha1' >> /etc/ssh/sshd_config
else
        echo 'MACs hmac-sha1' >> /etc/ssh/sshd_config
fi

if [ `grep -c "^Banner" /etc/ssh/sshd_config` -gt 0 ]; then
	sed -i "/^Banner/ c\Banner /etc/issue" /etc/ssh/sshd_config
else
	echo 'Banner /etc/issue' >> /etc/ssh/sshd_config
fi
