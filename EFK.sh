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
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
sudo apt-get install apt-transport-https -y
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
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
curl -fsSL https://toolbelt.treasuredata.com/sh/install-ubuntu-focal-td-agent4.sh | sh

cat <<EOC | sudo su
cat <<EOT > /etc/td-agent/td-agent.conf
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<match api.log>
  @type copy
  <store>
    @type elasticsearch
    host elasticsearch
    port 9200
    include_tag_key true
    tag_key @log_name
    logstash_format true
    logstash_prefix api.log
    flush_interval 10s
    @log_level debug
    user elastic
    password mysecret
  </store>
</match>
EOT
exit
EOC

sudo systemctl restart td-agent
