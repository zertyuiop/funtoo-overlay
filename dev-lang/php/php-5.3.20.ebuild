# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit eutils autotools flag-o-matic versionator depend.apache apache-module db-use libtool

SUHOSIN_VERSION=""
FPM_VERSION="builtin"
EXPECTED_TEST_FAILURES=""

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd"

function php_get_uri ()
{
	case "${1}" in
		"php-pre")
			echo "http://downloads.php.net/johannes/${2}"
		;;
		"php")
			echo "http://www.php.net/distributions/${2}"
		;;
		"suhosin")
			echo "http://download.suhosin.org/${2}"
		;;
		"olemarkus")
			echo "http://dev.gentoo.org/~olemarkus/php/${2}"
		;;
		"gentoo")
			echo "mirror://gentoo/${2}"
		;;
		*)
			die "unhandled case in php_get_uri"
		;;
	esac
}

PHP_MV="$(get_major_version)"
SLOT="$(get_version_component_range 1-2)"

# alias, so we can handle different types of releases (finals, rcs, alphas,
# betas, ...) w/o changing the whole ebuild
PHP_PV="${PV/_rc/RC}"
PHP_PV="${PHP_PV/_alpha/alpha}"
PHP_PV="${PHP_PV/_beta/beta}"
PHP_RELEASE="php"
[[ ${PV} == ${PV/_rc/} ]] || PHP_RELEASE="php-pre"
PHP_P="${PN}-${PHP_PV}"

PHP_PATCHSET_LOC="olemarkus"

PHP_SRC_URI="$(php_get_uri "${PHP_RELEASE}" "${PHP_P}.tar.bz2")"

PHP_PATCHSET="0"
PHP_PATCHSET_URI="
	$(php_get_uri "${PHP_PATCHSET_LOC}" "php-patchset-${SLOT}-r${PHP_PATCHSET}.tar.bz2")"

PHP_FPM_INIT_VER="4"
PHP_FPM_CONF_VER="1"

if [[ ${SUHOSIN_VERSION} == *-gentoo ]]; then
	# in some cases we use our own suhosin patch (very recent version,
	# patch conflicts, etc.)
	SUHOSIN_TYPE="olemarkus"
else
	SUHOSIN_TYPE="suhosin"
fi

if [[ -n ${SUHOSIN_VERSION} ]]; then
	SUHOSIN_PATCH="suhosin-patch-${SUHOSIN_VERSION}.patch";
	SUHOSIN_URI="$(php_get_uri ${SUHOSIN_TYPE} ${SUHOSIN_PATCH}.gz )"
fi

SRC_URI="
	${PHP_SRC_URI}
	${PHP_PATCHSET_URI}"

if [[ -n ${SUHOSIN_VERSION} ]]; then
	SRC_URI="${SRC_URI}
		suhosin? ( ${SUHOSIN_URI} )"
fi

DESCRIPTION="The PHP language runtime engine: CLI, CGI, FPM/FastCGI, Apache2 and embed SAPIs."
HOMEPAGE="http://php.net/"
LICENSE="PHP-3"

S="${WORKDIR}/${PHP_P}"

# We can build the following SAPIs in the given order
SAPIS="embed cli cgi fpm apache2"

# Gentoo-specific, common features
IUSE="kolab"

# SAPIs and SAPI-specific USE flags (cli SAPI is default on):
IUSE="${IUSE}
	${SAPIS/cli/+cli}
	threads"

IUSE="${IUSE} bcmath berkdb bzip2 calendar cdb cjk
	crypt +ctype curl curlwrappers debug doc
	enchant exif frontbase +fileinfo +filter firebird
	flatfile ftp gd gdbm gmp +hash +iconv imap inifile
	intl iodbc ipv6 +json kerberos ldap ldap-sasl libedit mhash
	mssql mysql mysqlnd mysqli nls
	oci8-instant-client odbc pcntl pdo +phar pic +posix postgres qdbm
	readline recode selinux +session sharedmem
	+simplexml snmp soap sockets spell sqlite2 sqlite ssl
	sybase-ct sysvipc tidy +tokenizer truetype unicode wddx
	+xml xmlreader xmlwriter xmlrpc xpm xsl zip zlib"

# Enable suhosin if available
[[ -n $SUHOSIN_VERSION ]] && IUSE="${IUSE} suhosin"

