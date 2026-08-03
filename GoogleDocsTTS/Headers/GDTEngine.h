#import <Foundation/Foundation.h>
#import "GDTModels.h"

NS_ASSUME_NONNULL_BEGIN

@interface GDTSpeechRequest : NSObject
@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy, nullable) NSString *voiceIdentifier;
@property(nonatomic) float rate;
@property(nonatomic) float pitch;
@property(nonatomic) float volume;
@end

@interface GDTVoice : NSObject
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *language;
@property(nonatomic) BOOL isNetworkRequired;
@end

@protocol GDTVoiceProvider <NSObject>
- (NSArray<GDTVoice *> *)availableVoices;
- (nullable GDTVoice *)voiceWithIdentifier:(NSString *)identifier;
@end

@protocol GDTSpeechDelegate <NSObject>
- (void)speechDidStart:(GDTSpeechRequest *)request;
- (void)speechDidFinish:(GDTSpeechRequest *)request error:(nullable NSError *)error;
@end

@protocol GDTTTSEngine <NSObject>
@property(nonatomic, readonly) BOOL speaking;
- (void)speakRequest:(GDTSpeechRequest *)request completion:(void (^)(NSError * _Nullable error))completion;
- (void)speakSentence:(GDTSentence *)sentence rate:(float)rate completion:(void (^)(NSError * _Nullable error))completion;
- (void)pause;
- (void)resume;
- (void)stop;
@end

@interface GDTSpeechEngine : NSObject <GDTTTSEngine>
@property(nonatomic, strong, readonly) id<GDTVoiceProvider> voiceProvider;
- (instancetype)initWithVoiceProvider:(id<GDTVoiceProvider>)voiceProvider delegate:(nullable id<GDTSpeechDelegate>)delegate;
@end

@interface GDTSystemVoiceProvider : NSObject <GDTVoiceProvider>
@end

NS_ASSUME_NONNULL_END
