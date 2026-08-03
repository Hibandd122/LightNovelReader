#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "GDTParser.h"
#import "GDTEngine.h"
#import "GDTStores.h"
#import "GDTHighlight.h"
#import "GDTPlayback.h"
#import "GDTSettingsPanel.h"
#import "GDTMiniPlayer.h"

static NSArray<WKWebView *> *GDTAllWebViews(UIView *root);
static UIViewController *GDTViewControllerForView(UIView *view);

@interface GDTReadingController : NSObject
@property(nonatomic, strong) GDTParser *parser;
@property(nonatomic, strong) id<GDTTTSEngine> engine;
@property(nonatomic, strong) id<GDTLibraryStore> store;
@property(nonatomic, strong) id<GDTHighlightEngine> highlighter;
@property(nonatomic, strong) id<GDTPlaybackCoordinator> playback;
@property(nonatomic, strong) GDTMiniPlayerView *miniPlayer;
@property(nonatomic, strong) GDTSettings *settings;
@property(nonatomic, strong) NSTimer *sleepTimer;
@property(nonatomic, strong) NSTimer *wordTimer;
@property(nonatomic, strong) GDTDocument *document;
@property(nonatomic, strong) GDTReadingSession *session;
@property(nonatomic, weak) WKWebView *webView;
@property(nonatomic) BOOL resumePromptShown;
- (void)loadWebView:(WKWebView *)webView;
- (void)loadSelectionFromWebView:(WKWebView *)webView fromCursor:(BOOL)fromCursor;
- (void)pauseOrResume;
- (void)stop;
- (void)bookmarkCurrent;
- (void)presentSettingsFrom:(UIViewController *)presenter;
- (void)installMiniPlayerInView:(UIView *)view;
@end

@implementation GDTReadingController

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _parser = [[GDTParser alloc] initWithSource:[GDTWebTextSource new]
                                      normalizer:[GDTDefaultNormalizer new]
                                       segmenter:[GDTSentenceSegmenter new]];
    _engine = [GDTSpeechEngine new];
    _highlighter = [GDTDOMHighlightEngine new];
    _playback = [GDTSystemPlaybackCoordinator new];
    [_playback configureAudioSession];
    _miniPlayer = [[GDTMiniPlayerView alloc] initWithFrame:CGRectZero];

    NSURL *support = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    [[NSFileManager defaultManager] createDirectoryAtURL:support withIntermediateDirectories:YES attributes:nil error:nil];
    NSError *storeError = nil;
    _store = [[GDTSQLiteStore alloc] initWithURL:[support URLByAppendingPathComponent:@"googledocs-tts.sqlite"] error:&storeError];
    if (!_store) _store = (id<GDTLibraryStore>)[GDTUserDefaultsStore new];
    _settings = [_store settings];

    __weak typeof(self) weakSelf = self;
    _miniPlayer.playPauseAction = ^{ [weakSelf pauseOrResume]; };
    _miniPlayer.stopAction = ^{ [weakSelf stop]; };
    _miniPlayer.bookmarkAction = ^{ [weakSelf bookmarkCurrent]; };
    return self;
}

- (void)loadWebView:(WKWebView *)webView {
    self.webView = webView;
    NSString *documentID = webView.URL.absoluteString ?: @"current";
    self.session = [self.store sessionForDocument:documentID];
    self.resumePromptShown = NO;
    [self scheduleSleepTimer];

    __weak typeof(self) weakSelf = self;
    [self.parser.source readTextFromWebView:webView completion:^(NSString *text, NSError *sourceError) {
        if (sourceError || !text.length) return;
        NSString *normalized = [[GDTDefaultNormalizer new] normalizeText:text];
        NSString *hash = [NSString stringWithFormat:@"%lu", (unsigned long)normalized.hash];
        GDTDocument *cached = [weakSelf.store documentForID:documentID contentHash:hash error:nil];
        if (cached.sentences.count) { weakSelf.document = cached; [weakSelf playCurrent]; return; }
        [weakSelf.parser parseWebView:webView documentID:documentID completion:^(GDTDocument *document, NSError *error) {
            if (error || !document.sentences.count) return;
            weakSelf.document = document;
            [weakSelf.store saveDocument:document error:nil];
            [weakSelf playCurrent];
        }];
    }];
}

