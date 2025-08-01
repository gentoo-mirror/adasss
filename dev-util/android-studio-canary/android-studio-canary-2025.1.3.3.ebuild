# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop wrapper

QA_PREBUILT="
	opt/${PN}/bin/*
	opt/${PN}/jbr/bin/*
	opt/${PN}/jbr/lib/*
	opt/${PN}/jbr/lib/jli/*
	opt/${PN}/jbr/lib/server/*
	opt/${PN}/lib/jna/amd64/*
	opt/${PN}/lib/native/linux-x86_64/*
	opt/${PN}/lib/pty4j/linux/x86_64/*
	opt/${PN}/plugins/android/resources/installer/*/*
	opt/${PN}/plugins/android/resources/native/*
	opt/${PN}/plugins/android/resources/perfetto/*/*
	opt/${PN}/plugins/android/resources/process-tracker-agent/native/*/*
	opt/${PN}/plugins/android/resources/screen-sharing-agent/*/*
	opt/${PN}/plugins/android/resources/simpleperf/*/*
	opt/${PN}/plugins/android/resources/trace_processor_daemon/*
	opt/${PN}/plugins/android/resources/transport/*/*
	opt/${PN}/plugins/android/resources/transport/native/agent/*/*
	opt/${PN}/plugins/android-ndk/resources/lldb/android/*/*
	opt/${PN}/plugins/android-ndk/resources/lldb/bin/*
	opt/${PN}/plugins/android-ndk/resources/lldb/lib/*
	opt/${PN}/plugins/android-ndk/resources/lldb/lib/python3.10/lib-dynload/*
	opt/${PN}/plugins/android-ndk/resources/lldb/lib64/*
	opt/${PN}/plugins/c-clangd-plugin/bin/clang/linux/x64/bin/*
	opt/${PN}/plugins/design-tools/resources/layoutlib/data/linux/lib64/*
	opt/${PN}/plugins/webp/lib/libwebp/linux/*
"

DESCRIPTION="Android development environment based on IntelliJ IDEA"

HOMEPAGE="https://developer.android.com/studio/preview/index.html"

PROG="android-studio"

SRC_URI="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${PV}/${PROG}-${PV}-linux.tar.gz"

S=${WORKDIR}/${PROG}

LICENSE="Apache-2.0 android BSD BSD-2 CDDL-1.1 CPL-0.5
	EPL-1.0 GPL-2 GPL-2+ JDOM IJG LGPL-2.1 MIT
	MPL-1.1 MPL-2.0 NPL-1.1 OFL-1.1 ZLIB"
SLOT="0"

KEYWORDS="~amd64"

IUSE="experimental selinux wayland"

REQUIRED_USE="experimental? ( wayland )"

RESTRICT="bindist mirror strip"

RDEPEND="
	selinux? ( sec-policy/selinux-android )
	wayland? ( dev-libs/wayland )
	>=app-arch/bzip2-1.0.8-r4
	>=dev-libs/expat-2.5.0
	>=dev-libs/libffi-3.4.4
	>=media-libs/fontconfig-2.14.0-r1
	>=media-libs/freetype-2.12.1-r1
	>=media-libs/libpng-1.6.39
	>=media-libs/mesa-22.2.5[X(+)]
	|| ( gnome-extra/zenity kde-apps/kdialog x11-apps/xmessage x11-libs/libnotify )
	sys-libs/ncurses-compat:5[tinfo]
	>=sys-libs/zlib-1.2.13-r1
	>=x11-libs/libX11-1.8.1
	>=x11-libs/libXau-1.0.11
	>=x11-libs/libXdamage-1.1.6
	>=x11-libs/libXdmcp-1.1.4-r2
	>=x11-libs/libXext-1.3.5
	>=x11-libs/libXfixes-6.0.0
	>=x11-libs/libXrender-0.9.11
	>=x11-libs/libXxf86vm-1.1.5
	>=x11-libs/libdrm-2.4.114
	>=x11-libs/libxcb-1.15-r1
	sys-libs/libxcrypt[compat]
	>=x11-libs/libxshmfence-1.3.2
	virtual/libcrypt:=
"

DEPEND=${RDEPEND}

PATCHES=(
	"${FILESDIR}/${PN}-jdk.patch"
)

src_prepare() {
	default

	cat <<-EOF >> bin/idea.properties || die
	#-----------------------------------------------------------------------
	# Disable automatic updates as these are handled through Gentoo's
	# package manager.
	#-----------------------------------------------------------------------
	ide.no.platform.update=Gentoo
	EOF
}

src_compile() {
	:;
}

src_install() {
	local dir="/opt/${PN}"
	insinto "${dir}"
	doins -r *

	fperms 755 "${dir}"/bin/{fsnotifier,restarter,studio,format.sh,game-tools.sh,inspect.sh,ltedit.sh,profiler.sh,studio.sh}
	fperms -R 755 "${dir}"/bin/{helpers,lldb}
	fperms -R 755 "${dir}"/jbr/bin
	fperms 755 "${dir}"/jbr/lib/{jexec,jspawnhelper}
	fperms -R 755 "${dir}"/plugins/Kotlin/kotlinc/bin
	fperms -R 755 "${dir}"/plugins/android/resources/installer
	fperms -R 755 "${dir}"/plugins/android/resources/perfetto
	fperms -R 755 "${dir}"/plugins/android/resources/simpleperf
	fperms -R 755 "${dir}"/plugins/android/resources/trace_processor_daemon
	fperms -R 755 "${dir}"/plugins/android/resources/transport/{arm64-v8a,armeabi-v7a,x86,x86_64}
	fperms -R 755 "${dir}"/plugins/android-ndk/resources/lldb/{android,bin,lib,shared}
	fperms 755 "${dir}"/plugins/c-clangd/bin/clang/linux/x64/bin/clangd

	newicon "bin/studio.png" "${PN}.png"

	if use experimental; then
		make_wrapper ${PN} "${dir}/bin/studio -Dawt.toolkit.name=WLToolkit"
		ewarn "You have enabled the experimental USE flag."
		ewarn "This is a Wayland support preview. Expect instability."
	else
		make_wrapper ${PN} ${dir}/bin/studio
	fi

	make_desktop_entry ${PN} "Android Studio Canary" ${PN} "Development;IDE" "StartupWMClass=jetbrains-studio"

	# https://developer.android.com/studio/command-line/variables
	newenvd - 99android-studio-canary <<-EOF
		# Configuration file android-studio-canary
		STUDIO_JDK_CANARY="${dir}/jbr"
	EOF
}

pkg_postrm() {
	elog "Android Studio data files were not removed."
	elog "If there will be no other programs using them anymore"
	elog "(especially another flavor of Android Studio)"
	elog "remove manually following folders:"
	elog ""
	elog "		~/.android/"
	elog "		~/.config/Google/AndroidStudio*/"
	elog "		~/.local/share/Google/AndroidStudio*/"
	elog "		~/Android/"
	elog ""
	elog "Also, if there are no other programs using Gradle, remove:"
	elog ""
	elog "		~/.gradle/"
}
