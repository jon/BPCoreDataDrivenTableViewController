//
//  BPCoreDataDrivenTableViewController.h
//  Skates
//
//  Created by Jon Olson on 2/9/10.
//  Copyright 2010 Ballistic Pigeon, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BPCoreDataDrivenTableViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
	NSManagedObjectContext *managedObjectContext;
	NSFetchedResultsController *fetchedResultsController;
	NSEntityDescription *entityDescription;
	
	Class inspectorClass;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSEntityDescription *entityDescription;

- (NSString *)managedEntityName;
- (NSString *)defaultSortKey;
- (NSString *)defaultSectionKey;
- (NSString *)defaultCellLabelKey;
- (NSString *)defaultCacheName;
- (NSString *)inspectorClassName;

// This is anagous to loadView. Only implement this if you need to do something special, there is a default implementation, although it requires you to implement managedEntityName
- (void)createFetchedResultsController;

- (UITableViewCell *)cellForManagedObject:(NSManagedObject *)object inTableView:(UITableView *)tableView;
- (void)configureCell:(UITableViewCell *)cell withManagedObject:(NSManagedObject *)object;

- (IBAction)addEntity:(id)sender;

@end

@protocol BPManagedObjectInspectorViewController

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (void)setManagedObject:(NSManagedObject *)managedObject;

- (IBAction)save:(id)sender;

@end
