import XCTest
@testable import LightNovelReader

final class SegmentTextForTTSUseCaseTests: XCTestCase {
    
    private var segmenter = TextSegmenter()
    
    override func setUp() {
        super.setUp()
        segmenter = TextSegmenter()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSegmenter_WithEnglishSentences_ShouldSplitByPeriod() {
        let text = "Hello world. This is a test. Can it split?"
        let sentences = segmenter.split(text)
        
        XCTAssertEqual(sentences.count, 3)
        XCTAssertEqual(sentences[0], "Hello world.")
        XCTAssertEqual(sentences[1], "This is a test.")
        XCTAssertEqual(sentences[2], "Can it split?")
    }
    
    func testSegmenter_WithJapaneseQuotes_ShouldNotBreakInsideQuote() {
        let text = "Cậu ấy nói: 「Xin chào, tôi là AI.」 và rời đi."
        let sentences = segmenter.split(text)
        
        XCTAssertEqual(sentences.count, 2)
        XCTAssertEqual(sentences[0], "Cậu ấy nói: 「Xin chào, tôi là AI.」")
        XCTAssertEqual(sentences[1], "và rời đi.")
    }
    
    func testSegmenter_WithNoPunctuation_ShouldReturnWholeText() {
        let text = "This is a single sentence without punctuation"
        let sentences = segmenter.split(text)
        
        XCTAssertEqual(sentences.count, 1)
        XCTAssertEqual(sentences[0], text)
    }

    func testSegmenter_WithVietnameseTextAndQuotes_ShouldKeepSentenceTogether() {
        let text = "Cậu ấy nói: \"Xin chào, tôi là AI.\" Và rồi đi."
        let sentences = segmenter.split(text)

        XCTAssertEqual(sentences, ["Cậu ấy nói: \"Xin chào, tôi là AI.\"", "Và rồi đi."])
    }

    func testSegmenter_WithVietnameseParagraphs_ShouldSplitWithoutPunctuation() {
        let text = "Đoạn đầu\n\nĐoạn sau"
        XCTAssertEqual(segmenter.split(text), ["Đoạn đầu", "Đoạn sau"])
    }
}