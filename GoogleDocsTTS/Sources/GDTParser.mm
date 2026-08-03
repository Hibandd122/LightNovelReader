#import "GDTParser.h"

@implementation GDTWebTextSource
- (void)readTextFromWebView:(WKWebView *)webView completion:(void (^)(NSString *, NSError *))completion {
    NSString *script = @"(function(){var n=document.querySelector('[contenteditable=\"true\"]')||document.body;return n ? (n.innerText||n.textContent||'') : '';})()";
    [webView evaluateJavaScript:script completionHandler:^(id value, NSError *error) { completion([value isKindOfClass:NSString.class] ? value : nil, error); }];
}
- (void)readStructuredTextFromWebView:(WKWebView *)webView completion:(void (^)(NSArray<NSDictionary *> *, NSError *))completion {
    NSString *script=@"(function(){var root=document.querySelector('[contenteditable=\\\"true\\\"]')||document.body;var out=[];var selector='h1,h2,h3,h4,h5,h6,p,li,table,a,img,[role=\\\"doc-footnote\\\"]';root.querySelectorAll(selector).forEach(function(el){var kind='paragraph';if(/^H[1-6]$/.test(el.tagName))kind='heading';else if(el.tagName==='LI')kind='list';else if(el.tagName==='TABLE')kind='table';else if(el.tagName==='A')kind='link';else if(el.tagName==='IMG')kind='image';else if(el.getAttribute('role')==='doc-footnote')kind='footnote';var text=el.tagName==='IMG'?(el.alt||''):((el.innerText||el.textContent||'').trim());if(text){out.push({kind:kind,text:text,href:el.href||'',alt:el.alt||'',level:el.tagName.match(/^H([1-6])$/)?el.tagName.substring(1):''});}});if(!out.length){var text=(root.innerText||root.textContent||'').trim();if(text)out.push({kind:'paragraph',text:text});}return out;})()";
    [webView evaluateJavaScript:script completionHandler:^(id value,NSError *error){ completion([value isKindOfClass:NSArray.class] ? value : nil,error); }];
}
- (void)readSelectedTextFromWebView:(WKWebView *)webView fromCursor:(BOOL)fromCursor completion:(void (^)(NSString *, NSUInteger, NSError *))completion {
    NSString *script=[NSString stringWithFormat:@"(function(){var s=window.getSelection();if(!s||!s.anchorNode)return {text:'',offset:0};var root=document.querySelector('[contenteditable=\\\"true\\\"]')||document.body;var r=document.createRange();r.selectNodeContents(root);if(%@){r.setEnd(s.anchorNode,s.anchorOffset);}else{r=s.getRangeAt(0).cloneRange();}var text=r.toString();return {text:text,offset:text.length};})()",fromCursor?@"true":@"false"];
    [webView evaluateJavaScript:script completionHandler:^(id value,NSError *error){ NSDictionary *result=[value isKindOfClass:NSDictionary.class] ? value : @{}; NSString *text=[result[@"text"] isKindOfClass:NSString.class] ? result[@"text"] : @""; NSUInteger offset=[result[@"offset"] unsignedIntegerValue]; completion(text,offset,error ?: (text.length ? nil : [NSError errorWithDomain:@"GoogleDocsTTS" code:3 userInfo:@{NSLocalizedDescriptionKey:@"No selected text or cursor position"}])); }];
}
@end

@implementation GDTDefaultNormalizer
- (NSString *)normalizeText:(NSString *)text {
    NSMutableString *result = [text mutableCopy];
    [result replaceOccurrencesOfString:@"\u00a0" withString:@" " options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0, result.length)];
    NSRegularExpression *spaces = [NSRegularExpression regularExpressionWithPattern:@"[ \\t]+" options:0 error:nil];
    [spaces replaceMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:@" "];
    return [result stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}
@end

