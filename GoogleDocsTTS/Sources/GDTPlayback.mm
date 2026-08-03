#import "GDTPlayback.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface GDTSystemPlaybackCoordinator ()
@property(nonatomic, copy) NSArray<id> *targets;
@end
@implementation GDTSystemPlaybackCoordinator
- (void)configureAudioSession { AVAudioSession *session=AVAudioSession.sharedInstance; [session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeSpokenAudio options:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP error:nil]; [session setActive:YES error:nil]; }
- (void)updateNowPlayingTitle:(NSString *)title progress:(float)progress duration:(NSTimeInterval)duration { MPNowPlayingInfoCenter *center=MPNowPlayingInfoCenter.defaultCenter; center.nowPlayingInfo=@{MPMediaItemPropertyTitle:title ?: @"Google Docs", MPNowPlayingInfoPropertyElapsedPlaybackTime:@(duration*progress), MPMediaItemPropertyPlaybackDuration:@(duration), MPNowPlayingInfoPropertyPlaybackRate:@1.0}; }
- (void)installRemoteCommandsWithPlay:(dispatch_block_t)play pause:(dispatch_block_t)pause next:(dispatch_block_t)next previous:(dispatch_block_t)previous { MPRemoteCommandCenter *remote=MPRemoteCommandCenter.sharedCommandCenter; NSMutableArray *targets=[NSMutableArray array]; MPRemoteCommandHandlerStatus (^handler)(MPRemoteCommandEvent *,dispatch_block_t) = ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event, dispatch_block_t block) { if (block) block(); return MPRemoteCommandHandlerStatusSuccess; }; if (play) [targets addObject:[remote.playCommand addHandlerForEvent:^(MPRemoteCommandEvent *event){ handler(event,play); }]]; if (pause) [targets addObject:[remote.pauseCommand addHandlerForEvent:^(MPRemoteCommandEvent *event){ handler(event,pause); }]]; if (next) [targets addObject:[remote.nextTrackCommand addHandlerForEvent:^(MPRemoteCommandEvent *event){ handler(event,next); }]]; if (previous) [targets addObject:[remote.previousTrackCommand addHandlerForEvent:^(MPRemoteCommandEvent *event){ handler(event,previous); }]]; self.targets=targets; }
- (void)removeRemoteCommands { MPRemoteCommandCenter *remote=MPRemoteCommandCenter.sharedCommandCenter; [self.targets enumerateObjectsUsingBlock:^(id target, NSUInteger idx, BOOL *stop) { [remote.playCommand removeTarget:target]; [remote.pauseCommand removeTarget:target]; [remote.nextTrackCommand removeTarget:target]; [remote.previousTrackCommand removeTarget:target]; }]; self.targets=@[]; }
@end
