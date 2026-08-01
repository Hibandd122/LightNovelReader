#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <WebKit/WebKit.h>
#import <dispatch/dispatch.h>
#import <string.h>
#import <stdlib.h>
#import <stdint.h>
#import <zlib.h>
#if __has_include(<UniformTypeIdentifiers/UniformTypeIdentifiers.h>)
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#define INJECTED_HAS_UNIFORM_TYPE_IDENTIFIERS 1
#endif

static uint16_t ReadLE16(const uint8_t *bytes) {
    return (uint16_t)bytes[0] | ((uint16_t)bytes[1] << 8);
}

static uint32_t ReadLE32(const uint8_t *bytes) {
    return (uint32_t)bytes[0] |
           ((uint32_t)bytes[1] << 8) |
           ((uint32_t)bytes[2] << 16) |
           ((uint32_t)bytes[3] << 24);
}

static void SetDocxError(NSError **error, NSInteger code, NSString *message) {
    if (error && !*error) {
        *error = [NSError errorWithDomain:@"InjectedTTS.DOCX"
                                     code:code
                                 userInfo:@{NSLocalizedDescriptionKey: message}];
    }
}

static NSData *InflateDeflatedData(NSData *compressed, NSUInteger expectedSize, NSError **error) {
    if (expectedSize > 64 * 1024 * 1024) {
        if (error) *error = [NSError errorWithDomain:@"InjectedTTS.DOCX" code:1 userInfo:@{
            NSLocalizedDescriptionKey: @"DOCX document is too large to read safely."
        }];
        return nil;
    }
    if (expectedSize == 0) return [NSData data];

    NSMutableData *result = [NSMutableData dataWithLength:expectedSize];
    z_stream stream;
    memset(&stream, 0, sizeof(stream));
    stream.next_in = (Bytef *)compressed.bytes;
    stream.avail_in = (uInt)compressed.length;
    stream.next_out = (Bytef *)result.mutableBytes;
    stream.avail_out = (uInt)result.length;

    int status = inflateInit2(&stream, -MAX_WBITS);
    if (status != Z_OK) return nil;
    status = inflate(&stream, Z_FINISH);
    inflateEnd(&stream);
    if (status != Z_STREAM_END) {
        if (error) *error = [NSError errorWithDomain:@"InjectedTTS.DOCX" code:2 userInfo:@{
            NSLocalizedDescriptionKey: @"Unable to decompress word/document.xml."
        }];
        return nil;
    }
    return result;
}

