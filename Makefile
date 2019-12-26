.ONESHELL:
srcdir=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

default: install

install: \
	dotfiles \
	/usr/sbin/nginx \
	/etc/nginx/sites-enabled/default \
	/usr/bin/unzip \
	/usr/bin/certbot

/usr/bin/certbot: /usr/bin/add-apt-repository /etc/apt/sources.list.d/certbot-ubuntu-certbot-bionic.list
	apt-get install python-certbot-nginx
	touch $@
	@echo Add this to crontab:
	@echo
	@echo '    17 7 * * * certbot renew --post-hook "systemctl reload nginx"'

/etc/apt/sources.list.d/certbot-ubuntu-certbot-bionic.list:
	add-apt-repository ppa:certbot/certbot
	apt-get update
	touch $@

/usr/bin/add-apt-repository:
	apt-get install software-properties-common
	touch $@

/usr/sbin/nginx:
	apt-get install nginx

/etc/nginx/sites-enabled/default:
	ln -svf $(srcdir)etc/nginx/sites-enabled/default $@

/usr/bin/unzip:
	apt-get install unzip

DOTFILES=\
	.bashrc \
	.bash_aliases \
	.bashrc_local \
	.gitconfig \
	.droppy

dotfiles:
	for f in $(DOTFILES); do
		ln -vfs $(srcdir)$$f ~/
	done

SITE_ROOT=/var/www/site/

start: start-droppy

start-droppy:
	/usr/local/bin/droppy start \
		--configdir /root/.droppy/config/ \
		--filesdir $(SITE_ROOT) \
		--daemon

restart-droppy:
	pkill droppy
	make start

check-npm-outdates:
	npm outdated -global

new-ssl-certificate:
	# - Comment out SSH-related lines in nginx config
	# - Add server config in nginx
	#
	# and then
	#
	#   certbot certonly --nginx
	#
