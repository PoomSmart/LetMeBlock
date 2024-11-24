PACKAGE_VERSION = 1.3.0
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e
else
TARGET = iphone:clang:14.5:9.0
export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LetMeBlock
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_LIBRARIES = sandy
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
