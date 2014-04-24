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
#import "Jet/Controls/JetBadge.h"


//
// LSCellFollowingShows
//

@interface LSCellFollowingShows : UICollectionViewCell
@property IBOutlet UIImageView* image;
@property IBOutlet JetBadge* badgeUnwatchedSeriesCount;
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
  self.data.showForDetails = self.data.showsFollowingFiltered[indexPath.row];
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
  return self.data.modelShowsLists.showsFollowingFiltered[indexPath.row];
}

- (NSUInteger) itemsCount
{
  return self.data.modelShowsLists.showsFollowingFiltered.count;
}

- (void) update
{
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
  [self.data.modelShowsLists.showsFollowingFiltered removeAllObjectes];
  for (NSInteger index = 0; index < self.data.modelShowsLists.showsFollowing.count; ++index)
  {
    LSShowAlbumCellModel* show = self.data.modelShowsLists.showsFollowing[index];
    if (
      !text.length ||
      [show.showInfo.title rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound ||
      [show.showInfo.originalTitle rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
      [self.data.modelShowsLists.showsFollowingFiltered addObjectByIndexSource:[self.data.modelShowsLists.showsFollowing indexTargetToSource:index]];
    }
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
    ? [self.data.modelShowsLists.showsFollowingFiltered indexTargetToSource:theIndexNext++]
    : NSNotFound;
}

- (void) serviceArtworkGetter:(LSServiceArtworkGetter*)service didGetArtworkAtIndex:(NSInteger)index
{
  NSInteger indexTarget = [self.data.modelShowsLists.showsFollowingFiltered indexSourceToTarget:index];
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
  cell.badgeUnwatchedSeriesCount.textBadge = @"1";
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  //
  [self registerYourself];
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

- (void) registerYourself
{
  id<LSBaseController> parent = ((id<LSBaseController>)self.parentViewController.parentViewController);
  idController = MakeIdController(parent.idController, self.idControllerShort);
  //
  [[LSApplication singleInstance].registryControllers registerController:self withIdentifier:idController];
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


#pragma mark - LSBaseController implementation


@synthesize idController;

- (NSString*) idControllerShort
{
  return LSShowsFollowingControllerShortID;
}

- (WFWorkflow*) workflow
{
  if (theWorkflow)
  {
    return theWorkflow;
  }  
  //
  LSModelBase* model = [LSApplication singleInstance].modelBase;
  //
  theWLinkCollection = [[LSWLinkFollowingShowsCollection alloc] initWithData:model view:self];
  theWLinkSwitchToDetails = [[LSWLinkShowsFollowingSwitchToDetails alloc] initWithData:model view:self];
  //
  theWorkflow = WFLinkWorkflow(
      theWLinkCollection
    , theWLinkSwitchToDetails
    , nil);
  return theWorkflow;
}


#pragma mark - Views implementation


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

@end


NSString* LSShowsFollowingControllerShortID = @"NSString* LSShowsFollowingController";
