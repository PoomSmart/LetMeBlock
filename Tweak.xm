#import <substrate.h>

unsigned int *_mDNS_StatusCallback_allocated = NULL;

%hookf(bool, "_os_variant_has_internal_diagnostics", const char *subsystem) {
	if (subsystem && strcmp(subsystem, "com.apple.mDNSResponder") == 0)
		return 1;
	return %orig;
}

%hookf(void, "_mDNS_StatusCallback", void *arg1, int arg2) {
	if (_mDNS_StatusCallback_allocated)
		*_mDNS_StatusCallback_allocated = 0;
	%orig;
}

%ctor {
	_mDNS_StatusCallback_allocated = (unsigned int *)MSFindSymbol(NULL, "_mDNS_StatusCallback.allocated");
	HBLogDebug(@"Found _mDNS_StatusCallback_allocated: %d", _mDNS_StatusCallback_allocated != NULL);
	%init;
}