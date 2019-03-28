#!/usr/bin/env bash

if ! type "composer" &>/dev/null; then
    # Install Composer
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('sha384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    php -r "unlink('composer-setup.php');"
fi

if ! type "envoy" &>/dev/null; then
    # Install Envoy for Laravel and create symlink
    sudo -u vagrant -i sh -c 'composer global require laravel/envoy'
    ln -sfn /home/vagrant/.config/composer/vendor/bin/envoy /usr/local/bin/envoy
fi
