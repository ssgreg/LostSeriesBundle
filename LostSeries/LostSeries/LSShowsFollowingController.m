//
//  LSShowsFollowingController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSShowsFollowingController.h"
#import "LSControllerShowDetails.h"
#import "LSModelBase.h"
#import "Logic/LSApplication.h"



//
// LSCellFollowingShows
//

@interface LSCellFollowingShows : UICollectionViewCell
@property IBOutlet UIImageView* overlay;
@property IBOutlet UIImageView* image;
@property IBOutlet UIImageView* subscriptionOverlay;
@property IBOutlet UILabel* detail;
@end

@implementation LSCellFollowingShows
@end


//
// LSWLinkShowsFollowingSwitchToDetails
//

@protocol LSDataShowsFollowingSwitchToDetails <LSDataBaseShowsFollowing, LSDataBaseModelShowForDatails>
@end

@interface LSWLinkShowsFollowingSwitchToDetails : WFWorkflowLink
@end

@implementation LSWLinkShowsFollowingSwitchToDetails

SYNTHESIZE_WL_ACCESSORS(LSDataShowsFollowingSwitchToDetails, LSViewFollowingSwitcherShowDetails);

- (void) didSelectItemAtIndex:(NSIndexPath*)indexPath
{
  self.data.showForDetails = self.data.showsFollowingSorted[indexPath.row];
  //
  [self.view switchToController:@"LSShowsFollowingController.ShowDetails"];
  [self input];
}

- (void) input
{
  LSRegistryControllers* registry = [LSApplication singleInstance].registryControllers;
  LSControllerShowDetails* controller = [registry findControllerByIdentifier:@"LSShowsFollowingController.ShowDetails"];
  [controller.workflow input];
}

@end


//
// LSWLinkFollowingShowsCollection
//

@interface LSWLinkFollowingShowsCollection : WFWorkflowLink <LSClientServiceArtworkGetters>

- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath;
- (NSUInteger) itemsCount;

@end

@implementation LSWLinkFollowingShowsCollection
{
  NSRange theRangeVisibleItems;
  NSInteger theIndexNext;
  //
  NSString* theTextFilter;
}

SYNTHESIZE_WL_ACCESSORS(LSDataBaseModelShowsLists, LSViewFollowingShowsCollection);

- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath
{
  return self.data.modelShowsLists.showsFollowingSorted[indexPath.row];
}

- (NSUInteger) itemsCount
{
  return self.data.modelShowsLists.showsFollowingSorted.count;
}

- (void) update
{
  [self updateView];
  //
  theRangeVisibleItems = NSMakeRange(0, 0);
  theIndexNext = NSNotFound;
  // artworks
  [[LSApplication singleInstance].serviceArtworkGetter addClient:self];
}

- (void) input
{
  [self filterByString: theTextFilter];
  [self output];
}

- (void) updateView
{
  [self.view showCollectionReloadData];
}

- (void) filterByString:(NSString*)text
{
  if (text.length)
  {
    self.data.modelShowsLists.showsFollowingSorted = [self.data.modelShowsLists makeEmptyArrayPartial];
    for (NSInteger index = 0; index < self.data.modelShowsLists.showsFollowing.count; ++index)
    {
      LSShowAlbumCellModel* show = self.data.modelShowsLists.showsFollowing[index];
      if ([show.showInfo.title rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [show.showInfo.originalTitle rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound)
      {
        [self.data.modelShowsLists.showsFollowingSorted addObjectByIndexSource:[self.data.modelShowsLists.showsFollowing indexTargetToSource:index]];
      }
    }
  }
  else
  {
    self.data.modelShowsLists.showsFollowingSorted = self.data.modelShowsLists.showsFollowing;
  }
  theTextFilter = text;
  // reset range to renew artwork download
  theRangeVisibleItems = NSMakeRange(0, 0);
  [self updateView];
}

#pragma mark - LSBatchArtworkGetterDelegate implementation

- (LSServiceArtworkGetterPriority) priorityForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  return [self.view showCollectionIsActive] ? LSServiceArtworkGetterPriorityHigh : LSServiceArtworkGetterPriorityNormal;
}

- (NSInteger) nextIndexForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  NSRange newRange = [self.view showCollectionVisibleItemRange];
  if (!NSEqualRanges(theRangeVisibleItems, newRange))
  {
    theRangeVisibleItems = newRange;
    theIndexNext = theRangeVisibleItems.location;
  }
  return NSLocationInRange(theIndexNext, theRangeVisibleItems)
    ? [self.data.modelShowsLists.showsFollowingSorted indexTargetToSource:theIndexNext++]
    : NSNotFound;
}

