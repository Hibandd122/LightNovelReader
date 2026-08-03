#import <XCTest/XCTest.h>
#import "GDTParser.h"

@interface GDTMockSource : NSObject <GDTTextSource>
@property(nonatomic, copy) NSString *text;
@end
@implementation GDTMockSource
- (void)readTextFromWebView:(WKWebView *)webView completion:(void (^)(NSString *, NSError *))completion { completion(self.text,nil); }
@end

@interface GDTParserTests : XCTestCase
@end
@implementation GDTParserTests
- (void)testParserNormalizesAndBuildsWordIndex { GDTMockSource *source=[GDTMockSource new]; source.text=@"  First   sentence.\nSecond sentence!  "; GDTParser *parser=[[GDTParser alloc] initWithSource:source normalizer:[GDTDefaultNormalizer new] segmenter:[GDTSentenceSegmenter new]]; XCTestExpectation *expectation=[self expectationWithDescription:@"parse"]; [parser parseWebView:[WKWebView new] documentID:@"doc" completion:^(GDTDocument *document,NSError *error){ XCTAssertNil(error); XCTAssertEqual(document.sentences.count,2u); XCTAssertEqualObjects(document.sentences.firstObject.text,@"First sentence."); XCTAssertGreaterThan(document.sentences.firstObject.words.count,1u); XCTAssertEqual(document.sections.count,1u); XCTAssertEqual(document.sections.firstObject.paragraphs.count,2u); [expectation fulfill]; }]; [self waitForExpectationsWithTimeout:2 handler:nil]; }
- (void)testEmptyTextFailsClosed { GDTMockSource *source=[GDTMockSource new]; source.text=@""; GDTParser *parser=[[GDTParser alloc] initWithSource:source normalizer:[GDTDefaultNormalizer new] segmenter:[GDTSentenceSegmenter new]]; XCTestExpectation *expectation=[self expectationWithDescription:@"empty"]; [parser parseWebView:[WKWebView new] documentID:@"doc" completion:^(GDTDocument *document,NSError *error){ XCTAssertNil(document); XCTAssertNotNil(error); [expectation fulfill]; }]; [self waitForExpectationsWithTimeout:2 handler:nil]; }
- (void)testParseTextCreatesStableDocumentIDAndNodesCanBeAttached { GDTParser *parser=[[GDTParser alloc] initWithSource:[GDTMockSource new] normalizer:[GDTDefaultNormalizer new] segmenter:[GDTSentenceSegmenter new]]; XCTestExpectation *expectation=[self expectationWithDescription:@"text"]; [parser parseText:@"Heading text." documentID:@"selection-1" completion:^(GDTDocument *document,NSError *error){ XCTAssertNil(error); XCTAssertEqualObjects(document.documentID,@"selection-1"); XCTAssertEqual(document.sentences.firstObject.sourceRange.location,0u); [expectation fulfill]; }]; [self waitForExpectationsWithTimeout:2 handler:nil]; }
@end
