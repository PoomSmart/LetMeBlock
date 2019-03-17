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

// The new UHB will place all the blocked addresses to /etc/hosts2 so we won't mess up with the original file
// If in any cases /etc/hosts2 got corrupted, we fallback to the original one
%hookf(int, open, const char *path, int oflag, ...) {
    int result = 0;
	bool orig = false;
hook:
	if (!orig && path && strcmp(path, "/etc/hosts") == 0)
		path = "/etc/hosts2";
    if (oflag & O_CREAT) {
        mode_t mode;
        va_list args;
        va_start(args, oflag);
        mode = (mode_t)va_arg(args, int);
        va_end(args);
        result = %orig(path, oflag, mode);
    }
    else
        result = %orig(path, oflag);
    if (!orig && result == -1) {
		orig = true;
		path = "/etc/hosts";
		goto hook;
	}
	return result;
}

%ctor {
	_mDNS_StatusCallback_allocated = (unsigned int *)MSFindSymbol(NULL, "_mDNS_StatusCallback.allocated");
	HBLogDebug(@"Found _mDNS_StatusCallback_allocated: %d", _mDNS_StatusCallback_allocated != NULL);
	%init;
}