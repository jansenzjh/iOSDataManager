//
//  DataManager.m
//  WarbyParker
//
//  Created by Philip Hayes on 2/20/12.
//  Copyright (c) 2012 happyMedium
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
#import "DataManager.h"

@implementation DataManager

@synthesize delegate;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
static DataManager* dataManager;
int districtNumber = 0;

NSManagedObjectContext *backgroundContext;
NSMutableDictionary * imageCache;

+(DataManager*)SharedDataManager{
    @synchronized(self){
        if (dataManager == nil) {
            dataManager = [[super allocWithZone:NULL]init];
            
        } else {
            //something
        }
    }
    
    return dataManager;
}

-(void)saveBackgroundContext{
    self.managedObjectContext = backgroundContext;
}

-(id)init{
    
    if((self = [super init])){
        
        
    }
    
    return self;
}


#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    
    
    return __fetchedResultsController;    
    
}

#pragma mark - Fetched Results Controller helper ---------
#pragma mark ---------------------------------------------
#pragma mark ---------------------------------------------

/* wrappers for initializing fetchedResultsController, performing fetch, and returning results */

-(NSArray *) getResultsWithEntity:(NSString*)entity sortDescriptor:(NSString*)sortDesc batchSize:(int)batchSize
{
    NSError * error;
    
	[[self fetchedResultsControllerWithEntity:entity sortDescriptor:sortDesc batchSize:batchSize] performFetch:&error];
    if(error)
    {
		NSLog(@"Error fetching: %@", error);
        return nil;
    }
    
    return [[self fetchedResultsController]fetchedObjects];
}


-(NSArray *) getResultsWithEntity:(NSString*)entity sortDescriptor:(NSString*)sortDesc sortPredicate:(NSPredicate*)sortPredicate batchSize:(int)batchSize
{
    NSError * error;
    [[self fetchedResultsControllerWithEntity:entity sortDescriptor:sortDesc sortPredicate:sortPredicate batchSize:batchSize] performFetch:&error];
    if(error)
    {
        NSLog(@"Error fetching: %@", error);
        return nil;
    }
    
    return [[self fetchedResultsController]fetchedObjects];
}

-(NSFetchedResultsController*) fetchedResultsControllerWithEntity:(NSString*)entity sortDescriptor:(NSString*)sortDesc batchSize:(int)batchSize{

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription 
                                              entityForName:entity inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entityDescription];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] 
                              initWithKey:sortDesc ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetchRequest setFetchBatchSize:batchSize];
    
    NSFetchedResultsController *theFetchedResultsController = 
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
                                        managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil 
                                                   cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;
    __fetchedResultsController.delegate = self;
    
    
    
    
    return __fetchedResultsController;   
}

-(NSFetchedResultsController*)fetchedResultsControllerWithEntity:(NSString*)entity sortDescriptor:(NSString*)sortDesc sortPredicate:(NSPredicate*)sortPredicate batchSize:(int)batchSize{

    if (__fetchedResultsController != nil && entity == __fetchedResultsController.fetchRequest.entityName) {
        return __fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDescription = [NSEntityDescription 
                                              entityForName:entity inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setPredicate:sortPredicate];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:sortDesc ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetchRequest setFetchBatchSize:batchSize];
    
    NSFetchedResultsController *theFetchedResultsController = 
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
                                        managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil 
                                                   cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;
    __fetchedResultsController.delegate = self;
    
    return __fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
   
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = nil;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.delegate configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            // Reloading the section inserts a new row and ensures that titles are updated appropriately.
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    
}

-(void)update{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    } else {
        
    }
}


#pragma  mark - NSUserDefaults methods

/* see Notes file for info on what NSUserDefaults keys the app uses */

-(id)defaultUserObjectForKey:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];  
	return [defaults objectForKey:key];
}

-(void)setDefaultUserObject:(id)obj forKey:(NSString *)key
{
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];  
     [defaults setObject:obj forKey:key];
     [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Document Saving methods

-(NSString *)saveImageToDevice:(UIImage *)image withName:(NSString *)imageName extension:(NSString *)ext
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * fileName = [NSString stringWithFormat:@"%@.%@",imageName, [ext lowercaseString]];
    NSString *localFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSError * error;
    if ([[ext lowercaseString] isEqualToString:@"png"]) 
    {
        [UIImagePNGRepresentation(image) writeToFile:localFilePath options:NSAtomicWrite error:&error];
    }
    else if ([[ext lowercaseString] isEqualToString:@"jpg"] || [[ext lowercaseString] isEqualToString:@"jpeg"]) 
    {
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:localFilePath options:NSAtomicWrite error:&error];
    }
    else 
    {
        NSLog(@"Image Save Failed\nExtension: (%@) is not recognized, use (PNG/JPG)", ext);
        return [NSString stringWithFormat:@""];
    }
    if(error)
    {
        NSLog(@"error saving image: %@", error);
    }
    
    return fileName;
}

-(BOOL) removeFile:(NSString *)fileName
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *localFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSError * error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL didDelete = [fileManager removeItemAtPath:localFilePath error:&error];
    if(error)
    {
        NSLog(@"   error removing file: %@", error);
    }
    
    if(didDelete && imageCache && [imageCache objectForKey:fileName])
    {
        [imageCache removeObjectForKey:fileName];
    }
    return didDelete;
    
}


-(UIImage *) loadImageNamed:(NSString *)imageName
{    
    if(imageCache == nil)
    {
        imageCache = [NSMutableDictionary dictionary];
    }
    
    UIImage * result = [imageCache objectForKey:imageName];
    
    if(result == nil)
    {		
        result = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], imageName]];
        
        if(result == nil)
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *localFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",imageName]];
            result = [UIImage imageWithContentsOfFile:localFilePath];
        }
        
        if(result != nil)
        {
            [imageCache setObject:result forKey:imageName];
        }
    }
    return result;
}

-(void) clearImageCache
{
    if(imageCache != nil)
    {
        [imageCache removeAllObjects];
    }
}

#pragma mark - Load view from Nib

-(UIView *) loadViewFromNib:(NSString *) nibName andOwner:(id) owner
{
    NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:nibName owner:owner options:nil];
    return [nibObjects objectAtIndex:0];
}

@end