static NSData *ReadZipEntry(NSData *archive, NSString *targetName, NSError **error) {
    if (!archive || archive.length < 22) return nil;

    const uint8_t *bytes = archive.bytes;
    NSUInteger searchStart = archive.length > (22 + 65535) ? archive.length - (22 + 65535) : 0;
    NSUInteger endRecord = NSNotFound;
    for (NSUInteger offset = archive.length - 22; offset >= searchStart; offset--) {
        uint16_t commentLength = ReadLE16(bytes + offset + 20);
        uint32_t centralSize = ReadLE32(bytes + offset + 12);
        uint32_t centralOffset = ReadLE32(bytes + offset + 16);
        if (ReadLE32(bytes + offset) == 0x06054b50 &&
            (uint64_t)offset + 22 + commentLength <= archive.length &&
            (uint64_t)centralOffset + centralSize <= archive.length) {
            endRecord = offset;
            break;
        }
        if (offset == 0) break;
    }
    if (endRecord == NSNotFound || endRecord + 22 > archive.length) return nil;

    uint16_t entryCount = ReadLE16(bytes + endRecord + 10);
    uint32_t centralSize = ReadLE32(bytes + endRecord + 12);
    uint32_t centralOffset = ReadLE32(bytes + endRecord + 16);
    if ((uint64_t)centralOffset + centralSize > archive.length) return nil;

    NSUInteger cursor = centralOffset;
    for (uint16_t index = 0; index < entryCount && cursor + 46 <= archive.length; index++) {
        if (ReadLE32(bytes + cursor) != 0x02014b50) break;
        uint16_t method = ReadLE16(bytes + cursor + 10);
        uint32_t expectedCRC = ReadLE32(bytes + cursor + 16);
        uint32_t compressedSize = ReadLE32(bytes + cursor + 20);
        uint32_t uncompressedSize = ReadLE32(bytes + cursor + 24);
        uint16_t nameLength = ReadLE16(bytes + cursor + 28);
        uint16_t extraLength = ReadLE16(bytes + cursor + 30);
        uint16_t commentLength = ReadLE16(bytes + cursor + 32);
        uint32_t localOffset = ReadLE32(bytes + cursor + 42);
        NSUInteger next = cursor + 46 + nameLength + extraLength + commentLength;
        if (next > archive.length) break;

        NSString *name = [[NSString alloc] initWithBytes:bytes + cursor + 46
                                                   length:nameLength
                                                 encoding:NSUTF8StringEncoding];
        if ([name isEqualToString:targetName] && (uint64_t)localOffset + 30 <= archive.length) {
            if (uncompressedSize > 64 * 1024 * 1024) {
                if (error) *error = [NSError errorWithDomain:@"InjectedTTS.DOCX" code:1 userInfo:@{
                    NSLocalizedDescriptionKey: @"DOCX document is too large to read safely."
                }];
                return nil;
            }
            if (ReadLE32(bytes + localOffset) != 0x04034b50) return nil;
            uint16_t localNameLength = ReadLE16(bytes + localOffset + 26);
            uint16_t localExtraLength = ReadLE16(bytes + localOffset + 28);
            NSUInteger dataOffset = (NSUInteger)localOffset + 30 + localNameLength + localExtraLength;
            if ((uint64_t)dataOffset + compressedSize > archive.length) return nil;
            NSData *compressed = [archive subdataWithRange:NSMakeRange(dataOffset, compressedSize)];
            NSData *result = nil;
            if (method == 0) {
                if (compressed.length != uncompressedSize) return nil;
                result = compressed;
            } else if (method == 8) {
                result = InflateDeflatedData(compressed, uncompressedSize, error);
            } else {
                return nil;
            }
            if (!result) return nil;
            uLong actualCRC = crc32(0L, Z_NULL, 0);
            actualCRC = crc32(actualCRC, result.bytes, (uInt)result.length);
            if ((uint32_t)actualCRC != expectedCRC) {
                if (error) *error = [NSError errorWithDomain:@"InjectedTTS.DOCX" code:3 userInfo:@{
                    NSLocalizedDescriptionKey: @"DOCX checksum validation failed."
                }];
                return nil;
            }
            return result;
        }
        cursor = next;
    }
    return nil;
}

