PACKAGE_VERSION = 0.0.6.5

TARGET = iphone:latest:9.0
ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LetMeBlock
LetMeBlock_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk


