#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <stdarg.h>

static void GDTLog(NSString *format, ...) { va_list args; va_start(args, format); NSLogv([NSString stringWithFormat:@"[GoogleDocsTTS] %@", format], args); va_end(args); }

%ctor {
    @autoreleasepool {
        Class cls = NSClassFromString(@"UIViewController");
        SEL original = @selector(viewDidAppear:);
        SEL replacement = @selector(gdt_viewDidAppear:);
        Method method = class_getInstanceMethod(cls, original);
        Method hook = class_getInstanceMethod(cls, replacement);
        if (method && hook) method_exchangeImplementations(method, hook);
        GDTLog(@"loaded; feature flags parser=1 speech=1 background=0");
    }
}
