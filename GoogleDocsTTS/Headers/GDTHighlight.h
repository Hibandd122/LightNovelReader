#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "GDTModels.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GDTHighlightEngine <NSObject>
- (void)highlightSentence:(GDTSentence * _Nullable)sentence inWebView:(WKWebView * _Nullable)webView autoScroll:(BOOL)autoScroll completion:(void (^ _Nullable)(NSError * _Nullable error))completion;
- (void)highlightParagraph:(GDTParagraph * _Nullable)paragraph inWebView:(WKWebView * _Nullable)webView autoScroll:(BOOL)autoScroll completion:(void (^ _Nullable)(NSError * _Nullable error))completion;
- (void)highlightWord:(GDTWord * _Nullable)word inWebView:(WKWebView * _Nullable)webView autoScroll:(BOOL)autoScroll completion:(void (^ _Nullable)(NSError * _Nullable error))completion;
- (void)clearHighlightInWebView:(WKWebView * _Nullable)webView;
@end

@interface GDTDOMHighlightEngine : NSObject <GDTHighlightEngine>
@end

NS_ASSUME_NONNULL_END
