#import <UIKit/UIKit.h>

static BOOL xrayEnabled = NO;
static UIWindow *overlayWindow = nil;
static UIButton *toggleButton = nil;

// Xray用リソースパックを書き出す関数
static void generateXrayPack(BOOL enable) {
    // マイクラのパス (TrollStore等でインストールされている前提)
    // 実際のサンドボックスパスは環境によって変わるため、Documents等の書き込み可能な場所に作る
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *packDir = [docsDir stringByAppendingPathComponent:@"XrayPack"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (enable) {
        // リソースパックのディレクトリ作成
        [fm createDirectoryAtPath:[packDir stringByAppendingPathComponent:@"textures/blocks"] withIntermediateDirectories:YES attributes:nil error:nil];
        
        // manifest.json 作成
        NSString *manifest = @"{\"format_version\": 2, \"header\": {\"description\": \"Xray Pack\", \"name\": \"Xray\", \"uuid\": \"11111111-1111-1111-1111-111111111111\", \"version\": [1, 0, 0], \"min_engine_version\": [1, 16, 0]}, \"modules\": [{\"description\": \"Xray Module\", \"type\": \"resources\", \"uuid\": \"22222222-2222-2222-2222-222222222222\", \"version\": [1, 0, 0]}]}";
        [manifest writeToFile:[packDir stringByAppendingPathComponent:@"manifest.json"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        // 透明なPNGデータ（1x1の透明ピクセル）を作成して、石系ブロックに上書きする
        // 1x1の透明PNGのBase64データ
        NSString *transparentPngBase64 = @"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
        NSData *pngData = [[NSData alloc] initWithBase64EncodedString:transparentPngBase64 options:0];
        
        // 透けさせたいブロックのリスト (Bedrockのテクスチャ名)
        NSArray *blocksToMakeInvisible = @[
            @"stone", @"cobblestone", @"dirt", @"grass_side", @"grass_top", 
            @"sand", @"gravel", @"andesite", @"diorite", @"granite", 
            @"coal_ore", @"iron_ore", @"gold_ore", @"diamond_ore", 
            @"emerald_ore", @"lapis_ore", @"redstone_ore", @"copper_ore",
            @"deepslate", @"cobbled_deepslate", @"tuff", @"calcite", @"basalt"
        ];
        
        for (NSString *block in blocksToMakeInvisible) {
            NSString *filePath = [packDir stringByAppendingPathComponent:[NSString stringWithFormat:@"textures/blocks/%@.png", block]];
            [pngData writeToFile:filePath atomically:YES];
        }
        
        NSLog(@"[Xray] Resource pack generated at %@", packDir);
        // ここでマイクラに対してリソースパックを適用する命令を送る必要があるが、
        // iOSのサンドボックス制限により、自動適用は難しい。
        // 実運用では、生成したパックを手動でインポートするか、
        // マイクラ内部のAPIをフックしてパスを強制指定する必要がある。
    } else {
        // オフにしたときはディレクトリごと削除
        [fm removeItemAtPath:packDir error:nil];
        NSLog(@"[Xray] Resource pack removed");
    }
}

static void toggleXray(void) {
    xrayEnabled = !xrayEnabled;
    generateXrayPack(xrayEnabled);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [toggleButton setTitle:xrayEnabled ? @"Xray: ON" : @"Xray: OFF"
                     forState:UIControlStateNormal];
        [toggleButton setTitleColor:xrayEnabled ? [UIColor greenColor] : [UIColor whiteColor] forState:UIControlStateNormal];
    });
}

static void setupOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.windowLevel = UIWindowLevelAlert + 100;
        window.backgroundColor = [UIColor clearColor];
        
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        // タッチを透過させるための設定
        rootVC.view.userInteractionEnabled = YES; 
        window.rootViewController = rootVC;
        window.hidden = NO;
        overlayWindow = window;

        toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        toggleButton.frame = CGRectMake(20, 100, 140, 44);
        [toggleButton setTitle:@"Xray: OFF" forState:UIControlStateNormal];
        [toggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        toggleButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        toggleButton.layer.cornerRadius = 8;
        toggleButton.userInteractionEnabled = YES;

        // タッチイベントの追加
        if (@available(iOS 14.0, *)) {
            [toggleButton addAction:[UIAction actionWithHandler:^(UIAction *action) {
                toggleXray();
            }] forControlEvents:UIControlEventTouchUpInside];
        } else {
            [toggleButton addTarget:NSClassFromString(@"NSObject")
                             action:@selector(toggleXray)
                   forControlEvents:UIControlEventTouchUpInside];
        }

        [rootVC.view addSubview:toggleButton];
    });
}

%ctor {
    NSLog(@"[Xray] dylib loaded");
    setupOverlay();
}
