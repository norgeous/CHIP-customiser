#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

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
cat <<EOF > /var/www/router.admin/index.html
<!DOCTYPE html>
<html>
<head>
  <title>router.admin</title>
  <style>a{display:block; width:80%; text-align:center; font-size:100px; background:#bada55; box-sizing:border-box; padding:40px; margin:40px auto; text-decoration:none; color:white;}</style>
</head>
<body>
  <a href="/" onclick="javascript:event.target.port=8080">pihole</a>
  <a href="/" onclick="javascript:event.target.port=3000">wetty</a>
  <a href="/" onclick="javascript:event.target.port=8765">motioneye</a>
</body>
</html>
EOF

systemctl restart nginx


#list open ports
netstat -t4lpn | grep LISTEN | sed "s/\s\s*/ /g" | cut -d' ' -f4,7 | sed 's/0\.0\.0\.0://g'