@implementation GDTSentenceSegmenter
- (NSArray<GDTSentence *> *)segmentText:(NSString *)text {
    NSMutableArray *out = [NSMutableArray array]; NSUInteger start = 0, paragraph = 0;
    NSCharacterSet *terminators = [NSCharacterSet characterSetWithCharactersInString:@".!?。！？…\n"];
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar ch = [text characterAtIndex:i];
        if (ch == '\n') paragraph++;
        BOOL end = [terminators characterIsMember:ch];
        if (end && (i + 1 == text.length || [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[text characterAtIndex:i + 1]])) {
            NSRange range = NSMakeRange(start, i + 1 - start); NSString *value = [[text substringWithRange:range] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (value.length) { GDTSentence *s = [GDTSentence new]; s.identifier = [NSString stringWithFormat:@"s-%lu", (unsigned long)out.count]; s.text = value; s.paragraphIndex = paragraph; s.sourceRange = range; s.words = [self wordsForText:value sourceOffset:range.location]; [out addObject:s]; } start = i + 1;
        }
    }
    if (start < text.length) { NSString *value = [[text substringFromIndex:start] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]; if (value.length) { GDTSentence *s = [GDTSentence new]; s.identifier = [NSString stringWithFormat:@"s-%lu", (unsigned long)out.count]; s.text = value; s.paragraphIndex = paragraph; s.sourceRange = NSMakeRange(start, text.length - start); s.words = [self wordsForText:value sourceOffset:start]; [out addObject:s]; } }
    return out;
}
- (NSArray<GDTWord *> *)wordsForText:(NSString *)text sourceOffset:(NSUInteger)offset {
    NSMutableArray *words=[NSMutableArray array]; NSCharacterSet *separators=NSCharacterSet.whitespaceAndNewlineCharacterSet; NSUInteger start=NSNotFound;
    for (NSUInteger i=0; i<=text.length; i++) { BOOL boundary=i==text.length || [separators characterIsMember:[text characterAtIndex:i]]; if (!boundary && start==NSNotFound) start=i; if (boundary && start!=NSNotFound) { GDTWord *word=[GDTWord new]; word.identifier=[NSString stringWithFormat:@"w-%lu", (unsigned long)words.count]; word.text=[text substringWithRange:NSMakeRange(start,i-start)]; word.sourceRange=NSMakeRange(offset+start,i-start); [words addObject:word]; start=NSNotFound; } }
    return words;
}
@end

