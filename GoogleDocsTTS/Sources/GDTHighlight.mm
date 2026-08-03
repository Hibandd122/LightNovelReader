#import "GDTHighlight.h"
#import <UIKit/UIKit.h>

@implementation GDTDOMHighlightEngine
- (NSString *)jsonString:(NSString *)value { NSData *data=[NSJSONSerialization dataWithJSONObject:@[value ?: @""] options:0 error:nil]; NSString *array=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]; return [array substringWithRange:NSMakeRange(1,array.length-2)]; }
- (void)highlightText:(NSString *)text inWebView:(WKWebView *)webView autoScroll:(BOOL)autoScroll announce:(BOOL)announce completion:(void (^)(NSError *))completion {
    NSString *needle=[self jsonString:[text stringByReplacingOccurrencesOfString:@"\n" withString:@" "]]; NSString *scroll=autoScroll ? @"var e=r.startContainer.parentElement;if(e)e.scrollIntoView({block:'center',behavior:'smooth'});" : @"";
    NSString *script=[NSString stringWithFormat:@"(function(){var q=%@,w=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT),nodes=[],n,all='';while(n=w.nextNode()){nodes.push({n:n,start:all.length});all+=n.nodeValue;}var p=all.indexOf(q);if(p<0)return false;var s,e,so,eo;for(var i=0;i<nodes.length;i++){var a=nodes[i],b=a.start+a.n.nodeValue.length;if(s===undefined&&p>=a.start&&p<b){s=a.n;so=p-a.start;}if(s!==undefined&&p+q.length<=b){e=a.n;eo=p+q.length-a.start;break;}}if(!s||!e)return false;var r=document.createRange();r.setStart(s,so);r.setEnd(e,eo);window.getSelection().removeAllRanges();window.getSelection().addRange(r);%@return true;})()",needle,scroll];
    [webView evaluateJavaScript:script completionHandler:^(id value,NSError *error){ if (!error && announce && UIAccessibilityIsVoiceOverRunning()) UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, text); if (completion) completion(error); }];
}
- (void)highlightSentence:(GDTSentence *)sentence inWebView:(WKWebView *)webView autoScroll:(BOOL)autoScroll completion:(void (^)(NSError *))completion { [self highlightText:sentence.text inWebView:webView autoScroll:autoScroll announce:YES completion:completion]; }
- (void)highlightParagraph:(GDTParagraph *)paragraph inWebView:(WKWebView *)webView autoScroll:(BOOL)autoScroll completion:(void (^)(NSError *))completion { [self highlightText:paragraph.text inWebView:webView autoScroll:autoScroll announce:NO completion:completion]; }
- (void)highlightWord:(GDTWord *)word inWebView:(WKWebView *)webView autoScroll:(BOOL)autoScroll completion:(void (^)(NSError *))completion { [self highlightText:word.text inWebView:webView autoScroll:autoScroll announce:NO completion:completion]; }
- (void)clearHighlightInWebView:(WKWebView *)webView { [webView evaluateJavaScript:@"window.getSelection().removeAllRanges();" completionHandler:nil]; }
@end
