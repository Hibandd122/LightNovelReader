#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "GDTModels.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GDTHighlightEngine <NSObject>
- (void)highlightSentence:(GDTSentence *)sentence inWebView:(WKWebView *)webView autoScroll:(BOOL)autoScroll completion:(void (^)(NSError * _Nullable error))completion;
- (void)highlightParagraph:(GDTParagraph *)paragraph inWebView:(WKWebView *)webView autoScroll:(BOOL)autoScroll completion:(void (^)(NSError * _Nullable error))completion;
- (void)highlightWord:(GDTWord *)word inWebView:(WKWebView *)webView autoScroll:(BOOL)autoScroll completion:(void (^)(NSError * _Nullable error))completion;
- (void)clearHighlightInWebView:(WKWebView *)webView;
@end

@interface GDTDOMHighlightEngine : NSObject <GDTHighlightEngine>
@end

NS_ASSUME_NONNULL_END
