#!/bin/bash

install_wordpress() {
    WORDPRESS_VERSION=$1
    WORDPRESS_DIR=$2
    WORDPRESS_URL=$3

    WEBSITE_TITLE=$4

    DATABASE_NAME=$5
    MYSQL_USER=$6
    MYSQL_PASSWORD=$7

    local admin_user=$8
    local admin_password=$9
    local admin_email=${10}

    echo "Commencing $WEBSITE_TITLE Setup"

    # Make a database, if we don't already have one
    echo "Creating database (if it's not already there)"
    mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME"
    mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO $MYSQL_USER@localhost IDENTIFIED BY '$MYSQL_PASSWORD';"

    # Check for the presence of a `htdocs` folder.
    if [ ! -d $WORDPRESS_DIR ]; then
        download_wordpress $WORDPRESS_VERSION $WORDPRESS_DIR
    elif [ "$WORDPRESS_VERSION" == "latest" ]; then
        upgrade_wordpress $WORDPRESS_DIR
    fi

    if [ ! -f "$WORDPRESS_DIR/wp-config.php" ] || ! $(noroot wp core is-installed --path=$WORDPRESS_DIR); then
        configure_wordpress $WORDPRESS_DIR $DATABASE_NAME $MYSQL_USER $MYSQL_PASSWORD $WORDPRESS_URL "$WEBSITE_TITLE" $admin_user $admin_password $admin_email
    fi

    # Let the user know the good news
    echo "$WEBSITE_TITLE is now installed";
    echo ""
}

download_wordpress() {
    local wordpress_version=$1
    local wordpress_dir=$2

    mkdir -p $wordpress_dir
    cd $wordpress_dir

    echo "Downloading WordPress $wordpress_version using WP-CLI"
    noroot wp core download --version=$wordpress_version

    cd $OLDPWD
}

upgrade_wordpress() {
    local wordpress_idr=$1

    cd $wordpress_idr

    echo "Updating WordPress using WP-CLI"
    noroot wp core upgrade

    cd $OLDPWD
}

configure_wordpress() {
    local wordpress_dir=$1
    local db_name=$2
    local mysql_user=$3
    local mysql_password=$4
    local wordpress_url=$5
    local website_title=$6
    local admin_user=$7
    local admin_password=$8
    local admin_email=$9

    cd $wordpress_dir

    # Use WP CLI to create a `wp-config.php` file
    if [ ! -f "wp-config.php" ]; then
        noroot wp core config --dbname="$db_name" --dbuser=$mysql_user --dbpass=$mysql_password --dbhost="localhost" --extra-php <<PHP
// Match any requests made via xip.io.
if ( isset( \$_SERVER['HTTP_HOST'] ) && preg_match('/^(local.wordpress.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(.xip.io)\z/', \$_SERVER['HTTP_HOST'] ) ) {
    define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
    define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
}

define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'SAVEQUERIES', true );
PHP

    fi

    if ! $(noroot wp core is-installed); then
        # Use WP CLI to install WordPress
        noroot wp core install --url=$wordpress_url --title="$website_title" --admin_user=$admin_user --admin_password="$admin_password" --admin_email=$admin_email
    fi

    cd $OLDPWD
}