DEPEND="!dev-lang/php:5
	>=app-admin/eselect-php-0.6.2
	>=dev-libs/libpcre-8.12[unicode]
	apache2? ( www-servers/apache[threads=] )
	berkdb? ( =sys-libs/db-4* )
	bzip2? ( app-arch/bzip2 )
	cdb? ( || ( dev-db/cdb dev-db/tinycdb ) )
	cjk? ( !gd? (
		virtual/jpeg
		media-libs/libpng
		sys-libs/zlib
	) )
	crypt? ( >=dev-libs/libmcrypt-2.4 )
	curl? ( >=net-misc/curl-7.10.5 )
	enchant? ( app-text/enchant )
	exif? ( !gd? (
		virtual/jpeg
		media-libs/libpng
		sys-libs/zlib
	) )
	firebird? ( dev-db/firebird )
	gd? ( virtual/jpeg media-libs/libpng sys-libs/zlib )
	gdbm? ( >=sys-libs/gdbm-1.8.0 )
	gmp? ( >=dev-libs/gmp-4.1.2 )
	iconv? ( virtual/libiconv )
	imap? ( virtual/imap-c-client[ssl=] )
	intl? ( dev-libs/icu )
	iodbc? ( dev-db/libiodbc )
	kerberos? ( virtual/krb5 )
	kolab? ( >=net-libs/c-client-2004g-r1 )
	ldap? ( >=net-nds/openldap-1.2.11 )
	ldap-sasl? ( dev-libs/cyrus-sasl >=net-nds/openldap-1.2.11 )
	libedit? ( || ( sys-freebsd/freebsd-lib dev-libs/libedit ) )
	mssql? ( dev-db/freetds[mssql] )
	!mysqlnd? (
		mysql? ( virtual/mysql )
		mysqli? ( >=virtual/mysql-4.1 )
	)
	nls? ( sys-devel/gettext )
	oci8-instant-client? ( dev-db/oracle-instantclient-basic )
	odbc? ( >=dev-db/unixODBC-1.8.13 )
	postgres? ( dev-db/postgresql-base )
	qdbm? ( dev-db/qdbm )
	readline? ( sys-libs/readline )
	recode? ( app-text/recode )
	sharedmem? ( dev-libs/mm )
	simplexml? ( >=dev-libs/libxml2-2.6.8 )
	snmp? ( >=net-analyzer/net-snmp-5.2 )
	soap? ( >=dev-libs/libxml2-2.6.8 )
	spell? ( >=app-text/aspell-0.50 )
	sqlite2? ( =dev-db/sqlite-2* )
	sqlite? ( >=dev-db/sqlite-3.7.7.1 )
	ssl? ( >=dev-libs/openssl-0.9.7 )
	sybase-ct? ( dev-db/freetds )
	tidy? ( app-text/htmltidy )
	truetype? (
		=media-libs/freetype-2*
		>=media-libs/t1lib-5.0.0
		!gd? (
			virtual/jpeg media-libs/libpng sys-libs/zlib )
	)
	unicode? ( dev-libs/oniguruma )
	wddx? ( >=dev-libs/libxml2-2.6.8 )
	xml? ( >=dev-libs/libxml2-2.6.8 )
	xmlrpc? ( >=dev-libs/libxml2-2.6.8 virtual/libiconv )
	xmlreader? ( >=dev-libs/libxml2-2.6.8 )
	xmlwriter? ( >=dev-libs/libxml2-2.6.8 )
	xpm? (
		x11-libs/libXpm
		virtual/jpeg
		media-libs/libpng sys-libs/zlib
	)
	xsl? ( dev-libs/libxslt >=dev-libs/libxml2-2.6.8 )
	zip? ( sys-libs/zlib )
	zlib? ( sys-libs/zlib )
	virtual/mta
"

php="=${CATEGORY}/${PF}"

REQUIRED_USE="
	truetype? ( gd )
	cjk? ( gd )
	exif? ( gd )

	xpm? ( gd )
	gd? ( zlib )
	simplexml? ( xml )
	soap? ( xml )
	wddx? ( xml )
	xmlrpc? ( || ( xml iconv ) )
	xmlreader? ( xml )
	xsl? ( xml )
	ldap-sasl? ( ldap )
	kolab? ( imap )
	mhash? ( hash )
	phar? ( hash )
	mysqlnd? ( || (
		mysql
		mysqli
		pdo
	) )

	qdbm? ( !gdbm )
	readline? ( !libedit )
	recode? ( !imap !mysql !mysqli )
	sharedmem? ( !threads )

	!cli? ( !cgi? ( !fpm? ( !apache2? ( !embed? ( cli ) ) ) ) )"

