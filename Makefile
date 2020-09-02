PACKAGE_VERSION = 0.0.7.4

TARGET = iphone:clang:latest:9.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LetMeBlock
LetMeBlock_FILES = Tweak.xm
LetMeBlock_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
