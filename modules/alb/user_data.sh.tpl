#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1
set -x

sudo unlink  /opt/conda/envs/python2-default/bin/python

sudo ln -s /opt/conda/envs/python-default/bin/python3.11 /opt/conda/envs/python-default/bin/python

sudo echo 'export PATH="/opt/conda/envs/python-default/bin/:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Run the hostname setup script
python3 /opt/pv/sources/set_hostname.py "${base_hostname}" "${domain}" 

source /etc/environment


export base_hostname="${base_hostname}"
export domain="${domain}"
export console_name="${console_name}"

# Get the new hostname
new_hostname="$CONSOLE_HOSTNAME"

# Update the Name tag to reflect the new hostname
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Hostname,Value=$new_hostname
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value="$console_name-$new_hostname"

# Fetching the artifacts from artifactory

curl -O https://artifacts.pvgroup.intranet/artifactory/test-canary-local/terraform-svn/1.0.0-SNAPSHOT/terraform-svn-1.0.0-SNAPSHOT.zip
mkdir -p /terraform-svn
unzip terraform-svn-1.0.0-SNAPSHOT.zip -d /terraform-svn
cd /terraform-svn
cd modules/alb
# Run the Ansible playbook
ansible-playbook install.yaml \
  -e "swap_size_mb=2048 wildcard_certificate_pfx=${wildcard_certificate_pfx_secret} track_id=${track} region=${region}" -e "efs_host=${efs_host}"  -e "prod_server_names=${prod_server_names}"  -e "environment_abbreviation=${environment_abbreviation}"

sudo reboot