- (void)loadSelectionFromWebView:(WKWebView *)webView fromCursor:(BOOL)fromCursor {
    if (![self.parser.source conformsToProtocol:@protocol(GDTSelectionSource)]) return;
    id<GDTSelectionSource> source = (id<GDTSelectionSource>)self.parser.source;
    __weak typeof(self) weakSelf = self;
    [source readSelectedTextFromWebView:webView fromCursor:fromCursor completion:^(NSString *text, NSUInteger offset, NSError *error) {
        if (error) return;
        NSString *documentID = [NSString stringWithFormat:@"%@#selection-%lu", webView.URL.absoluteString ?: @"current", (unsigned long)offset];
        [weakSelf.parser parseText:text documentID:documentID completion:^(GDTDocument *document, NSError *parseError) {
            if (parseError || !document.sentences.count) return;
            weakSelf.webView = webView;
            weakSelf.document = document;
            weakSelf.session = [weakSelf.store sessionForDocument:documentID];
            weakSelf.session.characterOffset = offset;
            weakSelf.resumePromptShown = YES;
            [weakSelf playCurrent];
        }];
    }];
}

- (void)playCurrent {
    self.settings = [self.store settings];
    if (!self.document || !self.document.sentences.count) return;

    if (!self.resumePromptShown && self.session.sentenceIndex > 0 && [self.document.documentID rangeOfString:@"#selection-"].location == NSNotFound) {
        self.resumePromptShown = YES;
        UIViewController *presenter = GDTViewControllerForView(self.webView);
        if (presenter) {
            __weak typeof(self) weakSelf = self;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Continue reading?" message:[NSString stringWithFormat:@"Resume at %.0f%%", self.session.progress * 100.0] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Start over" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { weakSelf.session.sentenceIndex = 0; [weakSelf playCurrent]; }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [weakSelf playCurrent]; }]];
            [presenter presentViewController:alert animated:YES completion:nil];
            return;
        }
    }

    if (self.session.sentenceIndex >= self.document.sentences.count) {
        self.session.sentenceIndex = 0;
        self.session.state = GDTReadingStateFinished;
        [self.store saveSession:self.session];
        return;
    }

    self.session.state = GDTReadingStatePlaying;
    self.session.progress = (float)self.session.sentenceIndex / (float)MAX(1, self.document.sentences.count);
    [self.store saveSession:self.session];
    self.miniPlayer.title = @"Google Docs";
    self.miniPlayer.progress = self.session.progress;
    self.miniPlayer.playing = YES;

    GDTSentence *sentence = self.document.sentences[self.session.sentenceIndex];
    [self.playback updateNowPlayingTitle:@"Google Docs" progress:self.session.progress duration:MAX(1, self.document.text.length / 12.0)];
    if (self.settings.highlightMode == GDTHighlightModeParagraph) {
        [self.highlighter highlightParagraph:[self paragraphForSentence:sentence] inWebView:self.webView autoScroll:self.settings.autoScroll completion:nil];
    } else if (self.settings.highlightMode == GDTHighlightModeWord && sentence.words.count) {
        self.session.wordIndex = 0;
        [self.highlighter highlightWord:sentence.words.firstObject inWebView:self.webView autoScroll:self.settings.autoScroll completion:nil];
        [self startWordTimerForSentence:sentence];
    } else {
        [self.highlighter highlightSentence:sentence inWebView:self.webView autoScroll:self.settings.autoScroll completion:nil];
    }

    __weak typeof(self) weakSelf = self;
    [self.playback removeRemoteCommands];
    [self.playback installRemoteCommandsWithPlay:^{ [weakSelf pauseOrResume]; } pause:^{ [weakSelf pauseOrResume]; } next:^{ [weakSelf.engine stop]; weakSelf.session.sentenceIndex++; [weakSelf playCurrent]; } previous:^{ [weakSelf.engine stop]; weakSelf.session.sentenceIndex = weakSelf.session.sentenceIndex > 0 ? weakSelf.session.sentenceIndex - 1 : 0; [weakSelf playCurrent]; }];

    GDTSpeechRequest *request = [GDTSpeechRequest new];
    request.text = sentence.text;
    request.rate = self.settings.speed;
    request.pitch = self.settings.pitch;
    request.volume = self.settings.volume;
    request.voiceIdentifier = self.settings.voiceIdentifier;
    [self.engine speakRequest:request completion:^(NSError *error) {
        if (error) { weakSelf.session.state = GDTReadingStateFailed; weakSelf.miniPlayer.playing = NO; return; }
        [weakSelf.wordTimer invalidate];
        weakSelf.wordTimer = nil;
        [weakSelf.store recordStatisticsForDocument:weakSelf.document.documentID seconds:MAX(1, sentence.text.length / 12.0) words:sentence.words.count];
        weakSelf.session.sentenceIndex++;
        weakSelf.session.wordIndex = 0;
        weakSelf.session.updatedAt = [NSDate date];
        [weakSelf.store saveSession:weakSelf.session];
        [weakSelf playCurrent];
    }];
}