static NSString *DecodeXMLText(NSString *text) {
    NSDictionary *entities = @{
        @"&amp;": @"&", @"&lt;": @"<", @"&gt;": @">",
        @"&quot;": @"\"", @"&apos;": @"'"
    };
    for (NSString *entity in entities) text = [text stringByReplacingOccurrencesOfString:entity withString:entities[entity]];
    NSRegularExpression *numeric = [NSRegularExpression regularExpressionWithPattern:@"&#(x[0-9A-Fa-f]+|[0-9]+);" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [numeric matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSString *value = [text substringWithRange:[match rangeAtIndex:1]];
        BOOL hexadecimal = value.lowercaseString.hasPrefix:@"x";
        unsigned long codePoint = strtoul(value.UTF8String + (hexadecimal ? 1 : 0), NULL, hexadecimal ? 16 : 10);
        if (codePoint <= 0x10FFFF) {
            NSString *replacement;
            if (codePoint <= 0xFFFF) {
                replacement = [NSString stringWithFormat:@"%C", (unichar)codePoint];
            } else {
                codePoint -= 0x10000;
                unichar high = (unichar)((codePoint >> 10) + 0xD800);
                unichar low = (unichar)((codePoint & 0x3FF) + 0xDC00);
                replacement = [NSString stringWithFormat:@"%C%C", high, low];
            }
            [text replaceCharactersInRange:match.range withString:replacement];
        }
    }
    return text;
}

static NSString *ExtractDocxText(NSData *xmlData) {
    NSString *xml = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    if (!xml.length) {
        xml = [[NSString alloc] initWithData:xmlData encoding:NSUTF16LittleEndianStringEncoding];
    }
    if (!xml.length) {
        xml = [[NSString alloc] initWithData:xmlData encoding:NSUTF16BigEndianStringEncoding];
    }
    if (!xml.length) return nil;
    NSRegularExpression *deletedRuns = [NSRegularExpression regularExpressionWithPattern:@"<w:(del|moveFrom)\\b[^>]*>.*?</w:\\1\\s*>"
                                                                                     options:NSRegularExpressionDotMatchesLineSeparators
                                                                                       error:nil];
    xml = [deletedRuns stringByReplacingMatchesInString:xml
                                                 options:0
                                                   range:NSMakeRange(0, xml.length)
                                            withTemplate:@""];
    NSString *pattern = @"<w:t\\b[^>]*>.*?</w:t\\s*>|<w:tab\\b[^>]*/?>|<w:br\\b[^>]*/?>|<w:cr\\b[^>]*/?>|<w:lastRenderedPageBreak\\b[^>]*/?>|</w:p\\s*>|</w:tc\\s*>|</w:tr\\s*>";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionDotMatchesLineSeparators
                                                                                 error:nil];
    NSMutableString *text = [NSMutableString string];
    [regex enumerateMatchesInString:xml options:0 range:NSMakeRange(0, xml.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSString *token = [xml substringWithRange:match.range];
        if ([token hasPrefix:@"</w:p"] || [token hasPrefix:@"</w:tr"]) {
            [text appendString:@"\n"];
        } else if ([token hasPrefix:@"</w:tc"] || [token hasPrefix:@"<w:tab"]) {
            [text appendString:@"\t"];
        } else if ([token hasPrefix:@"<w:br"] || [token hasPrefix:@"<w:cr"] || [token hasPrefix:@"<w:lastRenderedPageBreak"]) {
            [text appendString:@"\n"];
        } else {
            NSRange open = [token rangeOfString:@">"];
            NSRange close = [token rangeOfString:@"</w:t" options:NSBackwardsSearch];
            if (open.location != NSNotFound && close.location != NSNotFound && close.location > NSMaxRange(open)) {
                NSString *value = [token substringWithRange:NSMakeRange(NSMaxRange(open), close.location - NSMaxRange(open))];
                [text appendString:DecodeXMLText(value)];
            }
        }
    }];
    [text replaceOccurrencesOfString:@"\u00A0" withString:@" " options:0 range:NSMakeRange(0, text.length)];
    [text replaceOccurrencesOfString:@"\u00AD" withString:@"" options:0 range:NSMakeRange(0, text.length)];
    [text replaceOccurrencesOfString:@"\uFEFF" withString:@"" options:0 range:NSMakeRange(0, text.length)];
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static BOOL IsSpeechPunctuation(unichar character) {
    return character == '.' || character == '!' || character == '?' ||
           character == 0x3002 || character == 0xFF01 || character == 0xFF1F ||
           character == 0x2026;
}

static NSArray<NSString *> *SplitTextForSpeech(NSString *text) {
    NSMutableArray<NSString *> *sentences = [NSMutableArray array];
    NSMutableString *current = [NSMutableString string];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    for (NSUInteger index = 0; index < text.length; index++) {
        unichar character = [text characterAtIndex:index];
        if (character == '\r') continue;
        [current appendFormat:@"%C", character];

        BOOL isNewline = character == '\n';
        BOOL isPunctuation = IsSpeechPunctuation(character);
        if (isPunctuation) {
            unichar previous = index > 0 ? [text characterAtIndex:index - 1] : 0;
            unichar next = index + 1 < text.length ? [text characterAtIndex:index + 1] : 0;
            if (character == '.' && previous >= '0' && previous <= '9' && next >= '0' && next <= '9') {
                isPunctuation = NO;
            } else if (next && ![whitespace characterIsMember:next] && !IsSpeechPunctuation(next)) {
                isPunctuation = NO;
            }
        }

        BOOL reachedSpeechLimit = current.length >= 700 && [whitespace characterIsMember:character];
        BOOL reachedHardLimit = current.length >= 1200;
        if (isNewline || isPunctuation || reachedSpeechLimit || reachedHardLimit) {
            NSString *sentence = [current stringByTrimmingCharactersInSet:whitespace];
            if (sentence.length) [sentences addObject:sentence];
            [current setString:@""];
        }
    }
    NSString *tail = [current stringByTrimmingCharactersInSet:whitespace];
    if (tail.length) [sentences addObject:tail];
    return sentences;
}

static NSString *ReadDocxText(NSURL *url, NSError **error) {
    NSData *archive = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!archive) return nil;

    NSData *documentXML = ReadZipEntry(archive, @"word/document.xml", error);
    if (!documentXML) {
        SetDocxError(error, 4, @"Không tìm thấy phần nội dung chính của DOCX.");
        return nil;
    }
    NSString *body = ExtractDocxText(documentXML);
    if (!body.length) {
        SetDocxError(error, 5, @"DOCX không chứa văn bản có thể đọc.");
        return nil;
    }
    NSMutableString *content = [body mutableCopy];

    NSArray<NSString *> *supplementalParts = @[@"word/footnotes.xml", @"word/endnotes.xml"];
    for (NSString *partName in supplementalParts) {
        NSData *partXML = ReadZipEntry(archive, partName, nil);
        NSString *partText = ExtractDocxText(partXML);
        if (partText.length) {
            [content appendFormat:@"\n%@", partText];
        }
    }
    return content;
}

