TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := GoogleDocsTTS
GoogleDocsTTS_FILES := Tweak.xm Sources/GDTModels.mm Sources/GDTParser.mm Sources/GDTEngine.mm Sources/GDTStores.mm Sources/GDTControllers.mm Sources/GDTHighlight.mm Sources/GDTPlayback.mm Sources/GDTQueue.mm Sources/GDTSettingsPanel.mm Sources/GDTMiniPlayer.mm
GoogleDocsTTS_CXXFLAGS := -std=c++17 -fobjc-arc -I./Headers
GoogleDocsTTS_FRAMEWORKS := UIKit WebKit AVFoundation MediaPlayer
GoogleDocsTTS_LIBRARIES := sqlite3
GoogleDocsTTS_PRIVATE_FRAMEWORKS :=
GoogleDocsTTS_EXTRA_FRAMEWORKS :=

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Docs || true"
