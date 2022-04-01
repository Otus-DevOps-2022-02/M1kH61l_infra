ssh -i ~/.ssh/appuser -A -t appuser@51.250.65.56 ssh 10.128.0.14

sudo nano /etc/hosts
51.250.65.56 bastion
10.128.0.14 someinternalhost

host someinternalhost
        ProxyJump appuser@bastion
        IdentityFile ~/.ssh/appuser
        User appuser
        Port 22

bastion_IP = 51.250.65.56
someinternalhost_IP = 10.128.0.14
