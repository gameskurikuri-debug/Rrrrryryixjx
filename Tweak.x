#import <UIKit/UIKit.h>

static BOOL xrayEnabled = NO;
static UIWindow *overlayWindow = nil;
static UIButton *toggleButton = nil;

static void applyXray(BOOL enable) {
    NSLog(@"[Xray] %@", enable ? @"ON" : @"OFF");
}

static void toggleXray(void) {
    xrayEnabled = !xrayEnabled;
    applyXray(xrayEnabled);
    dispatch_async(dispatch_get_main_queue(), ^{
        [toggleButton setTitle:xrayEnabled ? @"Xray: ON" : @"Xray: OFF"
                     forState:UIControlStateNormal];
    });
}

static void setupOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelAlert + 100;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.rootViewController = [[UIViewController alloc] init];
        overlayWindow.hidden = NO;

        toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        toggleButton.frame = CGRectMake(20, 100, 140, 44);
        [toggleButton setTitle:@"Xray: OFF" forState:UIControlStateNormal];
        toggleButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        toggleButton.layer.cornerRadius = 8;
        [toggleButton addAction:[UIAction actionWithHandler:^(UIAction *a) {
            toggleXray();
        }] forControlEvents:UIControlEventTouchUpInside];

        [overlayWindow.rootViewController.view addSubview:toggleButton];
    });
}

%ctor {
    NSLog(@"[Xray] dylib loaded");
    setupOverlay();
}