RDEPEND="${DEPEND}"

[[ -n $SUHOSIN_VERSION ]] && RDEPEND="${RDEPEND} suhosin? ( =${CATEGORY}/${PN}-${SLOT}*[unicode] )"

RDEPEND="${RDEPEND} fpm? ( selinux? ( sec-policy/selinux-phpfpm ) )"

DEPEND="${DEPEND}
	sys-devel/flex
	>=sys-devel/m4-1.4.3
	>=sys-devel/libtool-1.5.18"

# They are in PDEPEND because we need PHP installed first!
PDEPEND="doc? ( app-doc/php-docs )"

# No longer depend on the extension. The suhosin USE flag only installs the
# patch
#[[ -n $SUHOSIN_VERSION ]] && PDEPEND="${PDEPEND} suhosin? ( dev-php${PHP_MV}/suhosin )"

# Allow users to install production version if they want to

case "${PHP_INI_VERSION}" in
	production|development)
		;;
	*)
		PHP_INI_VERSION="development"
		;;
esac

PHP_INI_UPSTREAM="php.ini-${PHP_INI_VERSION}"
PHP_INI_FILE="php.ini"

want_apache

pkg_setup() {
	depend.apache_pkg_setup
}

php_install_ini() {
	local phpsapi="${1}"

	# work out where we are installing the ini file
	php_set_ini_dir "${phpsapi}"

	local phpinisrc="${PHP_INI_UPSTREAM}-${phpsapi}"
	cp "${PHP_INI_UPSTREAM}" "${phpinisrc}"

	# default to /tmp for save_path, bug #282768
	sed -e 's|^;session.save_path .*$|session.save_path = "'"${EPREFIX}"'/tmp"|g' -i "${phpinisrc}"

	# Set the extension dir
	sed -e "s|^extension_dir .*$|extension_dir = ${extension_dir}|g" -i "${phpinisrc}"

	# Set the include path to point to where we want to find PEAR packages
	sed -e 's|^;include_path = ".:/php/includes".*|include_path = ".:'"${EPREFIX}"'/usr/share/php'${PHP_MV}':'"${EPREFIX}"'/usr/share/php"|' -i "${phpinisrc}"

	dodir "${PHP_INI_DIR#${EPREFIX}}"
	insinto "${PHP_INI_DIR#${EPREFIX}}"
	newins "${phpinisrc}" "${PHP_INI_FILE}"

	elog "Installing php.ini for ${phpsapi} into ${PHP_INI_DIR#${EPREFIX}}"
	elog

	dodir "${PHP_EXT_INI_DIR#${EPREFIX}}"
	dodir "${PHP_EXT_INI_DIR_ACTIVE#${EPREFIX}}"

	# SAPI-specific handling
	if [[ "${sapi}" == "apache2" ]] ; then
		insinto "${APACHE_MODULES_CONFDIR#${EPREFIX}}"
		newins "${FILESDIR}/70_mod_php${PHP_MV}.conf-apache2" \
			"70_mod_php${PHP_MV}.conf"
	fi

	if [[ "${sapi}" == "fpm" ]] ; then
        [[ -z ${PHP_FPM_INIT_VER} ]] && PHP_FPM_INIT_VER=3
        [[ -z ${PHP_FPM_CONF_VER} ]] && PHP_FPM_CONF_VER=0
		einfo "Installing FPM CGI config file php-fpm.conf"
		insinto "${PHP_INI_DIR#${EPREFIX}}"
		newins "${FILESDIR}/php-fpm-r${PHP_FPM_CONF_VER}.conf" php-fpm.conf
		dodir "/etc/init.d"
		insinto "/etc/init.d"
		newinitd "${FILESDIR}/php-fpm-r${PHP_FPM_INIT_VER}.init" "php-fpm"
		# dosym "${PHP_DESTDIR#${EPREFIX}}/bin/php-fpm" "/usr/bin/php-fpm"

		# Remove bogus /etc/php-fpm.conf.default (bug 359906)
		[[ -f "${ED}/etc/php-fpm.conf.default" ]] && rm "${ED}/etc/php-fpm.conf.default"
	fi

	# Install PHP ini files into /usr/share/php

	dodoc php.ini-development
	dodoc php.ini-production

}

