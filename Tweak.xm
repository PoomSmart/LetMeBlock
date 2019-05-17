#import "../PS.h"
#import <substrate.h>
#import "../libsubstitrate/substitrate.h"
#import <xpc/xpc.h>

#include <errno.h>
#include <sys/sysctl.h>
#include <sys/kern_memorystatus.h>

#define DEFAULT_HOSTS_PATH "/etc/hosts"
#define NEW_HOSTS_PATH "/etc/hosts.lmb"

%group mDNSResponder

unsigned int *mDNS_StatusCallback_allocated = NULL;

// Allow /etc/hosts to be read on iOS 12
bool (*_os_variant_has_internal_diagnostics)(const char *) = NULL;
bool os_variant_has_internal_diagnostics(const char *subsystem) {
	if (subsystem && strcmp(subsystem, "com.apple.mDNSResponder") == 0)
		return 1;
	return _os_variant_has_internal_diagnostics(subsystem);
}

// Reset the memory counter every time it is increased
void (*_mDNS_StatusCallback)(void *, int) = NULL;
void mDNS_StatusCallback(void *arg1, int arg2) {
	if (mDNS_StatusCallback_allocated)
		*mDNS_StatusCallback_allocated = 0;
	_mDNS_StatusCallback(arg1, arg2);
}

// Open UHB's hosts instead of DEFAULT_HOSTS_PATH
// This new UHB will place all the blocked addresses to NEW_HOSTS_PATH so we won't mess up with the original file
// If in any cases NEW_HOSTS_PATH got corrupted, we fallback to the original one (DEFAULT_HOSTS_PATH)
FILE *(*_fopen)(const char *, const char *);
FILE *fopen(const char *path, const char *mode) {
	if (path && strcmp(path, DEFAULT_HOSTS_PATH) == 0) {
		FILE *r = _fopen(NEW_HOSTS_PATH, mode);
		if (r) return r;
	}
	return _fopen(path, mode);
}

%end

%ctor {
	mDNS_StatusCallback_allocated = (unsigned int *)PSFindSymbolReadableCompat(NULL, "_mDNS_StatusCallback.allocated");
	if (mDNS_StatusCallback_allocated) {
		// mDNSResponder (_mDNSResponder)
		HBLogDebug(@"LetMeBlock: run on mDNSResponder");
		_PSHookFunctionCompat(NULL, "_mDNS_StatusCallback", mDNS_StatusCallback);
		_PSHookFunctionCompat("/usr/lib/system/libsystem_darwin.dylib", "_os_variant_has_internal_diagnostics", os_variant_has_internal_diagnostics);
		_PSHookFunctionCompat("/usr/lib/system/libsystem_c.dylib", "_fopen", fopen);
		%init(mDNSResponder);
		// Spawn mDNSResponderHelper if not already so that it will unlock mDNSResponder's memory limit as soon as possible
		void (*Init_Connection)(void) = (void (*)(void))PSFindSymbolCallableCompat(NULL, "_Init_Connection");
		if (Init_Connection)
			Init_Connection();
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
				for (unsigned long i = 0; i < size / sizeof(struct kinfo_proc); ++i) {
					if (strcmp(processes[i].kp_proc.p_comm, "mDNSResponder") == 0) {
						pid = processes[i].kp_proc.p_pid;
						if (memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, pid, 384, NULL, 0) == -1)
							HBLogError(@"LetMeBlock-jetsamctl: error: %s", strerror(errno));
						else
							HBLogDebug(@"LetMeBlock-jetsamctl: Successfully unlocked mDNSResponder's memory limit");
						break;
					}
				}
				if (pid == 0)
					HBLogError(@"LetMeBlock-jetsamctl: error: %s", strerror(ESRCH));
			}
			if (processes)
				free(processes);
		}
	}
}