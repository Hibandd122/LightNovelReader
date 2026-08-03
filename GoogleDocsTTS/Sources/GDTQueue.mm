#import "GDTQueue.h"

@implementation GDTQueueItem
+ (BOOL)supportsSecureCoding { return YES; }
- (void)encodeWithCoder:(NSCoder *)c { [c encodeObject:self.documentID forKey:@"documentID"]; [c encodeInteger:self.startSentence forKey:@"startSentence"]; [c encodeObject:self.title forKey:@"title"]; }
- (instancetype)initWithCoder:(NSCoder *)c { if ((self=[super init])) { _documentID=[c decodeObjectOfClass:NSString.class forKey:@"documentID"] ?: @""; _startSentence=[c decodeIntegerForKey:@"startSentence"]; _title=[c decodeObjectOfClass:NSString.class forKey:@"title"] ?: @""; } return self; }
@end

@interface GDTSerialReadingQueue ()
@property(nonatomic) NSMutableArray<GDTQueueItem *> *mutableItems;
@property(nonatomic) dispatch_queue_t queue;
@end
@implementation GDTSerialReadingQueue
- (instancetype)init { if ((self=[super init])) { _mutableItems=[NSMutableArray array]; _queue=dispatch_queue_create("com.google.docs.tts.queue", DISPATCH_QUEUE_SERIAL); } return self; }
- (NSArray<GDTQueueItem *> *)items { __block NSArray *items; dispatch_sync(self.queue, ^{ items=[self.mutableItems copy]; }); return items; }
- (void)enqueue:(GDTQueueItem *)item { if (!item.documentID.length) return; dispatch_async(self.queue, ^{ NSUInteger index=[self.mutableItems indexOfObjectPassingTest:^BOOL(GDTQueueItem *existing, NSUInteger idx, BOOL *stop){ return [existing.documentID isEqualToString:item.documentID]; }]; if (index==NSNotFound) [self.mutableItems addObject:item]; }); }
- (GDTQueueItem *)dequeue { __block GDTQueueItem *item; dispatch_sync(self.queue, ^{ if (self.mutableItems.count) { item=self.mutableItems.firstObject; [self.mutableItems removeObjectAtIndex:0]; } }); return item; }
- (void)removeDocumentID:(NSString *)documentID { dispatch_async(self.queue, ^{ NSIndexSet *indexes=[self.mutableItems indexesOfObjectsPassingTest:^BOOL(GDTQueueItem *item, NSUInteger idx, BOOL *stop){ return [item.documentID isEqualToString:documentID]; }]; [self.mutableItems removeObjectsAtIndexes:indexes]; }); }
- (void)clear { dispatch_async(self.queue, ^{ [self.mutableItems removeAllObjects]; }); }
@end
