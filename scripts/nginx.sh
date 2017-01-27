#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# debian 9 stretch repo (contains php7 arm)
echo "deb http://ftp.us.debian.org/debian stretch main contrib non-free" | tee /etc/apt/sources.list.d/stretch.list

# pin jessie (prevent auto update to stretch packages)
cat <<EOF > /etc/apt/preferences
Package: *
Pin: release n=jessie
Pin-Priority: 600
EOF

# update (needed after adding the stretch repo)
apt update

# php (from debian 9 stretch repo)
apt install -t stretch -y php-fpm php-xml

# nginx
apt install -y nginx

# nginx config
sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/g' /etc/nginx/nginx.conf
sed -i 's/# server_tokens off;/server_tokens off;/g' /etc/nginx/nginx.conf

# config default site with proxypass to local services
cat <<EOF > /etc/nginx/sites-enabled/default
server {

    server_name             "";
    root                    /var/www/router.admin;
    listen                  80 default_server;
    listen                  [::]:80 default_server;
    allow                   192.168.0.0/16;
    deny                    all;
    autoindex               on;
    location ~ \.php$ {
      include snippets/fastcgi-php.conf;
      fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }

    location ~ /\.ht {
      deny all;
    }

    #location /pihole/ {
    #    proxy_set_header        Host 127.0.0.1;
    #    proxy_set_header        X-Real-IP \$remote_addr;
    #    proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
    #    proxy_set_header        X-Forwarded-Proto \$scheme;
    #    proxy_pass              http://localhost:8080/admin/;
    #}

}
EOF

# router homepage
mkdir /var/www/router.admin
cat <<EOF > /var/www/router.admin/index.php
<!DOCTYPE html>
<html>
<head>
  <title>router.admin</title>
  <style>a{display:block; width:80%; text-align:center; font-size:30px; background:#bada55; box-sizing:border-box; padding:20px; margin:20px auto; text-decoration:none; color:white;}</style>
</head>
<body>
  <?php
    \$openports = preg_split('/\s+/', trim(shell_exec('netstat -tulpn | grep LISTEN | sed "s|\s\s*| |g;s|0\.0\.0\.0:||g;s/:::||g;s|/| |g" | cut -d" " -f4 | sort -n | uniq')));
    foreach (\$openports as \$port) {
      echo '<a href="/" onclick="javascript:event.target.port='.\$port.'">port '.\$port.'</a>';
    }
  ?>
</body>
</html>
EOF

systemctl restart nginx


#list open ports
netstat -tulpn | grep LISTEN | sed "s/\s\s*/ /g;s/0\.0\.0\.0://g;s/::://g;s|/| |g" | cut -d" " -f4,8 | sort -n | uniq
