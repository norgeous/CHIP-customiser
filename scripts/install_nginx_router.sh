#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

if (whiptail --title "Install nginx" --yesno "Install nginx with router page?" 15 46) then

apt install -y lsof php5-fpm nginx

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
    try_files           \$uri =404;
    fastcgi_pass        unix:/var/run/php5-fpm.sock;
    fastcgi_index       index.php;
    fastcgi_param       SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include             fastcgi_params;
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
  a.system{background:aqua;}
  </style>
</head>
<body>
  <h1><?php echo gethostname(); ?> (<?php echo \$_SERVER['HTTP_HOST']; ?>)</h1>
  <a href="#" class="system" onclick="(function(){var xhr = new XMLHttpRequest(); xhr.open('GET','/?cmd=reboot',true); xhr.send('');})(event, this)">reboot</a>
  <a href="#" class="system" onclick="(function(){var xhr = new XMLHttpRequest(); xhr.open('GET','/?cmd=shutdown',true); xhr.send('');})(event, this)">shutdown</a>
  <?php 
    \$enumerated = [];
    \$listening = explode("\n", trim(shell_exec("sudo lsof -i -P | grep 'LISTEN' | grep '*:' | sed 's|:| |g;s|\s\s*| |g' | cut -d' ' -f1,2,10 | uniq")));
    foreach (\$listening as \$processinfo) {
      \$info = explode(" ", \$processinfo);
      if (! array_key_exists(\$info[0].\$info[2], \$enumerated)) {
        \$enumerated[\$info[0].\$info[2]] = [
          "name" => \$info[0],
          "pid" => \$info[1],
          "port" => \$info[2],
          "cmd" => trim(shell_exec("cat /proc/".\$info[1]."/cmdline | xargs -0 echo"))
        ];
      }
    }
  ?>

  <?php foreach (\$enumerated as \$label => \$info): ?>
    <a href="http://<?php echo \$_SERVER['HTTP_HOST']; ?>:<?php echo \$info['port']; ?>/" title="<?php echo \$info['cmd']; ?> ">
      <?php echo \$info['name']; ?> (<?php echo \$info['port']; ?>)
      
    </a>
  <?php endforeach; ?>
</body>
</html>
EOF

# sudoers for www-data access to shutdown and reboot
cat <<EOF > /etc/sudoers.d/nginx
www-data ALL=NOPASSWD: /sbin/poweroff, /sbin/reboot, /sbin/shutdown, /usr/bin/lsof
EOF

systemctl restart nginx php5-fpm

fi