php_set_ini_dir() {
	PHP_INI_DIR="${EPREFIX}/etc/php/${1}-php${SLOT}"
	PHP_EXT_INI_DIR="${PHP_INI_DIR}/ext"
	PHP_EXT_INI_DIR_ACTIVE="${PHP_INI_DIR}/ext-active"
}

src_prepare() {
	# USE=sharedmem (session/mod_mm to be exact) tries to mmap() this path
	# ([empty session.save_path]/session_mm_[sapi][gid].sem)
	# there is no easy way to circumvent that, all php calls during
	# install use -n, so no php.ini file will be used.
	# As such, this is the easiest way to get around
	addpredict /session_mm_cli250.sem
	addpredict /session_mm_cli0.sem

	# kolab support (support for imap annotations)
	use kolab && epatch "${WORKDIR}/patches/opt/imap-kolab-annotations.patch"

	# Change PHP branding
	sed -re	"s|^(PHP_EXTRA_VERSION=\").*(\")|\1${PHP_EXTRA_BRANDING}-pl${PR/r/}-gentoo\2|g" \
		-i configure.in || die "Unable to change PHP branding"

	# Apply generic PHP patches
	EPATCH_SOURCE="${WORKDIR}/patches/generic" EPATCH_SUFFIX="patch" \
		EPATCH_FORCE="yes" \
		EPATCH_MULTI_MSG="Applying generic patches and fixes from upstream..." epatch

	# Patch PHP to show Gentoo as the server platform
	sed -e 's/PHP_UNAME=`uname -a | xargs`/PHP_UNAME=`uname -s -n -r -v | xargs`/g' \
		-i configure.in || die "Failed to fix server platform name"

	# Prevent PHP from activating the Apache config,
	# as we will do that ourselves
	sed -i \
		-e "s,-i -a -n php${PHP_MV},-i -n php${PHP_MV},g" \
		-e "s,-i -A -n php${PHP_MV},-i -n php${PHP_MV},g" \
		configure sapi/apache2filter/config.m4 sapi/apache2handler/config.m4

	# Patch PHP to support heimdal instead of mit-krb5
	if has_version "app-crypt/heimdal" ; then
		sed -e 's|gssapi_krb5|gssapi|g' -i acinclude.m4 \
			|| die "Failed to fix heimdal libname"
		sed -e 's|PHP_ADD_LIBRARY(k5crypto, 1, $1)||g' -i acinclude.m4 \
			|| die "Failed to fix heimdal crypt library reference"
	fi

	# Suhosin support
	if [[ -n $SUHOSIN_VERSION ]] ; then
		if use suhosin ; then
			epatch "${WORKDIR}/${SUHOSIN_PATCH}"
		fi
	else
		ewarn "Please note that this version of PHP does not yet come with a suhosin patch"
	fi

	#Add user patches #357637
	epatch_user

	# rebuild the whole autotools stuff as we are heavily patching it
	# (suhosin, fastbuild, ...)

	# eaclocal doesn't accept --force, so we try to force re-generation
	# this way
	rm aclocal.m4

	# work around divert() issues with newer autoconf, bug #281697
	if has_version '>=sys-devel/autoconf-2.64' ; then
		sed -i -r \
			-e 's:^((m4_)?divert)[(]([0-9]*)[)]:\1(600\3):' \
			$(grep -l divert $(find . -name '*.m4') configure.in) || die
	fi
	eautoreconf --force -W no-cross
}