@interface GDTParser ()
@property(nonatomic) id<GDTTextSource> source;
@property(nonatomic) id<GDTTextNormalizer> normalizer;
@property(nonatomic) id<GDTSegmenter> segmenter;
- (void)parseTextFromWebView:(WKWebView *)webView documentID:(NSString *)documentID nodes:(nullable NSArray<GDTContentNode *> *)nodes completion:(void (^)(GDTDocument * _Nullable document, NSError * _Nullable error))completion;
- (void)parseTextFromString:(NSString *)text documentID:(NSString *)documentID nodes:(nullable NSArray<GDTContentNode *> *)nodes completion:(void (^)(GDTDocument * _Nullable document, NSError * _Nullable error))completion;
@end
@implementation GDTParser
- (instancetype)initWithSource:(id<GDTTextSource>)source normalizer:(id<GDTTextNormalizer>)normalizer segmenter:(id<GDTSegmenter>)segmenter { if ((self = [super init])) { self.source = source; self.normalizer = normalizer; self.segmenter = segmenter; } return self; }
- (void)parseWebView:(WKWebView *)webView documentID:(NSString *)documentID completion:(void (^)(GDTDocument *, NSError *))completion {
    if ([self.source conformsToProtocol:@protocol(GDTStructuredTextSource)]) { id<GDTStructuredTextSource> structured=(id<GDTStructuredTextSource>)self.source; [structured readStructuredTextFromWebView:webView completion:^(NSArray<NSDictionary *> *blocks,NSError *error){ if (error || !blocks.count) { [self parseTextFromWebView:webView documentID:documentID nodes:nil completion:completion]; return; } NSMutableString *text=[NSMutableString string]; NSMutableArray<GDTContentNode *> *nodes=[NSMutableArray array]; [blocks enumerateObjectsUsingBlock:^(NSDictionary *block,NSUInteger index,BOOL *stop){ NSString *value=[block[@"text"] isKindOfClass:NSString.class] ? block[@"text"] : @""; if (!value.length) return; if (text.length) [text appendString:@"\n"]; [text appendString:value]; GDTContentNode *node=[GDTContentNode new]; node.identifier=[NSString stringWithFormat:@"node-%lu",(unsigned long)index]; node.order=index; node.text=value; NSString *kind=block[@"kind"]; if ([kind isEqualToString:@"heading"]) node.kind=GDTContentKindHeading; else if ([kind isEqualToString:@"list"]) node.kind=GDTContentKindListItem; else if ([kind isEqualToString:@"table"]) node.kind=GDTContentKindTable; else if ([kind isEqualToString:@"footnote"]) node.kind=GDTContentKindFootnote; else if ([kind isEqualToString:@"link"]) node.kind=GDTContentKindHyperlink; else if ([kind isEqualToString:@"image"]) node.kind=GDTContentKindImage; else node.kind=GDTContentKindParagraph; NSMutableDictionary *attributes=[NSMutableDictionary dictionary]; if ([block[@"href"] length]) attributes[@"href"]=block[@"href"]; if ([block[@"alt"] length]) attributes[@"alt"]=block[@"alt"]; if ([block[@"level"] length]) attributes[@"level"]=block[@"level"]; node.attributes=attributes; [nodes addObject:node]; }]; [self parseTextFromString:text documentID:documentID nodes:nodes completion:completion]; }]; return; }
    [self parseTextFromWebView:webView documentID:documentID nodes:nil completion:completion];
}
- (void)parseTextFromWebView:(WKWebView *)webView documentID:(NSString *)documentID nodes:(NSArray<GDTContentNode *> *)nodes completion:(void (^)(GDTDocument *, NSError *))completion { [self.source readTextFromWebView:webView completion:^(NSString *text,NSError *error){ if (error || !text.length) { completion(nil,error ?: [NSError errorWithDomain:@"GoogleDocsTTS" code:1 userInfo:@{NSLocalizedDescriptionKey:@"No document text found"}]); return; } [self parseTextFromString:text documentID:documentID nodes:nodes completion:completion]; }]; }
- (void)parseTextFromString:(NSString *)text documentID:(NSString *)documentID nodes:(NSArray<GDTContentNode *> *)nodes completion:(void (^)(GDTDocument *, NSError *))completion { [self parseText:text documentID:documentID completion:^(GDTDocument *doc,NSError *error){ doc.nodes=nodes ?: @[]; completion(doc,error); }]; }
- (void)parseText:(NSString *)text documentID:(NSString *)documentID completion:(void (^)(GDTDocument *, NSError *))completion {
    if (!text.length) { completion(nil, [NSError errorWithDomain:@"GoogleDocsTTS" code:2 userInfo:@{NSLocalizedDescriptionKey:@"Text selection is empty"}]); return; }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{ NSString *normalized=[self.normalizer normalizeText:text]; GDTDocument *doc=[GDTDocument new]; doc.documentID=documentID; doc.text=normalized; doc.sentences=[self.segmenter segmentText:normalized]; GDTParagraph *paragraph=[GDTParagraph new]; paragraph.identifier=@"p-0"; paragraph.index=0; paragraph.text=normalized; paragraph.sentences=doc.sentences; GDTSection *section=[GDTSection new]; section.identifier=@"section-0"; section.title=@"Selection"; section.index=0; section.paragraphs=@[paragraph]; doc.sections=@[section]; doc.contentHash=[NSString stringWithFormat:@"%lu",(unsigned long)normalized.hash]; dispatch_async(dispatch_get_main_queue(), ^{ completion(doc,nil); }); });
}
@end
