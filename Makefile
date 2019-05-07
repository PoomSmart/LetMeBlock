PACKAGE_VERSION = 0.0.6.6

TARGET = iphone:clang:latest:9.0
ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LetMeBlock
LetMeBlock_FILES = Tweak.xm
LetMeBlock_LIBRARIES = Substitrate

include $(THEOS_MAKE_PATH)/tweak.mk


