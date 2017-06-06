#!/bin/bash

wordpress_version=`get_config_value 'wp_version' 'latest'`

website_domain=`get_primary_host "${VVV_SITE_NAME}".dev`
website_title=`get_config_value 'site_title' "${website_domain}"`

admin_user=admin
admin_password=password
admin_email="admin@$website_domain"

database_name=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
database_name=${database_name//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}
mysql_user=wp
mysql_password=wp

repo_dir="${VVV_PATH_TO_SITE}/source"
htdocs_dir="${VVV_PATH_TO_SITE}/htdocs"

wordpress_dir="$htdocs_dir/$wordpress_version"
wordpress_url="$website_domain/$wordpress_version"

source provision.sh

install_wordpress $wordpress_version $wordpress_dir $wordpress_url "$website_title" $database_name $mysql_user $mysql_password $admin_user $admin_password $admin_email

cp "${VVV_PATH_TO_SITE}/provision/vvv-nginx.sample" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
sed -i "s#{vvv_server_name}#$website_domain#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
echo $website_domain > "${VVV_PATH_TO_SITE}/provision/vvv-hosts"
