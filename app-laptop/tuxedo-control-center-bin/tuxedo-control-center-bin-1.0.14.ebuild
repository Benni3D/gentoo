# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit rpm systemd xdg-utils

MY_PN="${PN/-bin/}"

DESCRIPTION="Tool to control performance, energy, fan and comfort settings on TUXEDO laptops"
HOMEPAGE="https://github.com/tuxedocomputers/tuxedo-control-center"
SRC_URI="https://rpm.tuxedocomputers.com/opensuse/15.2/x86_64/${MY_PN}_${PV}.rpm"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""

RESTRICT="strip splitdebug"

DEPEND="sys-power/tuxedo-cc-wmi"
RDEPEND="${DEPEND}"
BDEPEND="virtual/imagemagick-tools"

S="${WORKDIR}"

src_prepare() {
	default
	rm -rf usr/lib || die "failed to remove usr/lib"
	mkdir files || die "failed to create files directory"

	mv "opt/${MY_PN}/resources/dist" "opt/${MY_PN}/dist" || die "failed to move: $(realpath .)"
	convert "opt/${MY_PN}/dist/${MY_PN}/data/dist-data/${MY_PN}_256.svg" "opt/${MY_PN}/dist/${MY_PN}/data/dist-data/${MY_PN}_256.png" || die "failed to convert icon"
}

src_install() {
	insinto /
	doins -r usr opt
	find . -type f -perm -a=x | while read f; do
		fperms 0755 "/${f}"
	done

	dosym ../../opt/tuxedo-control-center/tuxedo-control-center /usr/bin/tuxedo-control-center

	insinto /usr/share/dbus-1/system.d/
	doins opt/tuxedo-control-center/dist/tuxedo-control-center/data/dist-data/com.tuxedocomputers.tccd.conf

	insinto /usr/share/polkit-1/actions
	doins opt/tuxedo-control-center/dist/tuxedo-control-center/data/dist-data/de.tuxedocomputers.tcc.policy

	systemd_dounit opt/tuxedo-control-center/dist/tuxedo-control-center/data/dist-data/tccd.service
	systemd_dounit opt/tuxedo-control-center/dist/tuxedo-control-center/data/dist-data/tccd-sleep.service
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	elog
	if systemd_is_booted; then
		elog "You need to enable tccd and tccd-sleep service before running tuxedo-control-center"
		elog
		elog "Instructions:"
		elog "\$ systemctl daemon-reload"
		elog "\$ systemctl enable --now tccd.service tccd-sleep.service"
	else
		elog "You need to enable tccd service before running tuxedo-control-center"
		elog
		elog "Instructions:"
		elog "\$ rc-service tccd start"
		elog "\$ rc-update add tccd default"
	fi
	elog
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
