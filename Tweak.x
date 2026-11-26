#import <UIKit/UIKit.h>

static BOOL xrayEnabled = NO;
static UIWindow *overlayWindow = nil;
static UIButton *toggleButton = nil;

// タッチイベントを透過させるカスタムウィンドウ
@interface PassthroughWindow : UIWindow
@end

@implementation PassthroughWindow
// このウィンドウ自体はタッチを受け付けない
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return NO;
}
@end

// ボタンの領域だけタッチを受け付けるコンテナビュー
@interface TouchView : UIView
@end

@implementation TouchView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 子ビュー（ボタン）の判定を優先
    UIView *hitView = [super hitTest:point withEvent:event];
    // ボタンに当たった場合のみタッチを返す
    if ([hitView isKindOfClass:[UIButton class]]) {
        return hitView;
    }
    return nil;
}
@end

static void applyXray(BOOL enable) {
    NSLog(@"[Xray] %@", enable ? @"ON" : @"OFF");
    // ここにXrayの実処理を書く
}

static void toggleXray(void) {
    xrayEnabled = !xrayEnabled;
    applyXray(xrayEnabled);
    dispatch_async(dispatch_get_main_queue(), ^{
        [toggleButton setTitle:xrayEnabled ? @"Xray: ON" : @"Xray: OFF"
                     forState:UIControlStateNormal];
        [toggleButton setTitleColor:xrayEnabled ? [UIColor greenColor] : [UIColor whiteColor] forState:UIControlStateNormal];
    });
}

static void setupOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        // タッチ透過ウィンドウの生成
        overlayWindow = [[PassthroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelAlert + 100;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.rootViewController = [[UIViewController alloc] init];
        overlayWindow.hidden = NO;

        // ボタンを受け止めるコンテナビュー
        TouchView *containerView = [[TouchView alloc] initWithFrame:overlayWindow.bounds];
        containerView.backgroundColor = [UIColor clearColor];
        [overlayWindow.rootViewController.view addSubview:containerView];

        // トグルボタン本体
        toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        toggleButton.frame = CGRectMake(20, 100, 140, 44);
        [toggleButton setTitle:@"Xray: OFF" forState:UIControlStateNormal];
        [toggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        toggleButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        toggleButton.layer.cornerRadius = 8;
        
        // iOS 14+ の addAction
        if (@available(iOS 14.0, *)) {
            [toggleButton addAction:[UIAction actionWithHandler:^(UIAction *action) {
                toggleXray();
            }] forControlEvents:UIControlEventTouchUpInside];
        } else {
            // フォールバック（iOS 13以下用）
            [toggleButton addTarget:[NSClassFromString(@"NSObject") class]
                             action:@selector(toggleXray)
                   forControlEvents:UIControlEventTouchUpInside];
        }

        [containerView addSubview:toggleButton];
    });
}

%ctor {
    NSLog(@"[Xray] dylib loaded");
    setupOverlay();
}