src_configure() {
	addpredict /usr/share/snmp/mibs/.index
	addpredict /var/lib/net-snmp/mib_indexes

	PHP_DESTDIR="/usr/$(get_libdir)/php${SLOT}"

	# This is a global variable and should be in caps. It isn't because the
	# phpconfutils eclass relies on exactly this name...
	# for --with-libdir see bug #327025
	my_conf="--prefix=${PHP_DESTDIR}
		--mandir=${PHP_DESTDIR}/man
		--infodir=${PHP_DESTDIR}/info
		--libdir=${PHP_DESTDIR}/lib
		--with-libdir=$(get_libdir)
		--without-pear
		$(use_enable threads maintainer-zts)"

	#                             extension	      USE flag        shared
	my_conf+="
	$(use_enable bcmath bcmath )
	$(use_with bzip2 bz2 )
	$(use_enable calendar calendar )
	$(use_enable ctype ctype )
	$(use_with curl curl )
	$(use_with curlwrappers curlwrappers )
	$(use_enable xml dom )
	$(use_with enchant enchant /usr)
	$(use_enable exif exif )
	$(use_enable fileinfo fileinfo )
	$(use_enable filter filter )
	$(use_enable ftp ftp )
	$(use_with nls gettext )
	$(use_with gmp gmp )
	$(use_enable hash hash )
	$(use_with mhash mhash )
	$(use_with iconv iconv )
	$(use_enable intl intl )
	$(use_enable ipv6 ipv6 )
	$(use_enable json json )
	$(use_with kerberos kerberos /usr)
	$(use_enable xml libxml )
	$(use_enable unicode mbstring )
	$(use_with crypt mcrypt )
	$(use_with mssql mssql )
	$(use_with unicode onig /usr)
	$(use_with ssl openssl )
	$(use_with ssl openssl-dir /usr)
	$(use_enable pcntl pcntl )
	$(use_enable phar phar )
	$(use_enable pdo pdo )
	$(use_with postgres pgsql )
	$(use_enable posix posix )
	$(use_with spell pspell )
	$(use_with recode recode )
	$(use_enable simplexml simplexml )
	$(use_enable sharedmem shmop )
	$(use_with snmp snmp )
	$(use_enable soap soap )
	$(use_enable sockets sockets )"
	if version_is_at_least 5.3.16-r2; then
		my_conf+=" $(use_with sqlite2 sqlite /usr) "
		use sqlite2 && my_conf+=" $(use_enable unicode sqlite-utf8)"
	else
		my_conf+=" $(use_with sqlite sqlite /usr) "
		use sqlite && my_conf+=" $(use_enable unicode sqlite-utf8)"
	fi
    my_conf+="
	$(use_with sqlite sqlite3 /usr)
	$(use_with sybase-ct sybase-ct /usr)
	$(use_enable sysvipc sysvmsg )
	$(use_enable sysvipc sysvsem )
	$(use_enable sysvipc sysvshm )
	$(use_with tidy tidy )
	$(use_enable tokenizer tokenizer )
	$(use_enable wddx wddx )
	$(use_enable xml xml )
	$(use_enable xmlreader xmlreader )
	$(use_enable xmlwriter xmlwriter )
	$(use_with xmlrpc xmlrpc )
	$(use_with xsl xsl )
	$(use_enable zip zip )
	$(use_with zlib zlib )
	$(use_enable debug debug )"

	# DBA support
	if use cdb || use berkdb || use flatfile || use gdbm || use inifile \
		|| use qdbm ; then
		my_conf="${my_conf} --enable-dba${shared}"
	fi

	# DBA drivers support
	my_conf+="
	$(use_with cdb cdb )
	$(use_with berkdb db4 )
	$(use_enable flatfile flatfile )
	$(use_with gdbm gdbm )
	$(use_enable inifile inifile )
	$(use_with qdbm qdbm )"

	# Support for the GD graphics library
	my_conf+="
	$(use_with truetype freetype-dir /usr)
	$(use_with truetype t1lib /usr)
	$(use_enable cjk gd-jis-conv )
	$(use_with gd jpeg-dir /usr)
	$(use_with gd png-dir /usr)
	$(use_with xpm xpm-dir /usr)"
	# enable gd last, so configure can pick up the previous settings
	my_conf+="
	$(use_with gd gd )"

	# IMAP support
	if use imap ; then
	    my_conf+="
		$(use_with imap imap )
		$(use_with ssl imap-ssl )"
	fi

	# Interbase/firebird support

	if use firebird ; then
	    my_conf+="
		$(use_with firebird interbase /usr)"
	fi

	# LDAP support
	if use ldap ; then
	    my_conf+="
		$(use_with ldap ldap )
		$(use_with ldap-sasl ldap-sasl )"
	fi

	# MySQL support
	if use mysql ; then
		if use mysqlnd ; then
	        my_conf+="
			$(use_with mysql mysql mysqlnd)"
		else
	        my_conf+="
			$(use_with mysql mysql /usr)"
		fi
	    my_conf+="
		$(use_with mysql mysql-sock /var/run/mysqld/mysqld.sock)"
	fi

	# MySQLi support
	if use mysqlnd ; then
	    my_conf+="
		$(use_with mysqli mysqli mysqlnd)"
	else
	    my_conf+="
		$(use_with mysqli mysqli /usr/bin/mysql_config)"
	fi

	# ODBC support
	if use odbc ; then
	    my_conf+="
		$(use_with odbc unixODBC /usr)"
	fi

	if use iodbc ; then
	    my_conf+="
		$(use_with iodbc iodbc /usr)"
	fi

	# Oracle support
	if use oci8-instant-client ; then
	    my_conf+="
		$(use_with oci8-instant-client oci8)"
	fi

	# PDO support
	if use pdo ; then
	    my_conf+="
		$(use_with mssql pdo-dblib )"
		if use mysqlnd ; then
	        my_conf+="
			$(use_with mysql pdo-mysql mysqlnd)"
		else
	        my_conf+="
			$(use_with mysql pdo-mysql /usr)"
		fi
	    my_conf+="
		$(use_with postgres pdo-pgsql )
		$(use_with sqlite pdo-sqlite /usr)
		$(use_with odbc pdo-odbc unixODBC,/usr)"
		if use oci8-instant-client ; then
	        my_conf+="
			$(use_with oci8-instant-client pdo-oci)"
		fi
	fi

	# readline/libedit support
	my_conf+="
	$(use_with readline readline )
	$(use_with libedit libedit )"

	# Session support
	if use session ; then
	    my_conf+="
		$(use_with sharedmem mm )"
	else
	    my_conf+="
		$(use_enable session session )"
	fi

	if use pic ; then
		my_conf="${my_conf} --with-pic"
	fi

	# we use the system copy of pcre
	# --with-pcre-regex affects ext/pcre
	# --with-pcre-dir affects ext/filter and ext/zip
	my_conf="${my_conf} --with-pcre-regex=/usr --with-pcre-dir=/usr"

	# Catch CFLAGS problems
    # Fixes bug #14067.
    # Changed order to run it in reverse for bug #32022 and #12021.
    replace-cpu-flags "k6*" "i586"

	# Support user-passed configuration parameters
	my_conf="${my_conf} ${EXTRA_ECONF:-}"

	# Support the Apache2 extras, they must be set globally for all
	# SAPIs to work correctly, especially for external PHP extensions

	mkdir -p "${WORKDIR}/sapis-build"
	for one_sapi in $SAPIS ; do
		use "${one_sapi}" || continue
		php_set_ini_dir "${one_sapi}"

		cp -r "${S}" "${WORKDIR}/sapis-build/${one_sapi}"
		cd "${WORKDIR}/sapis-build/${one_sapi}"

		sapi_conf="${my_conf} --with-config-file-path=${PHP_INI_DIR}
			--with-config-file-scan-dir=${PHP_EXT_INI_DIR_ACTIVE}"

		for sapi in $SAPIS ; do
			case "$sapi" in
				cli|cgi|embed|fpm)
					if [[ "${one_sapi}" == "${sapi}" ]] ; then
						sapi_conf="${sapi_conf} --enable-${sapi}"
					else
						sapi_conf="${sapi_conf} --disable-${sapi}"
					fi
					;;

				apache2)
					if [[ "${one_sapi}" == "${sapi}" ]] ; then
						sapi_conf="${sapi_conf} --with-apxs2=/usr/sbin/apxs"
					else
						sapi_conf="${sapi_conf} --without-apxs2"
					fi
					;;
			esac
		done

		econf ${sapi_conf}
	done
}

