
#import "Pap2NewAppDelegate.h"

#import "PersonListTableController.h"



@implementation Pap2NewAppDelegate

@synthesize window,photo,person;


#pragma mark -
#pragma mark Fetcher Imported Files



- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(NSString*)entityName withPredicate:(NSPredicate*)predicate {
    NSFetchedResultsController *fetchedResultsController;
    
    /*
	 Set up the fetched results controller.
     */
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
	
	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];
	
	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"user" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
	
    // Add a predicate if we're filtering by user name
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
	// Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
	deleteCacheWithName:nil;
	[fetchRequest release];
	[sortDescriptor release];
	[sortDescriptors release];
	
	return [fetchedResultsController autorelease];
}

- (NSArray *)fetchManagedObjectsForEntity:(NSString*)entityName withPredicate:(NSPredicate*)predicate
{
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext_];
	
	NSFetchRequest	*request = [[NSFetchRequest alloc] init];
	request.entity = entity;
	request.predicate = predicate;
	
	NSArray	*results = [managedObjectContext_ executeFetchRequest:request error:nil];
	[request release];
	
	return results;
}


- (BOOL)databaseExists
{
	NSString	*path = [self databasePath];
	BOOL		databaseExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
	
	return databaseExists;
}

- (NSString *)databasePath
{
	return [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"Pap2New.sqlite"];
}




#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	
    //Check if you have CoreData DB to work with already, if not this process gets data from the plist and sticks it in the existing model.
	
	if (![self databaseExists]) 
		
	{
		[self populateCoreDataStorage];
		
	}
	else {
		
		managedObjectContext_ =	[self managedObjectContext];
		
		if (!managedObjectContext_) {
			// Handle the error.
			NSLog(@"Unresolved error (no context)");
			exit(-1);  // Fail
		}
	}
	
	tab = [[UITabBarController alloc] init];
	
	nC1 =[[UINavigationController alloc] init];
	
	PersonListTableController *pTable = [[PersonListTableController alloc] initWithStyle:UITableViewStylePlain];
	
	pTable.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemContacts tag:1] autorelease];
	
	// REQUIRED?
	//pTable.managedObjectContext = mOC;
	
	
	[nC1 pushViewController:pTable animated:NO];	
	
	[pTable release];
	
	//nC2 =[[UINavigationController alloc] init];
	
	//PhotoListTableController *phTable = [[PhotoListTableController alloc] initWithStyle:UITableViewStylePlain];
	
	//phTable.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemRecents tag:2] autorelease];
	
	//[nC2 pushViewController:phTable animated:NO];	
	
	//[phTable release];
	
	
	NSArray *nCArray = [NSArray arrayWithObjects:nC1,nil];
	
	[tab setViewControllers:nCArray];
	
	[nC1 release];
	//[nC2 release];
	
	[window addSubview:tab.view];
	
	
    [window makeKeyAndVisible];
	
	return YES;
}

-(void)populateCoreDataStorage
{ 
	managedObjectContext_ =	[self managedObjectContext];
	
	if (!managedObjectContext_) {
		// Handle the error.
		NSLog(@"Unresolved error (no context)");
		exit(-1);  // Fail
	}
	
	//Check if you have CoreData DB to work with already, if not this process gets data from the plist and sticks it in the existing model.
	
	NSLog(@"No data in DB yet!");
	
	//Look in the documents directory for the plist file.
	NSString *plistPath;
	NSString *rootPath = [self applicationDocumentsDirectory];
	
    plistPath = [rootPath stringByAppendingPathComponent:@"FakeData.plist"];
	
	//If the file isn't in the documents directory(a new/edited plist?) take a look in the existing bundle. 
	
	NSArray *plistData;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
		
		NSString *bundlePath;
		bundlePath = [[NSBundle mainBundle] pathForResource:@"FakeData" ofType:@"plist"];
		plistData = [NSArray arrayWithContentsOfFile:bundlePath];
		
		if (plistData) {
            [plistData writeToFile:plistPath atomically:YES];
			NSLog(@"NewArray from Bundle written to docs:%@",plistData);
			
			
        }
	} else {
        
		plistData = [NSArray arrayWithContentsOfFile:plistPath];
		
		NSLog(@"No Array from Bundle either -empty array?:%@",plistData);
	}
	
	//Create a new instance of the Photo and Person Entities using an enumerator looping the array to fill contents into CoreData
	
	NSEnumerator *enumr = [plistData objectEnumerator];
	id curr = [enumr nextObject];
	NSMutableArray *names = [[NSMutableArray alloc] init];
	
	NSLog(@"NextObject in array enumeration:%@",curr);
	
	while (curr != nil)
		
	{
		
		photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:managedObjectContext_];
		[photo setName:[curr objectForKey:@"name"]];		
		[photo setUrl:[curr objectForKey:@"path"]];
		
		
		
		NSLog(@"Photo added: %@", photo);
		
		//See if the name has already been set for a Person object...
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ IN %@", [curr objectForKey:@"user"], names];
		
		NSLog(@"Predicate: %@", predicate);
		BOOL doesExist = [predicate evaluateWithObject:curr];
		
		if (doesExist == NO)
			
		{	
			person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:managedObjectContext_];
			
			
			[person setUser:[curr objectForKey:@"user"]];
			
			
		//	[person addPhoto:photo];
		//	[photo setPerson:person];
			
			NSLog(@"Person OBJECT: %@", person);
			[names addObject:[curr objectForKey:@"user"]];
			
		} else 
			
		{
			NSArray *objectArray = [self fetchManagedObjectsForEntity:@"Person" withPredicate:predicate];
			person = [objectArray objectAtIndex:0];
			
		//	[photo setPerson:person];
		//	[person addPhoto:photo];
			NSLog(@"Person OBJECT which has a photo already: %@", person);
			//REQUIRED: Also require establishing the reciprocal relationship for Person entity?
			
		}
		curr = [enumr nextObject];
	}
	[names release];
	
}



- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
    
    NSError *error = nil;
    if (managedObjectContext_ != nil) {
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Pap2New" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}




/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"Pap2New.sqlite"]];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator_;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    
	[person release];
	[photo release];
	
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    
    [window release];
    [super dealloc];
}


@end

