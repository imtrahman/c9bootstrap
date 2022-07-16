#!/bin/bash
date
touch /tmp/bootstrap.txt
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.UTF-8 >> /etc/environment
. /home/ec2-user/.bashrc
yum -y remove aws-cli >> /tmp/bootstrap.txt 
yum -y install sqlite telnet jq strace tree gcc glibc-static python3 python3-pip gettext bash-completion wget >> /tmp/bootstrap.txt

echo '=== CONFIGURE default python version ===' >> /tmp/bootstrap.txt
PATH=$PATH:/usr/bin 
alternatives --set python /usr/bin/python3.6 >> /tmp/bootstrap.txt

echo '=== INSTALL and CONFIGURE default software components ===' >> /tmp/bootstrap.txt
sudo -H -u ec2-user bash -c "pip install --upgrade pip" >> /tmp/bootstrap.txt
sudo -H -u ec2-user bash -c "pip install --user -U boto boto3 botocore awscli aws-sam-cli yq" >> /tmp/bootstrap.txt

echo '=== CONFIGURE awscli and setting ENVIRONMENT VARS ===' >> /tmp/bootstrap.txt
echo "complete -C '/usr/local/bin/aws_completer' aws" >> /home/ec2-user/.bashrc >> /tmp/bootstrap.txt
mkdir /home/ec2-user/.aws >> /tmp/bootstrap.txt

echo '[default]' > /home/ec2-user/.aws/config >> /tmp/bootstrap.txt
echo 'output = json' >> /home/ec2-user/.aws/config >> /tmp/bootstrap.txt

chmod 600 /home/ec2-user/.aws/config && chmod 600 /home/ec2-user/.aws/credentials >> /tmp/bootstrap.txt

echo 'PATH=$PATH:/usr/local/bin' >> /home/ec2-user/.bashrc >> /tmp/bootstrap.txt
echo 'export PATH' >> /home/ec2-user/.bashrc >> /tmp/bootstrap.txt
echo '=== CLEANING /home/ec2-user ===' >> /tmp/bootstrap.txt

for f in cloud9; do rm -rf /home/ec2-user/$f; done >> /tmp/bootstrap.txt

        chown -R ec2-user:ec2-user /home/ec2-user/ >> /tmp/bootstrap.txt

        echo '=== PREPARE REBOOT in 1 minute with at ===' >> /tmp/bootstrap.txt

        FILE=$(mktemp) && echo $FILE && echo '#!/bin/bash' > $FILE && echo 'reboot -f --verbose' >> $FILE && at now + 1 minute -f $FILE 

        echo "Bootstrap completed with return code $?" >> /tmp/bootstrap.txt