static NSString *ReadDocumentText(NSURL *url, NSError **error) {
    NSString *extension = url.pathExtension.lowercaseString;
    if ([extension isEqualToString:@"docx"]) {
        NSString *content = ReadDocxText(url, error);
        if (content.length) return content;

        NSAttributedString *document = [[NSAttributedString alloc] initWithURL:url
                                                                         options:@{}
                                                              documentAttributes:nil
                                                                           error:error];
        if (document.string.length) return document.string;
    }

    if ([extension isEqualToString:@"rtf"] || [extension isEqualToString:@"rtfd"]) {
        NSAttributedString *document = [[NSAttributedString alloc] initWithURL:url
                                                                         options:@{
                                                                             NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType
                                                                         }
                                                              documentAttributes:nil
                                                                           error:error];
        if (document.string.length) return document.string;
    }

    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSString *content = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:error];
    if (content.length) return content;

    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    return data.length ? [[NSString alloc] initWithData:data encoding:encoding] : nil;
}

static void PrepareSpeechAudioSession(void) {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback
                   withOptions:AVAudioSessionCategoryOptionMixWithOthers
                         error:nil];
    [audioSession setMode:AVAudioSessionModeSpokenAudio error:nil];
    [audioSession setActive:YES error:nil];
}

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
@property (nonatomic, strong) AVSpeechUtterance *activeUtterance;
@property (nonatomic, assign) NSUInteger documentLoadToken;
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
            if (sharedOverlay || ![note.object isKindOfClass:[UIWindowScene class]]) return;
            UIWindowScene *scene = (UIWindowScene *)note.object;
            if (scene.activationState == UISceneActivationStateUnattached) return;
            sharedOverlay = [[TTSOverlayWindow alloc] initWithFrame:CGRectMake(20, 80, 340, 260)];
            sharedOverlay.windowScene = scene;
            [sharedOverlay makeKeyAndVisible];
        }];
        
        // Fallback for non-scene apps
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            if (!sharedOverlay) {
                if (@available(iOS 13.0, *)) return;
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
        self.statusLabel.text = @"Chrome OS TTS không khả dụng trong app iOS; đang dùng giọng hệ thống.";
    } else {
        [self.voiceEngineBtn setTitle:@"Engine: iOS Native" forState:UIControlStateNormal];
        self.voiceEngineBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    }
}

- (void)openDocumentPicker {
    UIDocumentPickerViewController *picker;
#if INJECTED_HAS_UNIFORM_TYPE_IDENTIFIERS
    if (@available(iOS 14.0, *)) {
        picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[
            [UTType typeWithIdentifier:@"public.text"],
            [UTType typeWithIdentifier:@"public.rtf"],
            [UTType typeWithIdentifier:@"org.openxmlformats.wordprocessingml.document"]
        ]];
    } else
