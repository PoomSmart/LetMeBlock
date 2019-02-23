TARGET = iphone:latest:12.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LetMeBlock
LetMeBlock_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk


