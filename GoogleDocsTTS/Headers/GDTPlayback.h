#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GDTPlaybackCoordinator <NSObject>
- (void)configureAudioSession;
- (void)updateNowPlayingTitle:(NSString *)title progress:(float)progress duration:(NSTimeInterval)duration;
- (void)installRemoteCommandsWithPlay:(dispatch_block_t)play pause:(dispatch_block_t)pause next:(dispatch_block_t)next previous:(dispatch_block_t)previous;
- (void)removeRemoteCommands;
@end

@interface GDTSystemPlaybackCoordinator : NSObject <GDTPlaybackCoordinator>
@end

NS_ASSUME_NONNULL_END
