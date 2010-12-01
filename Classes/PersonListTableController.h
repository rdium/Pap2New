
#import <UIKit/UIKit.h>


@interface PersonListTableController : UITableViewController {
	
	NSManagedObjectContext *mOC;
	
	NSFetchedResultsController *fetchedResultsController;
	

}

@property (nonatomic, retain) NSManagedObjectContext *mOC;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;



@end
