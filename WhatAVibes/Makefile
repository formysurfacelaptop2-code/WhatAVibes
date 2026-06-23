TARGET := iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = Music

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WhatAVibes

WhatAVibes_FILES = Tweak.xm
WhatAVibes_CFLAGS = -fobjc-arc
WhatAVibes_FRAMEWORKS = UIKit CoreGraphics QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
