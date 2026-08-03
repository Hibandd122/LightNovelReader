#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GDTReadingState) {
    GDTReadingStateIdle,
    GDTReadingStatePlaying,
    GDTReadingStatePaused,
    GDTReadingStateFinished,
    GDTReadingStateFailed
};

typedef NS_ENUM(NSInteger, GDTHighlightMode) {
    GDTHighlightModeNone,
    GDTHighlightModeSentence,
    GDTHighlightModeParagraph,
    GDTHighlightModeWord
};

typedef NS_ENUM(NSInteger, GDTContentKind) {
    GDTContentKindParagraph,
    GDTContentKindHeading,
    GDTContentKindListItem,
    GDTContentKindTable,
    GDTContentKindFootnote,
    GDTContentKindHyperlink,
    GDTContentKindImage,
    GDTContentKindComment
};

@interface GDTContentNode : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic) GDTContentKind kind;
@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSDictionary<NSString *, NSString *> *attributes;
@property(nonatomic) NSUInteger order;
@end

@interface GDTWord : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *text;
@property(nonatomic) NSRange sourceRange;
@end

@interface GDTSentence : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *text;
@property(nonatomic) NSUInteger paragraphIndex;
@property(nonatomic) NSRange sourceRange;
@property(nonatomic, copy) NSArray<GDTWord *> *words;
@end

@interface GDTParagraph : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *text;
@property(nonatomic) NSUInteger index;
@property(nonatomic, copy) NSArray<GDTSentence *> *sentences;
@end

@interface GDTSection : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *title;
@property(nonatomic) NSUInteger index;
@property(nonatomic, copy) NSArray<GDTParagraph *> *paragraphs;
@end

@interface GDTDocument : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *documentID;
@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSArray<GDTSentence *> *sentences;
@property(nonatomic, copy) NSArray<GDTSection *> *sections;
@property(nonatomic, copy) NSArray<GDTContentNode *> *nodes;
@property(nonatomic, copy) NSString *contentHash;
@end

@interface GDTPlaybackPosition : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *documentID;
@property(nonatomic) NSUInteger sectionIndex;
@property(nonatomic) NSUInteger paragraphIndex;
@property(nonatomic) NSUInteger sentenceIndex;
@property(nonatomic) NSUInteger wordIndex;
@property(nonatomic) NSUInteger characterOffset;
@property(nonatomic) double scrollOffset;
@property(nonatomic) float progress;
@property(nonatomic, strong) NSDate *timestamp;
@end

@interface GDTReadingSession : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *documentID;
@property(nonatomic) NSUInteger sentenceIndex;
@property(nonatomic) NSUInteger paragraphIndex;
@property(nonatomic) NSUInteger wordIndex;
@property(nonatomic) NSUInteger characterOffset;
@property(nonatomic) double scrollOffset;
@property(nonatomic) float progress;
@property(nonatomic) GDTReadingState state;
@property(nonatomic) float rate;
@property(nonatomic, strong, nullable) NSDate *updatedAt;
@end

@interface GDTSettings : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *voiceIdentifier;
@property(nonatomic) float speed;
@property(nonatomic) float pitch;
@property(nonatomic) float volume;
@property(nonatomic) GDTHighlightMode highlightMode;
@property(nonatomic) BOOL autoScroll;
@property(nonatomic) BOOL rememberPosition;
@property(nonatomic) BOOL accessibilityAnnouncements;
@property(nonatomic) NSTimeInterval sleepTimer;
@property(nonatomic) NSUInteger cacheSizeMB;
@property(nonatomic, copy) NSString *theme;
@end

NS_ASSUME_NONNULL_END