- (void) serviceArtworkGetter:(LSServiceArtworkGetter*)service didGetArtworkAtIndex:(NSInteger)index
{
  NSInteger indexTarget = [self.data.modelShowsLists.showsFollowingSorted indexSourceToTarget:index];
  if (indexTarget != NSNotFound)
  {
    [self.view showCollectionUpdateItemAtIndex:[NSIndexPath indexPathForRow:indexTarget inSection:0]];
  }
}

@end


//
// LSShowsFollowingController
//

@implementation LSShowsFollowingController
{
  IBOutlet UICollectionView* theCollectionView;
  IBOutlet UINavigationItem* theNavigationItem;
  // workflow
  WFWorkflow* theWorkflow;
  LSWLinkFollowingShowsCollection* theWLinkCollection;
  LSWLinkShowsFollowingSwitchToDetails* theWLinkSwitchToDetails;
}

- (WFWorkflow*) workflow
{
  return theWorkflow;
}

- (void) updateCell:(LSCellFollowingShows*)cell forIndexPath:(NSIndexPath*)indexPath
{
  LSShowAlbumCellModel* model = [theWLinkCollection itemAtIndex:indexPath];
  //text
  cell.detail.text = model.showInfo.title;
  //
  if (model.artwork)
  {
    cell.image.image = model.artwork;
    cell.detail.hidden = YES;
  }
  else
  {
    cell.image.image = [UIImage imageNamed:@"StubTVShowImage"];
    cell.detail.hidden = NO;
  }
  //
  cell.image.alpha = 1;
  cell.overlay.hidden = YES;
  cell.subscriptionOverlay.hidden = YES;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  LSModelBase* model = [LSApplication singleInstance].modelBase;
  //
  theWLinkCollection = [[LSWLinkFollowingShowsCollection alloc] initWithData:model view:self];
  theWLinkSwitchToDetails = [[LSWLinkShowsFollowingSwitchToDetails alloc] initWithData:model view:self];
  //
  theWorkflow = WFLinkWorkflow(
      theWLinkCollection
    , theWLinkSwitchToDetails
    , nil);
  
  [[NSNotificationCenter defaultCenter] postNotificationName:LSShowsFollowingControllerDidLoadNotification object:self];
}

- (void) searchBarTextDidChange:(NSString*)text
{
  [theWLinkCollection filterByString:text];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
  LSControllerShowDetails* controller = segue.destinationViewController;
  controller.idController = segue.identifier;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void) showCollectionReloadData
{
  [self reloadData];
}

- (BOOL) showCollectionIsActive
{
  return self.tabBarController.selectedIndex == 1;
}

- (NSRange) showCollectionVisibleItemRange
{
  return [self rangeVisibleItems];
}

- (void) showCollectionUpdateItemAtIndex:(NSIndexPath*)indexPath
{
  LSCellFollowingShows* cell = (LSCellFollowingShows*)[theCollectionView cellForItemAtIndexPath:indexPath];
  if (cell)
  {
    [self updateCell:cell forIndexPath:indexPath];
    [cell setNeedsLayout];
  }
}

- (void) switchToController:(NSString*)identifier
{
  [self performSegueWithIdentifier:identifier sender:self];
}


#pragma mark - UICollectionViewDataSource implementation


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  NSUInteger itemCount = [theWLinkCollection itemsCount];
//  theCollectionViewLoadingStub.hidden = itemCount > 0;
  return itemCount;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  LSCellFollowingShows* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"theCellFollowingShows" forIndexPath:indexPath];
  [self updateCell:cell forIndexPath:indexPath];
  return cell;
}


#pragma mark - UICollectionViewDelegate implementation


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  [theWLinkSwitchToDetails didSelectItemAtIndex:indexPath];
}

@end


//
// Notifications
//

NSString* LSShowsFollowingControllerDidLoadNotification = @"LSShowsFollowingControllerDidLoadNotification";