src_compile() {
	# snmp seems to run during src_compile, too (bug #324739)
	addpredict /usr/share/snmp/mibs/.index
	addpredict /var/lib/net-snmp/mibs/.index

	SAPI_DIR="${WORKDIR}/sapis"

	for sapi in ${SAPIS} ; do
		use "${sapi}" || continue

		php_sapi_build "${sapi}"
		php_sapi_copy "${sapi}"
	done
}

php_sapi_build() {
	mkdir -p "${SAPI_DIR}/$1"

	cd "${WORKDIR}/sapis-build/$1"
	emake || die "emake failed"
}

php_sapi_copy() {
	local sapi="$1"
	local source=""

	case "$sapi" in
		cli)
			source="sapi/cli/php"
			;;
		cgi)
			source="sapi/cgi/php-cgi"
			;;
		fpm)
			source="sapi/fpm/php-fpm"
			;;
		embed)
			source="libs/libphp${PHP_MV}.so"
			;;

		apache2)
			# apache2 is a special case; the necessary files
			# (yes, multiple) are copied by make install, not
			# by the ebuild; that's the reason, why apache2 has
			# to be the last sapi
			emake INSTALL_ROOT="${SAPI_DIR}/${sapi}/" install-sapi
			;;

		*)
			die "unhandled sapi in php_sapi_copy"
			;;
	esac

	if [[ "${source}" ]] ; then
		cp "$source" "${SAPI_DIR}/$sapi" || die "Unable to copy ${sapi} SAPI"
	fi
}

