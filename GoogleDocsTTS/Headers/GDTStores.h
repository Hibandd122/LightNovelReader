#import <Foundation/Foundation.h>
#import "GDTModels.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GDTSessionStore <NSObject>
- (GDTReadingSession *)sessionForDocument:(NSString *)documentID;
- (void)saveSession:(GDTReadingSession *)session;
@end
@protocol GDTBookmarkStore <NSObject>
- (void)saveBookmarkForDocument:(NSString *)documentID sentenceIndex:(NSUInteger)index;
- (NSArray<NSNumber *> *)bookmarksForDocument:(NSString *)documentID;
- (void)saveBookmark:(GDTPlaybackPosition *)position;
- (NSArray<GDTPlaybackPosition *> *)bookmarkPositionsForDocument:(NSString *)documentID;
@end

@protocol GDTLibraryStore <GDTSessionStore, GDTBookmarkStore>
- (BOOL)saveDocument:(GDTDocument *)document error:(NSError **)error;
- (nullable GDTDocument *)documentForID:(NSString *)documentID contentHash:(NSString *)contentHash error:(NSError **)error;
- (void)recordHistoryForDocument:(NSString *)documentID position:(GDTPlaybackPosition *)position;
- (NSArray<GDTPlaybackPosition *> *)historyForDocument:(NSString *)documentID limit:(NSUInteger)limit;
- (GDTSettings *)settings;
- (void)saveSettings:(GDTSettings *)settings;
- (void)recordStatisticsForDocument:(NSString *)documentID seconds:(NSTimeInterval)seconds words:(NSUInteger)words;
@end

@interface GDTUserDefaultsStore : NSObject <GDTLibraryStore>
@end

@interface GDTSQLiteStore : NSObject <GDTLibraryStore>
- (instancetype)initWithURL:(NSURL *)url error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
