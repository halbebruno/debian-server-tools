#!/bin/bash --version
#
# Courier MTA.
#

# Locally generated mail (sendmail, SMTP, notifications)
#     MTA <-- sendmail
#     MTA <-- MUA@localhost
#     MTA <-- DSN
#
# Receiving from foreign hosts and as a 'smarthost' (inbound SMTP, SMTP-MSA)
#     MTA <-- Internet
#     MTA <-- Satellite systems (without authentication)
#     MTA <-- MUA (authenticated)
#
# Delivering to foreign hosts or 'smarthosts' or transactional email providers (outbound SMTP)
#     MTA --> Internet
#     MTA --> smarthosts
#     MTA --> transactional providers
#
# Forward to a foreign mailbox (SRS)
#     MTA --> another MTA
#
# Delivering to local mailboxes (accounts)
#     MTA --> MDA
#
# Fetching remote mailboxes (fetchmail)
#     MDA <-- remote MDA
#
# Reading mail in local mailboxes (IMAP)
#     MUA <-- MDA

exit 0

# Courier-mta message processing order on reception
#
# 1. SMTP communication
# 2. NOADD*, "opt MIME=none"
# 3. filters
# 4. DEFAULTDELIVERY

# ${D}/package/config-compare.sh

# gamin for courier-imap

# Mail Submission Agent (TCP/587)
editor esmtpd-msa
#     AUTH_REQUIRED=1
#     ADDRESS=0
#     ESMTPDSTART=YES
editor esmtpd
#     ESMTPAUTH=""
#     ESMTPAUTH_TLS="PLAIN LOGIN"

# IMAP only on localhost
# https://github.com/svarshavchik/courier/blob/master/courier/courier/module.esmtp/esmtpd-ssl.dist.in.git
editor imapd
#     ADDRESS=127.0.0.1
#     IMAP_CAPABILITY = add: AUTH=PLAIN
#     #IMAP_CAPABILITY_TLS=
#     #IMAP_EMPTYTRASH

# install courier-dhparams.sh

mkdir /etc/courier/esmtpacceptmailfor.dir
touch esmtpacceptmailfor

# authmodulelist="authuserdb"

# echo hosted-domain.hu > /etc/courier/hosteddomains
# mkdir mkdir /etc/courier/esmtpacceptmailfor.dir
# echo accepted-domain.hu > /etc/courier/esmtpacceptmailfor.dir/esmtpacceptmailfor
# touch /etc/courier/userdb && chmod 600 /etc/courier/userdb && makeuserdb

# authmysqlrc
DEFAULT_DOMAIN  szepe.net
MYSQL_SERVER            localhost
MYSQL_PORT              0
MYSQL_DATABASE          horde
MYSQL_USERNAME          courier
MYSQL_USER_TABLE        courier_horde
MYSQL_PASSWORD          <PASSWORD>

MYSQL_AUXOPTIONS_FIELD  options
MYSQL_CHARACTER_SET     utf8
MYSQL_CRYPT_PWFIELD     crypt
MYSQL_DEFAULTDELIVERY   defaultdelivery
MYSQL_GID_FIELD         gid
MYSQL_HOME_FIELD        home
MYSQL_LOGIN_FIELD       id
MYSQL_MAILDIR_FIELD     maildir
MYSQL_NAME_FIELD        name
MYSQL_OPT               0
MYSQL_QUOTA_FIELD       quota
MYSQL_UID_FIELD         uid

