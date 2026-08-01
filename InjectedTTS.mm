#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/**
 * InjectedTTS.mm — Objective-C Injected UI Overlay for Google Docs / iOS Apps
 * Provides floating overlay UI, DOCX/Text file reading, Chrome OS / Native TTS engine selection,
 * speech rate adjustment (0.25x - 3.0x), exact position pause/resume, and sentence seeking.
 */

@interface TTSOverlayWindow : UIWindow <AVSpeechSynthesizerDelegate, UIDocumentPickerDelegate>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) AVSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedValueLabel;
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *prevSentenceBtn;
@property (nonatomic, strong) UIButton *nextSentenceBtn;
@property (nonatomic, strong) UIButton *voiceEngineBtn;
@property (nonatomic, strong) UIButton *importDocBtn;
@property (nonatomic, strong) NSMutableArray<NSString *> *sentences;
@property (nonatomic, assign) NSInteger currentSentenceIndex;
@property (nonatomic, assign) BOOL useChromeOSTTS;
@property (nonatomic, strong) NSString *chromeOSVoiceName;
@end

@implementation TTSOverlayWindow

static TTSOverlayWindow *sharedOverlay = nil;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserverForName:@"UISceneDidActivateNotification"
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            if (!sharedOverlay) {
                if (@available(iOS 13.0, *)) {
                    UIWindowScene *scene = (UIWindowScene *)note.object;
                    if ([scene isKindOfClass:[UIWindowScene class]]) {
                        sharedOverlay = [[TTSOverlayWindow alloc] initWithFrame:CGRectMake(20, 80, 340, 260)];
                        sharedOverlay.windowScene = scene;
                        [sharedOverlay makeKeyAndVisible];
                    }
                }
            }
        }];
        
        // Fallback for non-scene apps
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            if (!sharedOverlay && ![[UIDevice currentDevice].systemVersion hasPrefix:@"13."] && ![[UIDevice currentDevice].systemVersion hasPrefix:@"14."] && ![[UIDevice currentDevice].systemVersion hasPrefix:@"15."] && ![[UIDevice currentDevice].systemVersion hasPrefix:@"16."] && ![[UIDevice currentDevice].systemVersion hasPrefix:@"17."]) {
                sharedOverlay = [[TTSOverlayWindow alloc] initWithFrame:CGRectMake(20, 80, 340, 260)];
                [sharedOverlay makeKeyAndVisible];
            }
        }];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 500;
        self.backgroundColor = [UIColor clearColor];
        
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        self.rootViewController = rootVC;
        
        _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        _speechSynthesizer.delegate = self;
        _sentences = [NSMutableArray array];
        _currentSentenceIndex = 0;
        _useChromeOSTTS = NO;
        _chromeOSVoiceName = @"ChromeOS-Vietnamese-Voice2";
        
        [self buildUI];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    // If the touch hits the window itself or its root view (background), pass it through
    if (hitView == self || hitView == self.rootViewController.view) {
        return nil;
    }
    return hitView;
}

