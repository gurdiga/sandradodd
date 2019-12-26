.ONESHELL:
srcdir=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

default: install
install: \
	dotfiles \
	nginx

nginx: /usr/sbin/nginx /etc/nginx/sites-enabled/default

/usr/sbin/nginx:
	apt-get install nginx

/etc/nginx/sites-enabled/default:
	ln -svf $(srcdir)etc/nginx/sites-enabled/default $@

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
