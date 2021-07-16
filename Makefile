.ONESHELL:
SHELL=/bin/bash

srcdir=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

NODE=/root/.nvm/versions/node/v14.16.1/bin/node
NPM=/root/.nvm/versions/node/v14.16.1/bin/npm
DROPPY_EXECUTABLE=./node_modules/.bin/droppy
DROPPY=$(NODE) $(DROPPY_EXECUTABLE)

default:
	@echo make what?

update:
	apt-get update \
		&& apt-get upgrade \
		&& apt-get dist-upgrade \
		&& apt-get autoremove
	npm update --global --production

check-nginx-config:
	nginx -t

install: \
	dotfiles \
	/usr/sbin/nginx \
	/etc/nginx/sites-enabled/default \
	/etc/logrotate.d/droppy \
	/usr/bin/unzip \
	/usr/bin/certbot \
	$(DROPPY_EXECUTABLE) \
	/usr/bin/recode \
	/usr/bin/uchardet \
	/usr/bin/htop

/usr/bin/htop:
	apt-get install htop

/usr/bin/uchardet:
	apt-get install uchardet

/usr/bin/recode:
	apt-get install recode

$(DROPPY_EXECUTABLE):
	npm install
	touch $@
	@echo Add something like this to crontab:
	@echo '    @reboot cd sandradodd && make start-droppy'

$(NODE):
	@echo 'Use nvm to install the latest LTS Node.'

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

/etc/logrotate.d/droppy:
	ln -svf $(srcdir)etc/logrotate.d/droppy $@

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

start-droppy:
	$(DROPPY) start \
		--configdir /root/.droppy/config/ \
		--filesdir $(SITE_ROOT) \
		--log /var/log/droppy.log \
		--daemon

stop-droppy:
	pkill -F $$HOME/.droppy/config/droppy.pid

restart-droppy: stop-droppy start-droppy

restart-nginx:
	systemctl restart nginx

reset-droppy-password:
	@read -p "New password for sandra: " password; \
	$(DROPPY) add sandra "$$password" p
	make restart-droppy

reset-droppy-password-holly:
	@read -p "New password for HollyDodd: " password; \
	$(DROPPY) add HollyDodd "$$password" p
	make restart-droppy

check-npm-outdates:
	@$(NPM) outdated --depth 99

new-ssl-certificate:
	# - Comment out SSH-related lines in nginx config
	# - Add server config in nginx
	#
	# and then
	#
	#   certbot certonly --nginx
	#

logs:
	du -sh /var/log
	du -sh /var/log/* | sort -rh | head

email: smtp
smtp:
	# https://hakanu.net/linux/2017/04/23/making-crontab-send-email-through-mailgun/

commit-changes:
	@cd /var/www/site/
	git add .
	if ! git diff-index --quiet HEAD --; then
		git commit -m "`date`"
		git push
	fi
