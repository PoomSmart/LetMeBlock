#import <substrate.h>

%hookf(bool, "_os_variant_has_internal_diagnostics", const char *subsystem) {
	if (subsystem && strcmp(subsystem, "com.apple.mDNSResponder") == 0)
		return 1;
	return %orig;
}

%ctor {
	%init;
}