- (GDTParagraph *)paragraphForSentence:(GDTSentence *)sentence {
    for (GDTSection *section in self.document.sections) for (GDTParagraph *paragraph in section.paragraphs) if (paragraph.index == sentence.paragraphIndex) return paragraph;
    return nil;
}

- (void)startWordTimerForSentence:(GDTSentence *)sentence {
    [self.wordTimer invalidate];
    if (sentence.words.count < 2) return;
    NSTimeInterval interval = MAX(0.12, sentence.text.length / (MAX(0.1, self.settings.speed) * 12.0 * sentence.words.count));
    __weak typeof(self) weakSelf = self;
    self.wordTimer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:YES block:^(NSTimer *timer) {
        if (weakSelf.session.wordIndex + 1 >= sentence.words.count) { [timer invalidate]; weakSelf.wordTimer = nil; return; }
        weakSelf.session.wordIndex++;
        [weakSelf.highlighter highlightWord:sentence.words[weakSelf.session.wordIndex] inWebView:weakSelf.webView autoScroll:NO completion:nil];
    }];
}

- (void)pauseOrResume {
    if (self.session.state == GDTReadingStatePlaying) { [self.engine pause]; self.session.state = GDTReadingStatePaused; self.miniPlayer.playing = NO; }
    else if (self.session.state == GDTReadingStatePaused) { [self.engine resume]; self.session.state = GDTReadingStatePlaying; self.miniPlayer.playing = YES; }
    [self.store saveSession:self.session];
}

- (void)scheduleSleepTimer {
    [self.sleepTimer invalidate];
    self.sleepTimer = nil;
    if (self.settings.sleepTimer <= 0) return;
    __weak typeof(self) weakSelf = self;
    self.sleepTimer = [NSTimer scheduledTimerWithTimeInterval:self.settings.sleepTimer repeats:NO block:^(NSTimer *timer) { [weakSelf stop]; }];
}

- (void)stop {
    [self.engine stop];
    [self.sleepTimer invalidate]; self.sleepTimer = nil;
    [self.wordTimer invalidate]; self.wordTimer = nil;
    [self.playback removeRemoteCommands];
    [self.highlighter clearHighlightInWebView:self.webView];
    self.session.state = GDTReadingStateIdle;
    self.miniPlayer.playing = NO;
    [self.store saveSession:self.session];
}

- (void)bookmarkCurrent {
    if (!self.document || !self.session) return;
    GDTPlaybackPosition *position = [GDTPlaybackPosition new];
    position.documentID = self.document.documentID;
    GDTSentence *current = self.session.sentenceIndex < self.document.sentences.count ? self.document.sentences[self.session.sentenceIndex] : nil;
    position.paragraphIndex = current ? current.paragraphIndex : self.session.paragraphIndex;
    position.sentenceIndex = self.session.sentenceIndex;
    position.wordIndex = self.session.wordIndex;
    position.characterOffset = current ? current.sourceRange.location : self.session.characterOffset;
    position.progress = self.session.progress;
    position.timestamp = [NSDate date];
    __weak typeof(self) weakSelf = self;
    [self.webView evaluateJavaScript:@"window.scrollY || 0" completionHandler:^(id value, NSError *error) { position.scrollOffset = [value doubleValue]; [weakSelf.store saveBookmark:position]; [weakSelf.store recordHistoryForDocument:position.documentID position:position]; }];
}

