.ONESHELL:
srcdir=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

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
	/usr/bin/unzip \
	/usr/bin/certbot \
	/usr/local/bin/droppy \
	/usr/bin/recode \
	/usr/bin/uchardet \
	/usr/bin/htop

/usr/bin/htop:
	apt-get install htop

/usr/bin/uchardet:
	apt-get install uchardet

/usr/bin/recode:
	apt-get install recode

/usr/local/bin/droppy: /usr/bin/node
	npm install --global --production droppy
	touch $@
	@echo Add something like this to crontab:
	@echo '    @reboot cd sandradodd && make start-droppy'

/usr/bin/node:
	apt-get install nodejs

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

start-droppy:
	/root/.nvm/versions/node/v12.18.4/bin/droppy start \
		--configdir /root/.droppy/config/ \
		--filesdir $(SITE_ROOT) \
		--daemon
stop-droppy:
	pkill -F $$HOME/.droppy/config/droppy.pid

restart-droppy: stop-droppy start-droppy

restart-nginx:
	systemctl restart nginx

reset-droppy-password:
	@read -p "New password for sandra: " password; \
	droppy add sandra "$$password" p
	make restart-droppy

reset-droppy-password-holly:
	@read -p "New password for HollyDodd: " password; \
	droppy add HollyDodd "$$password" p
	make restart-droppy

check-npm-outdates:
	@npm outdated -global

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