CREATE TABLE IF NOT EXISTS `passwords` (
  `id` char(128) CHARACTER SET latin1 NOT NULL,
  `crypt` char(128) CHARACTER SET latin1 NOT NULL,
  `clear` char(128) CHARACTER SET latin1 NOT NULL,
  `name` char(128) CHARACTER SET latin1 NOT NULL,
  `uid` int(10) unsigned NOT NULL DEFAULT '1',
  `gid` int(10) unsigned NOT NULL DEFAULT '1',
  `home` char(255) CHARACTER SET latin1 NOT NULL,
  `maildir` char(255) CHARACTER SET latin1 NOT NULL,
  `defaultdelivery` char(255) CHARACTER SET latin1 NOT NULL,
  `quota` char(255) CHARACTER SET latin1 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE `passwords`
  ADD UNIQUE KEY `id` (`id`);
# @TODO Test utf8.

# Privileges for `courierauthu`@`localhost`
GRANT USAGE ON *.* TO 'courierauthu'@'localhost' IDENTIFIED BY PASSWORD '*CA4FD4F77E14F2B60398B882C1020544D0CA9D9C';
GRANT SELECT ON `mail`.`passwords` TO 'courierauthu'@'localhost';

service courier-authdaemon restart

# Python Courier filters (python3)
apt-get install -y libpython2.7-dev libxml2-dev libxslt1-dev cython python-gdbm
pip2 install lxml html2text
#pip2 install courier-pythonfilter
# http://phantom.dragonsdawn.net/~gordon/courier-pythonfilter/

# Custom Python filters
git clone https://github.com/szepeviktor/courier-pythonfilter-custom
# /usr/local/lib/python${VERSION}
ln -sv email-correct.py /usr/local/lib/python2.7/dist-packages/pythonfilter/
ln -sv spamassassin3.py /usr/local/lib/python2.7/dist-packages/pythonfilter/
editor /etc/pythonfilter.conf
# log_mailfrom_rcptto
# noduplicates
# whitelist_auth
# whitelist_relayclients
# spamassassin3
# email-correct
ln -sv /usr/local/bin/pythonfilter /usr/lib/courier/filters
filterctl start pythonfilter

# MAXDELS - Maximum number of simultaneous delivery attempts
# http://www.courier-mta.org/queue.html
editor /etc/courier/module.esmtp

# Spamassassin
#     http://svn.apache.org/repos/asf/spamassassin/trunk/
editor /etc/default/spamassassin
#    OPTIONS="--create-prefs --max-children 2 --helper-home-dir --ipv4 --allow-tell --username=virtual --groupname=virtual --nouser-config --virtual-config-dir=/var/mail/.spamassassin"

# whitelist_to spamtrap@domain.tld
# Disable uribl.com checks
score URIBL_BLACK 0
score URIBL_RED 0
score URIBL_GREY 0
score URIBL_BLOCKED 0

# For DKIM check
apt-get install -y libmail-dkim-perl
# Pyzor
pip3 install pyzor

## Compile rules
#mkdir -p /var/lib/spamassassin/compiled && chmod -R go-w,go+rX /var/lib/spamassassin/
## Patch for being quiet
#cd /etc/cron.hourly
#patch -p0 < spamassassin34.patch

editor /etc/courier/smtpaccess/default
# :::1	allow,RELAYCLIENT

# Document: message way SMTP, courier C, courier filters (spamassassin, pyzor), aliases, .courier

# @TODO Where to whitelist: courier domain,IP; sa domain; dnsbl known_hosts;
#       What: own IP, servers, (smtp.timeweb.ru), broken SMTP servers
#             providers (ISP, bank, shared hosting, VPS, server, DNS, Incapsula/CloudFlare)
#             subscriptions, account (ifttt, linkedin, hubiC)
#             freemail?? (gmail, freemail, citromail, indamail)

editor /etc/spamassassin/local.cf
# host -t A worker.szepe.net
dns_server              81.2.236.171

# spammer.dnsbl, knownhosts.dnsbl

# Mail::SpamAssassin::Plugin::SAGrey (deprecated!)

# MISSING_MID monitoring

# maildrop: https://help.ubuntu.com/community/MailServerCourierSpamAssassin

# Scores
# @TODO Add descriptions

score RDNS_NONE                  3.0 -> spamassassin3.py rejects
score RDNS_DYNAMIC               2.0
score DYN_RDNS_AND_INLINE_IMAGE  3.0
score DNS_FROM_RFC_BOGUSMX       4.0

score SPF_HELO_FAIL              2.0
score FM_FAKE_HELO_HOTMAIL       2.0

score T_DKIM_INVALID             1.0

whitelist_from *@domain.tld

whitelist_to spamtrap@szepe.net
#whitelist_to other.spamtrap@domain.tld

# sagrey.pm?

# Log monitoring
#
# - MAIL_RECEPTION='courieresmtpd: error.*534 SIZE=Message too big\|courieresmtpd: error.*523 Message length .* exceeds administrative limit'
# - MAIL_FILER_EXCEPTION='courierfilter:.*xception'
# - MAIL_BROKEN='4[0-9][0-9]\s*tls\|Broken pipe'
# - weekly: grep "courieresmtpd: .*: 5[0-9][0-9] " "/var/log/mail.log.1" | grep -wv "554"
# - yearly: archive inbox and sent folders
# - monthly: top10-mailfolders.sh

# DNSBL (Spamassassin configuration)

# http://wiki.junkemailfilter.com/index.php/Spam_DNS_Lists#Spam_Assassin_Examples
ifplugin Mail::SpamAssassin::Plugin::DNSEval

header __RCVD_IN_HOSTKARMA eval:check_rbl('HOSTKARMA-lastexternal','hostkarma.junkemailfilter.com.')
describe __RCVD_IN_HOSTKARMA Sender listed in JunkEmailFilter
tflags __RCVD_IN_HOSTKARMA net

header RCVD_IN_HOSTKARMA_W eval:check_rbl_sub('HOSTKARMA-lastexternal', '127.0.0.1')
describe RCVD_IN_HOSTKARMA_W Sender listed in HOSTKARMA-WHITE
tflags RCVD_IN_HOSTKARMA_W net nice

header RCVD_IN_HOSTKARMA_BL eval:check_rbl_sub('HOSTKARMA-lastexternal', '127.0.0.2')
describe RCVD_IN_HOSTKARMA_BL Sender listed in HOSTKARMA-BLACK
tflags RCVD_IN_HOSTKARMA_BL net

header RCVD_IN_HOSTKARMA_BR eval:check_rbl_sub('HOSTKARMA-lastexternal', '127.0.0.4')
describe RCVD_IN_HOSTKARMA_BR Sender listed in HOSTKARMA-BROWN
tflags RCVD_IN_HOSTKARMA_BR net

score RCVD_IN_HOSTKARMA_W -5
score RCVD_IN_HOSTKARMA_BL 3.0
score RCVD_IN_HOSTKARMA_BR 1.0

endif

# @TODO add-domain.sh
info@%DOMAIN%:        admin@%DOMAIN%
abuse@%DOMAIN%:       admin@%DOMAIN%
spam@%DOMAIN%:        admin@%DOMAIN%
admin@%DOMAIN%:       admin@szepe.net
webmaster@%DOMAIN%:   admin@%DOMAIN%
postmaster@%DOMAIN%:  admin@%DOMAIN%
hostmaster@%DOMAIN%:  admin@%DOMAIN%

# http://www.dontbouncespam.org/#BVR

# ??? dont deliver to noreply@*
# editor /etc/courier/bofh
#     badfrom noreply@*

# DSN: Please consider using WeTransfer for sending BIG FILES / HU ...

# TLS_PROTOCOL,TLS_CIPHER_LIST for courierd, esmtpd, esmtpd-ssl, imapd, imapd-ssl

# more than 20 recipients -> use mailgun mailing list https://mailgun.com/
# set courier: bofh / maxrcpts 20 hard

# Testing infrequent restarts
echo "23h" > /etc/courier/respawnlo

# Tarbaby fake MX
# http://wiki.junkemailfilter.com/index.php/Project_tarbaby
editor /etc/courier/smtpaccess/default
#     # https://tools.ietf.org/html/rfc2821#section-4.2.3
#     # https://tools.ietf.org/html/rfc3463#section-3.8
#     # http://www.iana.org/assignments/smtp-enhanced-status-codes/smtp-enhanced-status-codes.xhtml
#     *	allow,RELAYCLIENT,BLOCK="451 4.7.1 Please try another MX"

# Add the lowest priority (highest numbered) MX record
#     domain.net.  IN  MX  50 tarbaby.domain.net.

# BLACKLISTS="-block=bl.blocklist.de"
