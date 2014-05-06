//
//  LSWLinkActionChangeUnwatchedEpisodes.m
//  LostSeries
//
//  Created by Grigory Zubankov on 05/05/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSWLinkActionChangeUnwatchedEpisodes.h"
#import "Logic/LSApplication.h"

//
// LSWLinkActionChangeUnwatchedEpisodes
//

@implementation LSWLinkActionChangeUnwatchedEpisodes

SYNTHESIZE_WL_ACCESSORS(LSDataActionChangeUnwatchedEpisodes, LSViewActionChangeUnwatchedEpisodes);

- (void) input
{
  [self.view updateActionIndicatorChangeUnwatchedEpisodes:YES];
  //
  [self changeModel];
  //
  [self.data.backendFacade
    setUnwatchedEpisodesByCDID:[LSApplication singleInstance].cdid
    episodesUnwatched:self.episodesUnwatched
    flagRemove:self.data.flagRemove
    replyHandler:^(BOOL result)
  {
    [self.view updateActionIndicatorChangeUnwatchedEpisodes:NO];
    if (result)
    {
      [self output];
    }
  }];
  //
  [self forwardBlock];
}

- (NSArray*) episodesUnwatched
{
  NSMutableArray* episodesUnwatched = [NSMutableArray array];
  for (LSEpisodeInfo* episode in self.data.episodesToChange)
  {
    LSEpisodeUnwatchedInfo* episodeUnwatched = [[LSEpisodeUnwatchedInfo alloc] init];
    episodeUnwatched.idShow = self.data.show.showInfo.showID;
    episodeUnwatched.numberSeason = self.data.show.showInfo.seasonNumber;
    episodeUnwatched.numberEpisode = episode.number;
    //
    [episodesUnwatched addObject:episodeUnwatched];
  }
  return episodesUnwatched;
}

- (void) changeModel
{
  if (self.data.flagRemove)
  {
    for (LSEpisodeInfo* episode in self.data.episodesToChange)
    {
//      NSInteger index = [self.data.show.showInfo.episodesUnwatched indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL* stop)
//      {
//        return ((LSEpisodeInfo*)object).number == episode.number;
//      }];
      NSMutableArray* episodesUnwatched = [NSMutableArray arrayWithArray:self.data.show.showInfo.episodesUnwatched];
      [episodesUnwatched removeObject:episode];
      self.data.show.showInfo.episodesUnwatched = episodesUnwatched;
    }
  }
  else
  {
    self.data.show.showInfo.episodesUnwatched = [self.data.show.showInfo.episodesUnwatched arrayByAddingObjectsFromArray:self.data.episodesToChange];
  }
  //
  [self.data modelDidChange];
}

@end
