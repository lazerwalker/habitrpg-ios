//
//  HRPGTableViewController.m
//  HabitRPG
//
//  Created by Phillip Thelen on 08/03/14.
//  Copyright (c) 2014 Phillip Thelen. All rights reserved.
//

#import "HRPGPartyMembersViewController.h"
#import "HRPGInviteMembersViewController.h"
#import "HRPGLabeledProgressBar.h"
#import "HRPGUserProfileViewController.h"
#import "UIColor+Habitica.h"
#import "UIViewController+TutorialSteps.h"
#import "HRPGCoreDataDataSource.h"

@interface HRPGPartyMembersViewController ()
@property NSString *readableName;
@property NSString *typeName;
@property NSIndexPath *openedIndexPath;
@property NSString *sortKey;
@property BOOL sortAscending;
@property HRPGCoreDataDataSource *dataSource;

@end

@implementation HRPGPartyMembersViewController

- (void)viewDidLoad {
    NSString *orderSetting = [self.sharedManager getUser].partyOrder;
    if ([orderSetting isEqualToString:@"level"]) {
        self.sortKey = @"level";
        self.sortAscending = NO;
    } else if ([orderSetting isEqualToString:@"pets"]) {
        self.sortKey = @"petCount";
        self.sortAscending = NO;
    } else if ([orderSetting isEqualToString:@"random"]) {
        self.sortKey = @"username";
        self.sortAscending = YES;
    } else {
        self.sortKey = @"partyPosition";
        self.sortAscending = NO;
    }

    [super viewDidLoad];
    
    [self setupTableView];

    [self setUpInvitationButton];

    [self.sharedManager fetchGroupMembers:[self.sharedManager getUser].partyID withPublicFields:YES fetchAll:YES onSuccess:nil onError:nil];
}

- (void)setupTableView {
    __weak HRPGPartyMembersViewController *weakSelf = self;
    TableViewCellConfigureBlock configureCell = ^(UITableViewCell *cell, User *user, NSIndexPath *indexPath) {
        [weakSelf configureCell:cell withUser:user withAnimation:YES];
    };
    FetchRequestConfigureBlock configureFetchRequest = ^(NSFetchRequest *fetchRequest) {
        NSPredicate *predicate;
        predicate =
        [NSPredicate predicateWithFormat:@"partyID == %@", [weakSelf.sharedManager getUser].partyID];
        [fetchRequest setPredicate:predicate];
        
        NSSortDescriptor *idDescriptor =
        [[NSSortDescriptor alloc] initWithKey:self.sortKey ascending:weakSelf.sortAscending];
        NSArray *sortDescriptors = @[ idDescriptor ];
        [fetchRequest setSortDescriptors:sortDescriptors];
    };
    self.dataSource= [[HRPGCoreDataDataSource alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                       entityName:@"User"
                                                                   cellIdentifier:@"Cell"
                                                               configureCellBlock:configureCell
                                                                fetchRequestBlock:configureFetchRequest
                                                                    asDelegateFor:self.tableView];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (void)configureCell:(UITableViewCell *)cell
          withUser:(User *)user
        withAnimation:(BOOL)animate {
    UILabel *textLabel = [cell viewWithTag:1];
    textLabel.text = user.username;
    UIView *avatarView = (UIView *)[cell viewWithTag:2];
    [user setAvatarSubview:avatarView showsBackground:NO showsMount:NO showsPet:NO];

    HRPGLabeledProgressBar *healthLabel = [cell viewWithTag:3];
    healthLabel.color = [UIColor red100];
    healthLabel.icon = [UIImage imageNamed:@"icon_health"];
    healthLabel.value = user.health;
    healthLabel.maxValue = @50;

    UILabel *levelLabel = [cell viewWithTag:5];
    levelLabel.text = [NSString stringWithFormat:@"LVL %@", user.level];
    UILabel *classLabel = [cell viewWithTag:6];
    classLabel.text = user.hclass;
    [classLabel.layer setCornerRadius:5.0f];
    classLabel.backgroundColor = [user classColor];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"UserProfileSegue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        User *user = [self.dataSource itemAtIndexPath:indexPath];
        HRPGUserProfileViewController *userProfileViewController = segue.destinationViewController;
        userProfileViewController.userID = user.id;
        userProfileViewController.username = user.username;
    }
    [super prepareForSegue:segue sender:sender];
}

- (void)setUpInvitationButton {
    UIBarButtonItem *barButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Invite", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(openInvitationForm)];
    self.navigationItem.rightBarButtonItem = barButton;
}

- (void)openInvitationForm {
    [self performSegueWithIdentifier:@"InvitationSegue" sender:self];
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue {
}

- (IBAction)unwindToListSave:(UIStoryboardSegue *)segue {
    HRPGInviteMembersViewController *formViewController = segue.sourceViewController;
    [self.sharedManager inviteMembers:formViewController.members
        withInvitationType:formViewController.invitationType
        toGroupWithID:self.partyID
                            onSuccess:^() {
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invitation Successful", nil)
                                                                                message:NSLocalizedString(@"The users were invited to your party", nil)
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                                [alert show];
                            } onError:nil];
}

@end
