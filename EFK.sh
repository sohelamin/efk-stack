#/bin/bash
echo -n "Enter EFK Server's Domain/IP: "
read domain
echo -n "Enter Kibana UI Password: "
read kibanapassword

# Update the system
sudo apt-get update

# Install java
sudo apt-get update
sudo apt-get install default-jdk -y

# Add elasticsearch package source
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update

# Install elasticsearch
sudo apt-get install elasticsearch -y
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service

# Install kibana
sudo apt-get install kibana -y
sudo systemctl daemon-reload
sudo systemctl enable kibana.service
sudo systemctl restart kibana.service

# Install & configure nginx
sudo apt-get -y install nginx -y
cat <<EOC | sudo su
cat <<EOT > /etc/nginx/sites-available/default
server {
    listen 80;

    server_name $domain;

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \\\$host;
        proxy_cache_bypass \\\$http_upgrade;
    }
}
EOT
exit
EOC
echo "admin:`openssl passwd -apr1 $kibanapassword`" | sudo tee -a /etc/nginx/htpasswd.users
sudo systemctl restart nginx

# Install & configure fluentd
curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-bionic-td-agent4.sh | sh

cat <<EOC | sudo su
cat <<EOT > /etc/td-agent/td-agent.conf
<source>
  @type http
  @id input_http
  port 8888
</source>

<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<match *.**>
  type copy
  <store>
    type elasticsearch
    host localhost
    port 9200
    include_tag_key true
    tag_key @log_name
    logstash_format true
    flush_interval 10s
  </store>
</match>
EOT
exit
EOC

sudo systemctl restart td-agent
