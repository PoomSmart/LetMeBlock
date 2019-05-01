#import "../PS.h"
#import <substrate.h>
#import <xpc/xpc.h>

#include <stdlib.h>
#include <errno.h>
#include <sys/sysctl.h>
#include <sys/kern_memorystatus.h>

#define DEFAULT_HOSTS_PATH "/etc/hosts"
#define NEW_HOSTS_PATH "/etc/hosts.lmb"

%group mDNSResponder

unsigned int *_mDNS_StatusCallback_allocated = NULL;

// Allow /etc/hosts to be read on iOS 12
%hookf(bool, "_os_variant_has_internal_diagnostics", const char *subsystem) {
	if (subsystem && strcmp(subsystem, "com.apple.mDNSResponder") == 0)
		return 1;
	return %orig;
}

// Reset the memory counter every time it is increased
%hookf(void, "_mDNS_StatusCallback", void *arg1, int arg2) {
	if (_mDNS_StatusCallback_allocated)
		*_mDNS_StatusCallback_allocated = 0;
	%orig;
}

// Open UHB's hosts instead of /etc/hosts
// This new UHB will place all the blocked addresses to NEW_HOSTS_PATH so we won't mess up with the original file
// If in any cases NEW_HOSTS_PATH got corrupted, we fallback to the original one (DEFAULT_HOSTS_PATH)
%hookf(int, "_open", const char *path, int oflag, ...) {
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

%hookf(FILE *, "_fopen", const char *path, const char *mode) {
	if (path && strcmp(path, DEFAULT_HOSTS_PATH) == 0) {
		FILE *r = %orig(NEW_HOSTS_PATH, mode);
		return r ? r : %orig;
	}
	return %orig;
}

%end

%group mDNSResponderHelper

// iOS 10? - 12
%hookf(void, "___accept_client_block_invoke", int arg0, xpc_object_t object) {
	%orig;
	if (xpc_get_type(object) != XPC_TYPE_DICTIONARY) {
		// If this happens, mDNSResponderHelper assumes that mDNSResponder died - and yes, we want the helper to die too
		kill(getpid(), SIGKILL);
	}
}

// iOS 9
%hookf(void, "_proxy_mDNSExit", int arg0) {
	%orig;
	kill(getpid(), SIGKILL);
}

%end

%ctor {
	_mDNS_StatusCallback_allocated = (unsigned int *)PSFindSymbolReadable(NULL, "_mDNS_StatusCallback.allocated");
	if (_mDNS_StatusCallback_allocated) {
		// mDNSResponder (_mDNSResponder)
		HBLogDebug(@"LetMeBlock: run on mDNSResponder");
		%init(mDNSResponder);
	} else {
		// mDNSResponderHelper (root)
		HBLogDebug(@"LetMeBlock: run on mDNSResponderHelper");
		pid_t pid = 0;
		int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
		size_t size;
		if (sysctl(mib, 4, NULL, &size, NULL, 0) == -1)
			HBLogError(@"LetMeBlock-jetsamctl: error: %s", strerror(errno));
		else {
			struct kinfo_proc *processes = (struct kinfo_proc *)malloc(size);
			if (processes == NULL)
				HBLogError(@"LetMeBlock-jetsamctl: error: %s", strerror(errno));
			else if (sysctl(mib, 4, processes, &size, NULL, 0) == -1)
				HBLogError(@"LetMeBlock-jetsamctl: error: %s", strerror(errno));
			else {
				for (unsigned long i = 0; i < size / sizeof(struct kinfo_proc); i++) {
					if (strcmp(processes[i].kp_proc.p_comm, "mDNSResponder") == 0) {
						pid = processes[i].kp_proc.p_pid;
						break;
					}
				}
				if (pid == 0)
					HBLogError(@"LetMeBlock-jetsamctl: error: %s", strerror(ESRCH));
				else if (memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, pid, 384, NULL, 0) == -1)
					HBLogError(@"LetMeBlock-jetsamctl: error: %s", strerror(errno));
			}
			if (processes)
				free(processes);
		}
		%init(mDNSResponderHelper);
	}
}