- (void)presentSettingsFrom:(UIViewController *)presenter {
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:[[GDTSettingsViewController alloc] initWithStore:self.store]];
    navigation.modalPresentationStyle = UIModalPresentationFormSheet;
    [presenter presentViewController:navigation animated:YES completion:nil];
}

- (void)installMiniPlayerInView:(UIView *)view {
    if (self.miniPlayer.superview == view) return;
    self.miniPlayer.tag = 0x47545454;
    self.miniPlayer.frame = CGRectMake(16, MAX(80, CGRectGetHeight(view.bounds) - 76), MAX(0, CGRectGetWidth(view.bounds) - 32), 58);
    self.miniPlayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [view addSubview:self.miniPlayer];
}

@end

static GDTReadingController *GDTController;

static UIViewController *GDTViewControllerForView(UIView *view) {
    UIResponder *responder = view;
    while (responder && ![responder isKindOfClass:UIViewController.class]) responder = responder.nextResponder;
    return (UIViewController *)responder;
}

static void GDTInstallButton(UIViewController *controller) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!GDTController) GDTController = [GDTReadingController new];
        [GDTController installMiniPlayerInView:controller.view];
        if ([controller.view viewWithTag:0x47545453]) return;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = 0x47545453;
        button.frame = CGRectMake(20, 80, 52, 52);
        button.layer.cornerRadius = 26;
        button.backgroundColor = [UIColor colorWithRed:0.15 green:0.35 blue:0.9 alpha:0.95];
        [button setTitle:@"Play" forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.accessibilityLabel = @"Read document aloud";
        __weak UIViewController *weakController = controller;
        [button addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            UIViewController *strongController = weakController;
            WKWebView *web = GDTAllWebViews(strongController.view).firstObject;
            if (GDTController.webView == web && GDTController.session.state != GDTReadingStateIdle) [GDTController pauseOrResume];
            else if (web) [GDTController loadWebView:web];
        }] forControlEvents:UIControlEventTouchUpInside];
        button.menu = [UIMenu menuWithTitle:@"Read" children:@[
            [UIAction actionWithTitle:@"Read selection" image:nil identifier:nil handler:^(__kindof UIAction *action) { WKWebView *web = GDTAllWebViews(controller.view).firstObject; if (web) [GDTController loadSelectionFromWebView:web fromCursor:NO]; }],
            [UIAction actionWithTitle:@"Read from cursor" image:nil identifier:nil handler:^(__kindof UIAction *action) { WKWebView *web = GDTAllWebViews(controller.view).firstObject; if (web) [GDTController loadSelectionFromWebView:web fromCursor:YES]; }],
            [UIAction actionWithTitle:@"Bookmark current" image:nil identifier:nil handler:^(__kindof UIAction *action) { [GDTController bookmarkCurrent]; }],
            [UIAction actionWithTitle:@"Settings" image:nil identifier:nil handler:^(__kindof UIAction *action) { [GDTController presentSettingsFrom:controller]; }]
        ]];
        [controller.view addSubview:button];
    });
}

static NSArray<WKWebView *> *GDTAllWebViews(UIView *root) {
    NSMutableArray<WKWebView *> *result = [NSMutableArray array];
    if ([root isKindOfClass:WKWebView.class]) [result addObject:(WKWebView *)root];
    for (UIView *subview in root.subviews) [result addObjectsFromArray:GDTAllWebViews(subview)];
    return result;
}

@interface UIViewController (GoogleDocsTTS)
@end

@implementation UIViewController (GoogleDocsTTS)
- (void)gdt_viewDidAppear:(BOOL)animated { [self gdt_viewDidAppear:animated]; if (self.view.window) GDTInstallButton(self); }
@end
