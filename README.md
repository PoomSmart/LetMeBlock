# LetMeBlock
Makes mDNSResponder care about `/etc/hosts` on iOS 12, and load **all** entries on iOS 9+

In order to load all entries on iOS 9+, the memory limits defined in `Version4 > Daemon > Override > com.apple.mDNSResponder.reloaded` of the jetsam properties plist **must be increased**.

If in any cases the tweak does not seem to work, you either
* Reinstall LetMeBlock from Cydia
* Run the command `killall -9 mDNSResponder` as root
