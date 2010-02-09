//
//  BPCoreDataDrivenTableViewController.m
//  Skates
//
//  Created by Jon Olson on 2/9/10.
//  Copyright 2010 Ballistic Pigeon, LLC. All rights reserved.
//

#import "BPCoreDataDrivenTableViewController.h"


@interface BPCoreDataDrivenTableViewController (Private)

@end

@implementation BPCoreDataDrivenTableViewController

#pragma mark -
#pragma mark Construction and deallocation

- (id)init {
	if (self = [super initWithStyle:UITableViewStylePlain]) {
		
	}
	
	return self;
}

- (void)dealloc {
	[entityDescription release];
	[fetchedResultsController release];
	[managedObjectContext release];
    [super dealloc];
}

#pragma mark -
#pragma mark Abstract methods that subclasses should implement to ensure sane behavior

- (NSString *)managedEntityName {
	return nil;
}

- (NSString *)defaultSortKey {
	return nil;
}

- (NSString *)defaultSectionKey {
	return nil;
}

- (NSString *)defaultCellLabelKey {
	return nil;
}

- (NSString *)defaultCacheName {
	return nil;
}

- (NSString *)inspectorClassName {
	return nil;
}

- (void)createFetchedResultsController {
	if ([self entityDescription]) {		
		NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		[fetchRequest setEntity:[self entityDescription]];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:[self defaultSortKey] ascending:YES];
		[fetchRequest setSortDescriptors:A(sortDescriptor)];
		
		self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:[self defaultCacheName]] autorelease];
	}

	return;
}

#pragma mark -
#pragma mark Accessors

@synthesize managedObjectContext, fetchedResultsController, entityDescription;

- (NSFetchedResultsController *)fetchedResultsController {
	if (!fetchedResultsController) {
		[self createFetchedResultsController];
		[fetchedResultsController setDelegate:self];
	}
	
	return fetchedResultsController;
}

- (NSEntityDescription *)entityDescription {
	if (!entityDescription && self.managedObjectContext && [self managedEntityName]) {
		NSManagedObjectModel *model = [[self.managedObjectContext persistentStoreCoordinator] managedObjectModel];
		entityDescription = [[[model entitiesByName] objectForKey:[self managedEntityName]] retain];
	}
	
	return entityDescription;
}

- (Class)inspectorClass {
	if (!inspectorClass && [self inspectorClassName])
		inspectorClass = NSClassFromString([self inspectorClassName]);
	
	return inspectorClass;
}

#pragma mark -
#pragma mark View loading and unloading

- (void)viewDidLoad {
    [super viewDidLoad];

	if ([self managedEntityName] && [self inspectorClassName] && !self.navigationItem.rightBarButtonItem)
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addEntity:)] autorelease];
}

#pragma mark -
#pragma mark View appearing and disappeaing

- (void)viewWillAppear:(BOOL)animated {
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error])
		[[[UIAlertView alloc] initWithTitle:@"Error Fetching Results" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

#pragma mark -
#pragma mark UITableViewDelegate and UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UITableViewCell *cell = [self cellForManagedObject:managedObject inTableView:tableView];
	
	[self configureCell:cell withManagedObject:managedObject];
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { 
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self inspectorClassName])
		return indexPath;
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController <BPManagedObjectInspectorViewController> *viewController = [[[self inspectorClass] alloc] init];
	[viewController setManagedObjectContext:self.managedObjectContext];
	[viewController setManagedObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
	[self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
		[managedObjectContext deleteObject:object];
		NSError *error = nil;
		if (![managedObjectContext save:&error])
			[[[[UIAlertView alloc] initWithTitle:@"Delete Failed" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
	}
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate implementation

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	
    UITableView *tableView = self.tableView;
	
    switch(type) {
			
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
			if ([tableView cellForRowAtIndexPath:indexPath]) {
				[self configureCell:[tableView cellForRowAtIndexPath:indexPath]
				  withManagedObject:[controller objectAtIndexPath:indexPath]];
				[tableView reloadRowsAtIndexPaths:A(indexPath) withRowAnimation:UITableViewRowAnimationFade];
			}
            break;
			
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark -
#pragma mark Default cell creation 

- (UITableViewCell *)cellForManagedObject:(NSManagedObject *)object inTableView:(UITableView *)tableView {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
	
	return cell;
}

- (void)configureCell:(UITableViewCell *)cell withManagedObject:(NSManagedObject *)object {
	NSString *cellLabelKey = [self defaultCellLabelKey];
	NSAssert(cellLabelKey, @"Must implement -defaultCellLabelKey to use default cell configruation");
	cell.textLabel.text = [object valueForKey:cellLabelKey];
}

#pragma mark -
#pragma mark UI Actions

- (IBAction)addEntity:(id)sender {
	NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:[self managedEntityName] inManagedObjectContext:self.managedObjectContext];
	UIViewController <BPManagedObjectInspectorViewController> *viewController = (UIViewController <BPManagedObjectInspectorViewController> *)[[[self inspectorClass] alloc] init];
	[viewController setManagedObjectContext:self.managedObjectContext];
	[viewController setManagedObject:newObject];
	[viewController setEditing:YES];
	viewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:viewController action:@selector(save:)] autorelease];
	[self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

@end