#endif
    {
        picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[
            @"public.text", @"public.rtf", @"org.openxmlformats.wordprocessingml.document"
        ] inMode:UIDocumentPickerModeImport];
    }
    picker.delegate = self;
    [self.rootViewController presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    
    BOOL accessed = [url startAccessingSecurityScopedResource];
    NSString *filename = url.lastPathComponent ?: @"Tài liệu";
    NSUInteger loadToken = ++self.documentLoadToken;
    __weak TTSOverlayWindow *weakSelf = self;
    self.statusLabel.text = [NSString stringWithFormat:@"Đang đọc: %@…", filename];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSString *content = ReadDocumentText(url, &error);
        if (accessed) [url stopAccessingSecurityScopedResource];

        dispatch_async(dispatch_get_main_queue(), ^{
            TTSOverlayWindow *strongSelf = weakSelf;
            if (!strongSelf) return;
            if (strongSelf.documentLoadToken != loadToken) return;
            if (content.length) {
                [strongSelf loadTextContent:content filename:filename];
            } else {
                NSString *message = error.localizedDescription ?: @"Không thể trích xuất nội dung tài liệu.";
                strongSelf.statusLabel.text = [NSString stringWithFormat:@"Lỗi đọc file: %@", message];
            }
        });
    });
}

- (void)loadTextContent:(NSString *)text filename:(NSString *)filename {
    self.activeUtterance = nil;
    [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.sentences removeAllObjects];
    [self.sentences addObjectsFromArray:SplitTextForSpeech(text ?: @"")];
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
        if (self.currentSentenceIndex >= self.sentences.count) {
            self.currentSentenceIndex = 0;
        }
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
    if (!completion) return;
    UIWindow *appWindow = nil;
    NSArray<UIWindow *> *windows = [UIApplication sharedApplication].windows;
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = self.windowScene;
        if (scene) windows = scene.windows;
    }
    for (UIWindow *w in windows) {
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
        
        if ([view isKindOfClass:[WKWebView class]]) {
            foundWebView = YES;
            WKWebView *webView = (WKWebView *)view;
            [webView evaluateJavaScript:@"document.body ? document.body.innerText : ''" completionHandler:^(id result, NSError *error) {
                if ([result isKindOfClass:[NSString class]] && ((NSString *)result).length > 0) {
                    completion(result);
                } else {
                    completion(gatheredText);
                }
            }];
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
        self.activeUtterance = nil;
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        [self speakSentenceAtIndex:self.currentSentenceIndex];
    }
}

- (void)nextSentence {
    if (self.currentSentenceIndex + 1 < self.sentences.count) {
        self.currentSentenceIndex++;
        self.activeUtterance = nil;
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
    PrepareSpeechAudioSession();
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    CGFloat multiplier = self.speedSlider.value;
    CGFloat rate;
    if (multiplier <= 1.0) {
        CGFloat progress = (multiplier - 0.25) / 0.75;
        rate = AVSpeechUtteranceMinimumSpeechRate +
               progress * (AVSpeechUtteranceDefaultSpeechRate - AVSpeechUtteranceMinimumSpeechRate);
    } else {
        CGFloat progress = (multiplier - 1.0) / 1.5;
        rate = AVSpeechUtteranceDefaultSpeechRate +
               progress * (AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceDefaultSpeechRate);
    }
    utterance.rate = MIN(AVSpeechUtteranceMaximumSpeechRate,
                         MAX(AVSpeechUtteranceMinimumSpeechRate, rate));
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"vi-VN"] ?: [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
    
    [self.playPauseButton setTitle:@"⏸ Tạm dừng" forState:UIControlStateNormal];
    self.activeUtterance = utterance;
    [self.speechSynthesizer speakUtterance:utterance];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (utterance != self.activeUtterance) return;
    self.activeUtterance = nil;
    self.currentSentenceIndex++;
    if (self.currentSentenceIndex < self.sentences.count) {
        [self speakSentenceAtIndex:self.currentSentenceIndex];
    } else {
        self.statusLabel.text = @"Đã đọc hết nội dung.";
        [self.playPauseButton setTitle:@"▶️ Phát" forState:UIControlStateNormal];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (utterance != self.activeUtterance) return;
    self.activeUtterance = nil;
    [self.playPauseButton setTitle:@"▶️ Phát" forState:UIControlStateNormal];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    if (!self.speechSynthesizer.isSpeaking && self.sentences.count == 0) {
        self.statusLabel.text = @"Sẵn sàng.";
    }
}

@end
