#import <substrate.h>

#define DEFAULT_HOSTS_PATH "/etc/hosts"
#define NEW_HOSTS_PATH "/etc/hosts.lmb"

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

// The new UHB will place all the blocked addresses to NEW_HOSTS_PATH so we won't mess up with the original file
// If in any cases NEW_HOSTS_PATH got corrupted, we fallback to the original one (DEFAULT_HOSTS_PATH)
%hookf(int, open, const char *path, int oflag, ...) {
	int result = 0;
	bool orig = false;
hook:
	if (!orig && path && strcmp(path, DEFAULT_HOSTS_PATH) == 0)
		path = NEW_HOSTS_PATH;
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
		path = DEFAULT_HOSTS_PATH;
		goto hook;
	}
	return result;
}

%hookf(FILE *, fopen, const char *path, const char *mode) {
	if (path && strcmp(path, DEFAULT_HOSTS_PATH) == 0) {
		FILE *r = %orig(NEW_HOSTS_PATH, mode);
		return r ? r : %orig;
	}
	return %orig;
}

%ctor {
	_mDNS_StatusCallback_allocated = (unsigned int *)MSFindSymbol(NULL, "_mDNS_StatusCallback.allocated");
	HBLogDebug(@"Found _mDNS_StatusCallback_allocated: %d", _mDNS_StatusCallback_allocated != NULL);
	%init;
}