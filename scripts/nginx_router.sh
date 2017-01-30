#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# debian 9 stretch repo (contains php7 arm)
#echo "deb http://ftp.us.debian.org/debian stretch main contrib non-free" | tee /etc/apt/sources.list.d/stretch.list

# pin jessie (prevent auto update to stretch packages)
#cat <<EOF > /etc/apt/preferences
#Package: *
#Pin: release n=jessie
#Pin-Priority: 600
#EOF

# update (needed after adding the stretch repo)
#apt update

# list open files (for port grabbing later)
apt install -y lsof

# php (from debian 9 stretch repo)
#apt install -t stretch -y php-fpm php-xml
apt install -y php-fpm php-xml

# nginx
apt install -y nginx

# nginx config
sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/g' /etc/nginx/nginx.conf
sed -i 's/# server_tokens off;/server_tokens off;/g' /etc/nginx/nginx.conf

# config default site with proxypass to local services
cat <<EOF > /etc/nginx/sites-enabled/default

# proxy all connections from 80 to 8080 for pihole (except for the domains listed below)
server {
  listen              80 default_server;
  listen              [::]:80 default_server;
  #listen              443 ssl;
  #listen              [::]:443 ssl;
  server_name         "";
  allow               192.168.0.0/16;
  deny                all;
  location / {
    proxy_set_header    Host \$host;
    proxy_set_header    X-Real-IP \$remote_addr;
    proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto \$scheme;
    proxy_pass          http://127.0.0.1:8080;
  }
}

server {
  listen              80;
  listen              [::]:80;
  server_name         router.admin 192.168.*;
  root                /var/www/router.admin;
  allow               192.168.0.0/16;
  deny                all;
  autoindex           on;
  index               index.php;
  location ~ \.php$ {
    include             snippets/fastcgi-php.conf;
    fastcgi_pass        unix:/run/php/php7.0-fpm.sock;
  }
  location ~ /\.ht {
    deny                all;
  }
}

EOF

# router homepage
mkdir /var/www/router.admin
cat <<EOF > /var/www/router.admin/index.php
<?php
if(isset(\$_GET['cmd']) && !empty(\$_GET['cmd'])){
  switch(\$_GET['cmd']){
    case 'reboot': shell_exec('sudo reboot'); break;
    case 'shutdown': shell_exec('sudo shutdown -h now'); break;
  }
}
?><!DOCTYPE html>
<html>
<head>
  <title><?php echo gethostname(); ?> (<?php echo \$_SERVER['HTTP_HOST']; ?>)</title>
  <style>
  body{background:black; font-family:arial; color:white;}
  h1{text-align:center;}
  a{display:block; text-align:center; font-size:20px; background:#bada55; box-sizing:border-box; padding:10px; margin:5px auto; text-decoration:none; color:black;}
  </style>
</head>
<body>
  <h1><?php echo gethostname(); ?> (<?php echo \$_SERVER['HTTP_HOST']; ?>)</h1>
  <a href="#" onclick="(function(){var xhr = new XMLHttpRequest(); xhr.open('GET','/?cmd=reboot',true); xhr.send('');})(event, this)">reboot</a>
  <a href="#" onclick="(function(){var xhr = new XMLHttpRequest(); xhr.open('GET','/?cmd=shutdown',true); xhr.send('');})(event, this)">shutdown</a>
  <?php \$openports = explode("\n", trim(shell_exec("sudo lsof -i -P | grep 'LISTEN' | grep '*:' | sed 's|:| |g;s|\s\s*| |g' | cut -d' ' -f1,10 | awk '{t=\$1;\$1=\$2;\$2=t;print;}' | sort -n | uniq"))); ?>
  <?php foreach (\$openports as \$portinfo): ?>
    <?php \$info = explode(" ", \$portinfo); ?>
    <a href="http://<?php echo \$_SERVER['HTTP_HOST']; ?>:<?php echo \$info[0]; ?>/">
      <?php echo \$info[1]; ?> (<?php echo \$info[0]; ?>)
    </a>
  <?php endforeach; ?>
</body>
</html>
EOF

# sudoers for www-data access to shutdown and reboot
cat <<EOF > /etc/sudoers.d/nginx
www-data ALL=NOPASSWD: /sbin/poweroff, /sbin/reboot, /sbin/shutdown, /usr/bin/lsof
EOF

systemctl restart nginx
