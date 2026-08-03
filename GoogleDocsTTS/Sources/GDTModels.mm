#import "GDTModels.h"

@implementation GDTContentNode
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.identifier forKey:@"id"]; [c encodeInteger:self.kind forKey:@"kind"]; [c encodeObject:self.text forKey:@"text"]; [c encodeObject:self.attributes forKey:@"attributes"]; [c encodeInteger:self.order forKey:@"order"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self=[super init])) { _identifier=[c decodeObjectOfClass:NSString.class forKey:@"id"] ?: @""; _kind=[c decodeIntegerForKey:@"kind"]; _text=[c decodeObjectOfClass:NSString.class forKey:@"text"] ?: @""; _attributes=[c decodeObjectOfClasses:[NSSet setWithObjects:NSDictionary.class,NSString.class,nil] forKey:@"attributes"] ?: @{}; _order=[c decodeIntegerForKey:@"order"]; } return self; }
@end

@implementation GDTWord
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.identifier forKey:@"id"]; [c encodeObject:self.text forKey:@"text"]; [c encodeInteger:self.sourceRange.location forKey:@"location"]; [c encodeInteger:self.sourceRange.length forKey:@"length"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self = [super init])) { _identifier=[c decodeObjectOfClass:NSString.class forKey:@"id"] ?: @""; _text=[c decodeObjectOfClass:NSString.class forKey:@"text"] ?: @""; _sourceRange=NSMakeRange([c decodeIntegerForKey:@"location"], [c decodeIntegerForKey:@"length"]); } return self; }
@end

@implementation GDTSentence
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.identifier forKey:@"id"]; [c encodeObject:self.text forKey:@"text"]; [c encodeInteger:self.paragraphIndex forKey:@"paragraph"]; [c encodeInteger:self.sourceRange.location forKey:@"location"]; [c encodeInteger:self.sourceRange.length forKey:@"length"]; [c encodeObject:self.words forKey:@"words"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self = [super init])) { _identifier = [c decodeObjectOfClass:NSString.class forKey:@"id"] ?: @""; _text = [c decodeObjectOfClass:NSString.class forKey:@"text"] ?: @""; _paragraphIndex = [c decodeIntegerForKey:@"paragraph"]; _sourceRange = NSMakeRange([c decodeIntegerForKey:@"location"], [c decodeIntegerForKey:@"length"]); _words = [c decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, GDTWord.class, nil] forKey:@"words"] ?: @[]; } return self; }
@end

@implementation GDTParagraph
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.identifier forKey:@"id"]; [c encodeObject:self.text forKey:@"text"]; [c encodeInteger:self.index forKey:@"index"]; [c encodeObject:self.sentences forKey:@"sentences"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self=[super init])) { _identifier=[c decodeObjectOfClass:NSString.class forKey:@"id"] ?: @""; _text=[c decodeObjectOfClass:NSString.class forKey:@"text"] ?: @""; _index=[c decodeIntegerForKey:@"index"]; _sentences=[c decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, GDTSentence.class, nil] forKey:@"sentences"] ?: @[]; } return self; }
@end

@implementation GDTSection
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.identifier forKey:@"id"]; [c encodeObject:self.title forKey:@"title"]; [c encodeInteger:self.index forKey:@"index"]; [c encodeObject:self.paragraphs forKey:@"paragraphs"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self=[super init])) { _identifier=[c decodeObjectOfClass:NSString.class forKey:@"id"] ?: @""; _title=[c decodeObjectOfClass:NSString.class forKey:@"title"] ?: @""; _index=[c decodeIntegerForKey:@"index"]; _paragraphs=[c decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, GDTParagraph.class, nil] forKey:@"paragraphs"] ?: @[]; } return self; }
@end

@implementation GDTDocument
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.documentID forKey:@"documentID"]; [c encodeObject:self.text forKey:@"text"]; [c encodeObject:self.sentences forKey:@"sentences"]; [c encodeObject:self.sections forKey:@"sections"]; [c encodeObject:self.nodes forKey:@"nodes"]; [c encodeObject:self.contentHash forKey:@"hash"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self = [super init])) { _documentID = [c decodeObjectOfClass:NSString.class forKey:@"documentID"] ?: @""; _text = [c decodeObjectOfClass:NSString.class forKey:@"text"] ?: @""; _sentences = [c decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, GDTSentence.class, nil] forKey:@"sentences"] ?: @[]; _sections = [c decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, GDTSection.class, GDTParagraph.class, GDTSentence.class, nil] forKey:@"sections"] ?: @[]; _nodes = [c decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, GDTContentNode.class, NSDictionary.class, NSString.class, nil] forKey:@"nodes"] ?: @[]; _contentHash = [c decodeObjectOfClass:NSString.class forKey:@"hash"] ?: @""; } return self; }
@end