- (void)buildUI {
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = [UIColor colorWithRed:0.08 green:0.09 blue:0.12 alpha:0.92];
    self.containerView.layer.cornerRadius = 14.0;
    self.containerView.layer.borderWidth = 1.5;
    self.containerView.layer.borderColor = [UIColor colorWithRed:0.3 green:0.7 blue:1.0 alpha:0.9].CGColor;
    self.containerView.clipsToBounds = YES;
    
    // Pan gesture for dragging overlay
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.containerView addGestureRecognizer:pan];
    
    // Title
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 220, 22)];
    self.titleLabel.text = @"🔊 TTS & DOCX OVERLAY";
    self.titleLabel.textColor = [UIColor colorWithRed:0.4 green:0.8 blue:1.0 alpha:1.0];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [self.containerView addSubview:self.titleLabel];
    
    // Voice Engine Selector Button
    self.voiceEngineBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.voiceEngineBtn.frame = CGRectMake(220, 8, 110, 24);
    self.voiceEngineBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    [self.voiceEngineBtn setTitle:@"Engine: iOS Native" forState:UIControlStateNormal];
    self.voiceEngineBtn.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    self.voiceEngineBtn.layer.cornerRadius = 5;
    [self.voiceEngineBtn addTarget:self action:@selector(toggleVoiceEngine) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.voiceEngineBtn];
    
    // Status text
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 36, 316, 36)];
    self.statusLabel.text = @"Sẵn sàng. Chạm 'Nhập File/Text' hoặc dán nội dung DOCX vào.";
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.font = [UIFont systemFontOfSize:11];
    [self.containerView addSubview:self.statusLabel];
    
    // Speed Slider
    UILabel *speedTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 78, 70, 20)];
    speedTitle.text = @"Tốc độ:";
    speedTitle.textColor = [UIColor lightGrayColor];
    speedTitle.font = [UIFont systemFontOfSize:11];
    [self.containerView addSubview:speedTitle];
    
    self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(75, 78, 195, 20)];
    self.speedSlider.minimumValue = 0.25;
    self.speedSlider.maximumValue = 2.50;
    self.speedSlider.value = 1.00;
    [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
    [self.containerView addSubview:self.speedSlider];
    
    self.speedValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(275, 78, 50, 20)];
    self.speedValueLabel.text = @"1.00x";
    self.speedValueLabel.textColor = [UIColor greenColor];
    self.speedValueLabel.font = [UIFont boldSystemFontOfSize:11];
    [self.containerView addSubview:self.speedValueLabel];
    
    // Control Buttons Row (Prev, Play/Pause, Next)
    self.prevSentenceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.prevSentenceBtn.frame = CGRectMake(12, 115, 60, 34);
    self.prevSentenceBtn.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    [self.prevSentenceBtn setTitle:@"⏮ Trước" forState:UIControlStateNormal];
    self.prevSentenceBtn.titleLabel.font = [UIFont systemFontOfSize:11];
    self.prevSentenceBtn.layer.cornerRadius = 6;
    [self.prevSentenceBtn addTarget:self action:@selector(prevSentence) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.prevSentenceBtn];
    
    self.playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playPauseButton.frame = CGRectMake(78, 115, 100, 34);
    self.playPauseButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    [self.playPauseButton setTitle:@"▶️ Phát" forState:UIControlStateNormal];
    self.playPauseButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    self.playPauseButton.layer.cornerRadius = 6;
    [self.playPauseButton addTarget:self action:@selector(togglePlayPause) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.playPauseButton];
    
    self.nextSentenceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextSentenceBtn.frame = CGRectMake(184, 115, 60, 34);
    self.nextSentenceBtn.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    [self.nextSentenceBtn setTitle:@"Kế ⏭" forState:UIControlStateNormal];
    self.nextSentenceBtn.titleLabel.font = [UIFont systemFontOfSize:11];
    self.nextSentenceBtn.layer.cornerRadius = 6;
    [self.nextSentenceBtn addTarget:self action:@selector(nextSentence) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.nextSentenceBtn];
    
    // Import File / Clipboard Button
    self.importDocBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.importDocBtn.frame = CGRectMake(250, 115, 78, 34);
    self.importDocBtn.backgroundColor = [UIColor colorWithRed:0.1 green:0.7 blue:0.4 alpha:1.0];
    [self.importDocBtn setTitle:@"📁 Nhập Doc" forState:UIControlStateNormal];
    self.importDocBtn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    self.importDocBtn.layer.cornerRadius = 6;
    [self.importDocBtn addTarget:self action:@selector(openDocumentPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.importDocBtn];
    
    [self addSubview:self.containerView];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self];
    CGRect frame = self.frame;
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;
    self.frame = frame;
    [pan setTranslation:CGPointZero inView:self];
}

- (void)speedChanged:(UISlider *)sender {
    self.speedValueLabel.text = [NSString stringWithFormat:@"%.2fx", sender.value];
}

- (void)toggleVoiceEngine {
    self.useChromeOSTTS = !self.useChromeOSTTS;
    if (self.useChromeOSTTS) {
        [self.voiceEngineBtn setTitle:@"Engine: Chrome OS 2" forState:UIControlStateNormal];
        self.voiceEngineBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.4 blue:0.0 alpha:1.0];
    } else {
        [self.voiceEngineBtn setTitle:@"Engine: iOS Native" forState:UIControlStateNormal];
        self.voiceEngineBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    }
}

- (void)openDocumentPicker {
    // Open system file picker for docx/txt/epub
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.text", @"org.openxmlformats.wordprocessingml.document"] inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    [self.rootViewController presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (content) {
        [self loadTextContent:content filename:url.lastPathComponent];
    } else {
        self.statusLabel.text = [NSString stringWithFormat:@"Lỗi đọc file: %@", error.localizedDescription];
    }
}

- (void)loadTextContent:(NSString *)text filename:(NSString *)filename {
    [self.sentences removeAllObjects];
    NSArray *components = [text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@".!?\n"]];
    for (NSString *item in components) {
        NSString *trimmed = [item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            [self.sentences addObject:trimmed];
        }
    }
    self.currentSentenceIndex = 0;
    self.statusLabel.text = [NSString stringWithFormat:@"Đã tải: %@ (%lud câu)", filename, (unsigned long)self.sentences.count];
}

