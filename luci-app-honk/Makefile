# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#
# Single self-contained package: LuCI frontend + honk-core static binary +
# embedded Doona dashboard + embedded geodata. One ipk/apk installs everything;
# only kernel modules (kmod-*) are pulled in as opkg dependencies because they
# must match the running kernel.

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-honk
PKG_VERSION:=0.0.1_beta83
PKG_RELEASE:=1

# Raw upstream release tag. It keeps the dots in qualifiers (e.g. v0.0.1.beta.49)
# because that is what the GitHub release asset name uses.
HONK_RELEASE_TAG:=v0.0.1.beta.83

# SHA256 of each release tarball, kept in sync by scripts/update_honk_version.sh.
HONK_HASH_X86_64:=0d440bc094a4ceead94a897647b3c598f6ca7630c65a1675ed137e3d9c1c0c56
HONK_HASH_AARCH64:=bb8c893c676f8f245332598ae701f50b803b922aef308dded4d0805c67692ab3

ifeq ($(ARCH),x86_64)
  HONK_TARGET:=x86_64-unknown-linux-musl
  HONK_HASH:=$(HONK_HASH_X86_64)
else ifeq ($(ARCH),aarch64)
  HONK_TARGET:=aarch64-unknown-linux-musl
  HONK_HASH:=$(HONK_HASH_AARCH64)
endif

# Default to the stock-malloc build: lower RSS high-water on small gateways.
# Use an empty suffix to switch back to the mimalloc build (faster QUIC).
HONK_SUFFIX:=-stock
HONK_ASSET:=honk-core-$(HONK_RELEASE_TAG)-$(HONK_TARGET)$(HONK_SUFFIX).tar.gz

PKG_SOURCE:=$(HONK_ASSET)
PKG_SOURCE_URL:=https://github.com/daeuniverse/honk/releases/download/$(HONK_RELEASE_TAG)/
PKG_HASH:=$(HONK_HASH)

PKG_LICENSE:=AGPL-3.0-only
PKG_MAINTAINER:=luci-app-honk maintainers

LUCI_TITLE:=LuCI support for honk (self-contained)
LUCI_PKGARCH:=$(ARCH)
LUCI_DEPENDS:=@(x86_64||aarch64) \
	+luci-base +rpcd-mod-ucode +unzip \
	+ca-bundle +ip-full \
	+kmod-sched-core +kmod-sched-bpf +kmod-veth +kmod-nft-queue \
	+@KERNEL_XDP_SOCKETS \
	+HONK_USE_VMLINUX_BTF:vmlinux-btf

include $(TOPDIR)/feeds/luci/luci.mk

# ---------------------------------------------------------------------------
# Embedded geodata.
#
# The runtime loads /usr/share/v2ray/geosite.dat and geoip.dat directly, so we
# embed them at build time instead of depending on the large, slowly updated
# v2ray-geoip / v2ray-geosite packages. Sources are the same ones the LuCI UI
# offers for online refresh:
#   geosite.dat: MetaCubeX/meta-rules-dat release
#   geoip.dat:   QiuSimons/geoip-moedove (lightweight)
#
# Both are refreshed frequently upstream; HASH is intentionally skipped here.
# scripts/update_geodata.sh verifies the sources and prints sizes/hashes for
# release review. To opt out of embedding, delete the two Download blocks and
# restore +v2ray-geoip +v2ray-geosite in LUCI_DEPENDS.
# ---------------------------------------------------------------------------
define Download/geosite
	URL:=https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/
	FILE:=geosite.dat
	HASH:=skip
endef
$(eval $(call Download,geosite))

define Download/geoip
	URL:=https://raw.githubusercontent.com/QiuSimons/geoip-moedove/refs/heads/main/
	FILE:=geoip.dat
	HASH:=skip
endef
$(eval $(call Download,geoip))

define Package/luci-app-honk/config
	choice
		prompt "BTF source for CO-RE"
		default HONK_USE_KERNEL_BTF
		depends on PACKAGE_luci-app-honk

	config HONK_USE_KERNEL_BTF
		bool "Use kernel BTF (integrated)"
		depends on KERNEL_DEBUG_INFO_BTF

	config HONK_USE_VMLINUX_BTF
		bool "Use vmlinux-btf package"
	endchoice
endef

define Package/luci-app-honk/conffiles
/etc/honk/config.dae
/etc/honk/config.d/
/etc/config/honk
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)/root
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR) --strip-components=1
	$(CP) -r $(CURDIR)/root/* $(PKG_BUILD_DIR)/root/
	mkdir -p $(PKG_BUILD_DIR)/root/usr/bin $(PKG_BUILD_DIR)/root/usr/share/v2ray
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/honk-core $(PKG_BUILD_DIR)/root/usr/bin/honk-core
	$(INSTALL_DATA) $(DL_DIR)/geosite.dat $(PKG_BUILD_DIR)/root/usr/share/v2ray/geosite.dat
	$(INSTALL_DATA) $(DL_DIR)/geoip.dat $(PKG_BUILD_DIR)/root/usr/share/v2ray/geoip.dat
endef

define Package/luci-app-honk/install
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
endef

$(eval $(call BuildPackage,luci-app-honk))