src_install() {
	# see bug #324739 for what happens when we don't have that
	addpredict /usr/share/snmp/mibs/.index

	# grab the first SAPI that got built and install common files from there
	local first_sapi=""
	for sapi in $SAPIS ; do
		if use $sapi ; then
			first_sapi=$sapi
			break
		fi
	done

	# Makefile forgets to create this before trying to write to it...
	dodir "${PHP_DESTDIR#${EPREFIX}}/bin"

	# Install php environment (without any sapis)
	cd "${WORKDIR}/sapis-build/$first_sapi"
	emake INSTALL_ROOT="${D}" \
		install-build install-headers install-programs \
		|| die "emake install failed"

	local extension_dir="$("${ED}/${PHP_DESTDIR#${EPREFIX}}/bin/php-config" --extension-dir)"

	# Create the directory where we'll put version-specific php scripts
	keepdir /usr/share/php${PHP_MV}

	local sapi="", file=""
	local sapi_list=""

	for sapi in ${SAPIS}; do
		if use "${sapi}" ; then
			einfo "Installing SAPI: ${sapi}"
			cd "${WORKDIR}/sapis-build/${sapi}"

			if [[ "${sapi}" == "apache2" ]] ; then
				# We're specifically not using emake install-sapi as libtool
				# may cause unnecessary relink failures (see bug #351266)
				insinto "${PHP_DESTDIR#${EPREFIX}}/apache2/"
				newins ".libs/libphp5$(get_libname)" "libphp${PHP_MV}$(get_libname)"
				keepdir "/usr/$(get_libdir)/apache2/modules"
			else
				# needed each time, php_install_ini would reset it
				into "${PHP_DESTDIR#${EPREFIX}}"
			    case "$sapi" in
					cli)
						source="sapi/cli/php"
						;;
					cgi)
						source="sapi/cgi/php-cgi"
						;;
					fpm)
						source="sapi/fpm/php-fpm"
						;;
					embed)
						source="libs/libphp${PHP_MV}$(get_libname)"
						;;
					*)
						die "unhandled sapi in src_install"
						;;
				esac

				if [[ "${source}" == *"$(get_libname)" ]]; then
					dolib.so "${source}" || die "Unable to install ${sapi} sapi"
				else
					dobin "${source}" || die "Unable to install ${sapi} sapi"
				fi
			fi

			php_install_ini "${sapi}"

			# construct correct SAPI string for php-config
			# thanks to ferringb for the bash voodoo
			if [[ "${sapi}" == "apache2" ]]; then
				sapi_list="${sapi_list:+${sapi_list} }apache2handler"
			else
				sapi_list="${sapi_list:+${sapi_list} }${sapi}"
			fi
		fi
	done

	# Install env.d files
	newenvd "${FILESDIR}/20php5-envd" \
		"20php${SLOT}"
	sed -e "s|/lib/|/$(get_libdir)/|g" -i \
		"${ED}/etc/env.d/20php${SLOT}"
	sed -e "s|php5|php${SLOT}|g" -i \
		"${ED}/etc/env.d/20php${SLOT}"

	# set php-config variable correctly (bug #278439)
	sed -e "s:^\(php_sapis=\)\".*\"$:\1\"${sapi_list}\":" -i \
		"${ED}/usr/$(get_libdir)/php${SLOT}/bin/php-config"
}

