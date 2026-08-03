#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

NS_ASSUME_NONNULL_BEGIN

@interface GDTQueueItem : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *documentID;
@property(nonatomic) NSUInteger startSentence;
@property(nonatomic, copy) NSString *title;
@end

@protocol GDTReadingQueue <NSObject>
@property(nonatomic, readonly) NSArray<GDTQueueItem *> *items;
- (void)enqueue:(GDTQueueItem *)item;
- (nullable GDTQueueItem *)dequeue;
- (void)removeDocumentID:(NSString *)documentID;
- (void)clear;
@end

@interface GDTSerialReadingQueue : NSObject <GDTReadingQueue>
@end

NS_ASSUME_NONNULL_END