@implementation GDTPlaybackPosition
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.documentID forKey:@"documentID"]; [c encodeInteger:self.sectionIndex forKey:@"section"]; [c encodeInteger:self.paragraphIndex forKey:@"paragraph"]; [c encodeInteger:self.sentenceIndex forKey:@"sentence"]; [c encodeInteger:self.wordIndex forKey:@"word"]; [c encodeInteger:self.characterOffset forKey:@"character"]; [c encodeDouble:self.scrollOffset forKey:@"scroll"]; [c encodeFloat:self.progress forKey:@"progress"]; [c encodeObject:self.timestamp forKey:@"timestamp"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self=[super init])) { _documentID=[c decodeObjectOfClass:NSString.class forKey:@"documentID"] ?: @""; _sectionIndex=[c decodeIntegerForKey:@"section"]; _paragraphIndex=[c decodeIntegerForKey:@"paragraph"]; _sentenceIndex=[c decodeIntegerForKey:@"sentence"]; _wordIndex=[c decodeIntegerForKey:@"word"]; _characterOffset=[c decodeIntegerForKey:@"character"]; _scrollOffset=[c decodeDoubleForKey:@"scroll"]; _progress=[c decodeFloatForKey:@"progress"]; _timestamp=[c decodeObjectOfClass:NSDate.class forKey:@"timestamp"] ?: [NSDate date]; } return self; }
@end

@implementation GDTReadingSession
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.documentID forKey:@"documentID"]; [c encodeInteger:self.sentenceIndex forKey:@"sentence"]; [c encodeInteger:self.paragraphIndex forKey:@"paragraph"]; [c encodeInteger:self.wordIndex forKey:@"word"]; [c encodeInteger:self.characterOffset forKey:@"character"]; [c encodeDouble:self.scrollOffset forKey:@"scroll"]; [c encodeInteger:self.state forKey:@"state"]; [c encodeFloat:self.rate forKey:@"rate"]; [c encodeFloat:self.progress forKey:@"progress"]; [c encodeObject:self.updatedAt forKey:@"updatedAt"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self = [super init])) { _documentID = [c decodeObjectOfClass:NSString.class forKey:@"documentID"] ?: @""; _sentenceIndex = [c decodeIntegerForKey:@"sentence"]; _paragraphIndex=[c decodeIntegerForKey:@"paragraph"]; _wordIndex=[c decodeIntegerForKey:@"word"]; _characterOffset=[c decodeIntegerForKey:@"character"]; _scrollOffset=[c decodeDoubleForKey:@"scroll"]; _state = [c decodeIntegerForKey:@"state"]; _rate = [c decodeFloatForKey:@"rate"]; _progress=[c decodeFloatForKey:@"progress"]; _updatedAt = [c decodeObjectOfClass:NSDate.class forKey:@"updatedAt"]; } return self; }
@end

@implementation GDTSettings
+ (BOOL)supportsSecureCoding { return YES; }
- (instancetype)init { if ((self=[super init])) { _speed=0.5f; _pitch=1.0f; _volume=1.0f; _highlightMode=GDTHighlightModeSentence; _autoScroll=YES; _rememberPosition=YES; _accessibilityAnnouncements=YES; _cacheSizeMB=128; _theme=@"system"; } return self; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.voiceIdentifier forKey:@"voice"]; [c encodeFloat:self.speed forKey:@"speed"]; [c encodeFloat:self.pitch forKey:@"pitch"]; [c encodeFloat:self.volume forKey:@"volume"]; [c encodeInteger:self.highlightMode forKey:@"highlight"]; [c encodeBool:self.autoScroll forKey:@"autoScroll"]; [c encodeBool:self.rememberPosition forKey:@"remember"]; [c encodeBool:self.accessibilityAnnouncements forKey:@"accessibility"]; [c encodeDouble:self.sleepTimer forKey:@"sleep"]; [c encodeInteger:self.cacheSizeMB forKey:@"cacheSize"]; [c encodeObject:self.theme forKey:@"theme"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self=[self init])) { _voiceIdentifier=[c decodeObjectOfClass:NSString.class forKey:@"voice"]; _speed=[c decodeFloatForKey:@"speed"]; _pitch=[c decodeFloatForKey:@"pitch"]; _volume=[c decodeFloatForKey:@"volume"]; _highlightMode=[c decodeIntegerForKey:@"highlight"]; _autoScroll=[c decodeBoolForKey:@"autoScroll"]; _rememberPosition=[c decodeBoolForKey:@"remember"]; _accessibilityAnnouncements=[c decodeBoolForKey:@"accessibility"]; _sleepTimer=[c decodeDoubleForKey:@"sleep"]; _cacheSizeMB=[c decodeIntegerForKey:@"cacheSize"]; _theme=[c decodeObjectOfClass:NSString.class forKey:@"theme"] ?: @"system"; } return self; }
@end