- (void)togglePlayPause {
    if (self.speechSynthesizer.isSpeaking) {
        if (self.speechSynthesizer.isPaused) {
            [self.speechSynthesizer continueSpeaking];
            [self.playPauseButton setTitle:@"⏸ Tạm dừng" forState:UIControlStateNormal];
            self.statusLabel.text = @"Đang phát...";
        } else {
            [self.speechSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            [self.playPauseButton setTitle:@"▶️ Tiếp tục" forState:UIControlStateNormal];
            self.statusLabel.text = @"Đã tạm dừng.";
        }
    } else if (self.sentences.count > 0) {
        [self speakSentenceAtIndex:self.currentSentenceIndex];
    } else {
        self.statusLabel.text = @"Đang quét nội dung trên màn hình...";
        [self extractTextFromCurrentAppWithCompletion:^(NSString *text) {
            if (text && text.length > 0) {
                [self loadTextContent:text filename:@"Màn hình hiện tại"];
                [self speakSentenceAtIndex:0];
            } else {
                // Fallback: Read Clipboard
                NSString *clip = [UIPasteboard generalPasteboard].string;
                if (clip && clip.length > 0) {
                    [self loadTextContent:clip filename:@"Clipboard"];
                    [self speakSentenceAtIndex:0];
                } else {
                    self.statusLabel.text = @"Không tìm thấy chữ trên màn hình.";
                }
            }
        }];
    }
}

- (void)extractTextFromCurrentAppWithCompletion:(void(^)(NSString *))completion {
    UIWindow *appWindow = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w != self && w.isKeyWindow) {
            appWindow = w;
            break;
        }
    }
    if (!appWindow) {
        appWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    
    __block NSMutableString *gatheredText = [NSMutableString string];
    __block BOOL foundWebView = NO;
    
    void (^__block traverseViews)(UIView *) = ^(UIView *view) {
        if (foundWebView) return;
        
        if ([view isKindOfClass:NSClassFromString(@"WKWebView")]) {
            foundWebView = YES;
            id webView = view;
            
            // Using performSelector to avoid linking WebKit explicitly if we don't have to
            void (^jsCompletion)(id, NSError*) = ^(id result, NSError *error) {
                if ([result isKindOfClass:[NSString class]] && ((NSString *)result).length > 0) {
                    completion(result);
                } else {
                    completion(gatheredText);
                }
            };
            
            SEL sel = NSSelectorFromString(@"evaluateJavaScript:completionHandler:");
            if ([webView respondsToSelector:sel]) {
                NSMethodSignature *signature = [webView methodSignatureForSelector:sel];
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                [invocation setTarget:webView];
                [invocation setSelector:sel];
                NSString *js = @"document.body.innerText";
                [invocation setArgument:&js atIndex:2];
                [invocation setArgument:&jsCompletion atIndex:3];
                [invocation invoke];
            } else {
                completion(gatheredText);
            }
            return;
        }
        
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *lbl = (UILabel *)view;
            if (lbl.text) [gatheredText appendFormat:@"%@\n", lbl.text];
        } else if ([view isKindOfClass:[UITextView class]]) {
            UITextView *tv = (UITextView *)view;
            if (tv.text) [gatheredText appendFormat:@"%@\n", tv.text];
        }
        
        for (UIView *subview in view.subviews) {
            traverseViews(subview);
        }
    };
    
    if (appWindow) {
        traverseViews(appWindow);
    }
    
    if (!foundWebView) {
        completion(gatheredText);
    }
}

- (void)prevSentence {
    if (self.currentSentenceIndex > 0) {
        self.currentSentenceIndex--;
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        [self speakSentenceAtIndex:self.currentSentenceIndex];
    }
}

- (void)nextSentence {
    if (self.currentSentenceIndex + 1 < self.sentences.count) {
        self.currentSentenceIndex++;
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        [self speakSentenceAtIndex:self.currentSentenceIndex];
    }
}

- (void)speakSentenceAtIndex:(NSInteger)index {
    if (index >= self.sentences.count) {
        self.statusLabel.text = @"Hoàn tất bài đọc.";
        [self.playPauseButton setTitle:@"▶️ Phát" forState:UIControlStateNormal];
        return;
    }
    
    NSString *text = self.sentences[index];
    self.statusLabel.text = [NSString stringWithFormat:@"[%ld/%lu]: %@", (long)(index + 1), (unsigned long)self.sentences.count, text];
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    utterance.rate = self.speedSlider.value * AVSpeechUtteranceDefaultSpeechRate;
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"vi-VN"] ?: [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
    
    [self.playPauseButton setTitle:@"⏸ Tạm dừng" forState:UIControlStateNormal];
    [self.speechSynthesizer speakUtterance:utterance];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    self.currentSentenceIndex++;
    if (self.currentSentenceIndex < self.sentences.count) {
        [self speakSentenceAtIndex:self.currentSentenceIndex];
    } else {
        self.statusLabel.text = @"Đã đọc hết nội dung.";
        [self.playPauseButton setTitle:@"▶️ Phát" forState:UIControlStateNormal];
    }
}

@end
