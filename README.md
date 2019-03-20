# LetMeBlock
Makes mDNSResponder care about `/etc/hosts` on iOS 12, and load **all** entries on iOS 9+

In order to load all entries on iOS 9+, the memory limits defined in `Version4 > Daemon > Override > com.apple.mDNSResponder.reloaded` of the jetsam properties plist **must be increased**. This can be done either by manually editing the plist or using jetsamctl's API, see [here](https://github.com/conradev/jetsamctl).

If in any cases the tweak does not seem to work, you either
* Reinstall LetMeBlock from Cydia
* Run the command `killall -9 mDNSResponder; killall -9 mDNSResponderHelper` as root
