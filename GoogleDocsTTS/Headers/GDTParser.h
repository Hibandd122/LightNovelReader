#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "GDTModels.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GDTTextSource <NSObject>
- (void)readTextFromWebView:(WKWebView *)webView completion:(void (^)(NSString * _Nullable text, NSError * _Nullable error))completion;
@end

@protocol GDTStructuredTextSource <GDTTextSource>
- (void)readStructuredTextFromWebView:(WKWebView *)webView completion:(void (^)(NSArray<NSDictionary *> * _Nullable blocks, NSError * _Nullable error))completion;
@end

@protocol GDTSelectionSource <NSObject>
- (void)readSelectedTextFromWebView:(WKWebView *)webView fromCursor:(BOOL)fromCursor completion:(void (^)(NSString * _Nullable text, NSUInteger characterOffset, NSError * _Nullable error))completion;
@end

@protocol GDTTextNormalizer <NSObject>
- (NSString *)normalizeText:(NSString *)text;
@end

@protocol GDTSegmenter <NSObject>
- (NSArray<GDTSentence *> *)segmentText:(NSString *)text;
@end

@interface GDTWebTextSource : NSObject <GDTStructuredTextSource, GDTSelectionSource>
@end
@interface GDTDefaultNormalizer : NSObject <GDTTextNormalizer>
@end
@interface GDTSentenceSegmenter : NSObject <GDTSegmenter>
@end
@interface GDTParser : NSObject
@property(nonatomic, readonly) id<GDTTextSource> source;
- (instancetype)initWithSource:(id<GDTTextSource>)source normalizer:(id<GDTTextNormalizer>)normalizer segmenter:(id<GDTSegmenter>)segmenter;
- (void)parseWebView:(WKWebView *)webView documentID:(NSString *)documentID completion:(void (^)(GDTDocument * _Nullable document, NSError * _Nullable error))completion;
- (void)parseText:(NSString *)text documentID:(NSString *)documentID completion:(void (^)(GDTDocument * _Nullable document, NSError * _Nullable error))completion;
@end

NS_ASSUME_NONNULL_END