src_test() {
	echo ">>> Test phase [test]: ${CATEGORY}/${PF}"
	PHP_BIN="${WORKDIR}/sapis-build/cli/sapi/cli/php"
	if [[ ! -x "${PHP_BIN}" ]] ; then
		ewarn "Test phase requires USE=cli, skipping"
		return
	else
		export TEST_PHP_EXECUTABLE="${PHP_BIN}"
	fi

	if [[ -x "${WORKDIR}/sapis/cgi/php-cgi" ]] ; then
		export TEST_PHP_CGI_EXECUTABLE="${WORKDIR}/sapis/cgi/php-cgi"
	fi

	REPORT_EXIT_STATUS=1 "${TEST_PHP_EXECUTABLE}" -n  -d "session.save_path=${T}" \
		"${WORKDIR}/sapis-build/cli/run-tests.php" -n -q -d "session.save_path=${T}"

	for name in ${EXPECTED_TEST_FAILURES}; do
		mv "${name}.out" "${name}.out.orig" 2>/dev/null
	done

	local failed="$(find -name '*.out')"
	if [[ ${failed} != "" ]] ; then
		ewarn "The following test cases failed unexpectedly:"
		for name in ${failed}; do
			ewarn "  ${name/.out/}"
		done
	else
		einfo "No unexpected test failures, all fine"
	fi

	if [[ ${PHP_SHOW_UNEXPECTED_TEST_PASS} == "1" ]] ; then
		local passed=""
		for name in ${EXPECTED_TEST_FAILURES}; do
			[[ -f "${name}.diff" ]] && continue
			passed="${passed} ${name}"
		done
		if [[ ${passed} != "" ]] ; then
			einfo "The following test cases passed unexpectedly:"
			for name in ${passed}; do
				ewarn "  ${passed}"
			done
		else
			einfo "None of the known-to-fail tests passed, all fine"
		fi
	fi
}

#Do not use eblit for this because it will not get sourced when installing from
#binary package (bug #380845)
pkg_postinst() {
	# Output some general info to the user
	if use apache2 ; then
		APACHE2_MOD_DEFINE="PHP5"
		APACHE2_MOD_CONF="70_mod_php5"
		apache-module_pkg_postinst
	fi

	# Create the symlinks for php
	for m in ${SAPIS}; do
		[[ ${m} == 'embed' ]] && continue;
		if use $m ; then
			local ci=$(eselect php show $m)
			if [[ -z $ci ]]; then
				eselect php set $m php${SLOT}
				einfo "Switched ${m} to use php:${SLOT}"
				einfo
			elif [[ $ci != "php${SLOT}" ]] ; then
				elog "To switch $m to use php:${SLOT}, run"
				elog "    eselect php set $m php${SLOT}"
				elog
			fi
		fi
	done

	elog "Make sure that PHP_TARGETS in /etc/make.conf includes php${SLOT/./-} in order"
	elog "to compile extensions for the ${SLOT} ABI"
	elog
	if ! use readline && use cli ; then
		ewarn "Note that in order to use php interactivly, you need to enable"
		ewarn "the readline USE flag or php -a will hang"
	fi
	elog
	elog "This ebuild installed a version of php.ini based on php.ini-${PHP_INI_VERSION} version."
	elog "You can chose which version of php.ini to install by default by setting PHP_INI_VERSION to either"
	elog "'production' or 'development' in /etc/make.conf"
	ewarn "Both versions of php.ini can be found in /usr/share/doc/${PF}"

	# check for not yet migrated old style config dirs
	ls "${ROOT}"/etc/php/*-php5 &>/dev/null
	if [[ $? -eq 0 ]]; then
		ewarn "Make sure to migrate your config files, starting with php-5.3.4 and php-5.2.16 config"
		ewarn "files are now kept at ${ROOT}etc/php/{apache2,cli,cgi,fpm}-php5.x"
	fi
	elog
	elog "For more details on how minor version slotting works (PHP_TARGETS) please read the upgrade guide:"
	elog "http://www.gentoo.org/proj/en/php/php-upgrading.xml"
	elog

	if ( [[ -z SUHOSIN_VERSION ]] && use suhosin && version_is_at_least 5.3.6_rc1 ) ; then
		ewarn "The suhosin USE flag now only installs the suhosin patch!"
		ewarn "If you want the suhosin extension, make sure you install"
		ewarn " dev-php5/suhosin"
		ewarn
	fi
}
