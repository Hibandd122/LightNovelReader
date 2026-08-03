#import "GDTEngine.h"
#import <AVFoundation/AVFoundation.h>

@implementation GDTSpeechRequest @end
@implementation GDTVoice @end

@implementation GDTSystemVoiceProvider
- (NSArray<GDTVoice *> *)availableVoices { NSMutableArray *voices=[NSMutableArray array]; for (AVSpeechSynthesisVoice *voice in AVSpeechSynthesisVoice.speechVoices) { GDTVoice *item=[GDTVoice new]; item.identifier=voice.identifier; item.name=voice.name; item.language=voice.language; item.isNetworkRequired=voice.quality==AVSpeechSynthesisVoiceQualityEnhanced; [voices addObject:item]; } return voices; }
- (GDTVoice *)voiceWithIdentifier:(NSString *)identifier { for (GDTVoice *voice in self.availableVoices) if ([voice.identifier isEqualToString:identifier]) return voice; return nil; }
@end

@interface GDTSpeechEngine () <AVSpeechSynthesizerDelegate>
@property(nonatomic) AVSpeechSynthesizer *synthesizer;
@property(nonatomic, copy) void (^completion)(NSError *);
@property(nonatomic, strong) id<GDTVoiceProvider> voiceProvider;
@property(nonatomic, weak) id<GDTSpeechDelegate> delegate;
@property(nonatomic, strong) GDTSpeechRequest *currentRequest;
@end
@implementation GDTSpeechEngine
- (instancetype)init { return [self initWithVoiceProvider:[GDTSystemVoiceProvider new] delegate:nil]; }
- (instancetype)initWithVoiceProvider:(id<GDTVoiceProvider>)voiceProvider delegate:(id<GDTSpeechDelegate>)delegate { if ((self = [super init])) { _synthesizer = [AVSpeechSynthesizer new]; _synthesizer.delegate = self; _voiceProvider=voiceProvider; _delegate=delegate; } return self; }
- (BOOL)speaking { return self.synthesizer.isSpeaking; }
- (void)speakRequest:(GDTSpeechRequest *)request completion:(void (^)(NSError *))completion { self.completion = completion; self.currentRequest=request; AVSpeechUtterance *u = [AVSpeechUtterance speechUtteranceWithString:request.text]; u.rate = MAX(AVSpeechUtteranceMinimumSpeechRate, MIN(request.rate, AVSpeechUtteranceMaximumSpeechRate)); u.pitchMultiplier=MAX(0.5,MIN(request.pitch,2.0)); u.volume=MAX(0.0,MIN(request.volume,1.0)); if (request.voiceIdentifier.length) { AVSpeechSynthesisVoice *voice=[AVSpeechSynthesisVoice voiceWithIdentifier:request.voiceIdentifier]; if (voice) u.voice=voice; } [self.delegate speechDidStart:request]; [self.synthesizer speakUtterance:u]; }
- (void)speakSentence:(GDTSentence *)sentence rate:(float)rate completion:(void (^)(NSError *))completion { GDTSpeechRequest *request=[GDTSpeechRequest new]; request.text=sentence.text; request.rate=rate; request.pitch=1.0f; request.volume=1.0f; [self speakRequest:request completion:completion]; }
- (void)pause { [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate]; }
- (void)resume { [self.synthesizer continueSpeaking]; }
- (void)stop { [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate]; }
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance { [self.delegate speechDidFinish:self.currentRequest error:nil]; if (self.completion) { self.completion(nil); self.completion = nil; } self.currentRequest=nil; }
@end
