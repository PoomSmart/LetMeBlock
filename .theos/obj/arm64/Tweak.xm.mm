#line 1 "Tweak.xm"
#import <substrate.h>


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif




#line 3 "Tweak.xm"
__unused static bool (*_logos_orig$_ungrouped$lookup$_os_variant_has_internal_diagnostics)(const char *subsystem); __unused static bool _logos_function$_ungrouped$lookup$_os_variant_has_internal_diagnostics(const char *subsystem) {
	if (subsystem && strcmp(subsystem, "com.apple.mDNSResponder") == 0)
		return 1;
	return _logos_orig$_ungrouped$lookup$_os_variant_has_internal_diagnostics(subsystem);
}

static __attribute__((constructor)) void _logosLocalCtor_344ae32b(int __unused argc, char __unused **argv, char __unused **envp) {
	{ MSHookFunction((void *)MSFindSymbol(NULL, "_os_variant_has_internal_diagnostics"), (void *)&_logos_function$_ungrouped$lookup$_os_variant_has_internal_diagnostics, (void **)&_logos_orig$_ungrouped$lookup$_os_variant_has_internal_diagnostics);}
}
