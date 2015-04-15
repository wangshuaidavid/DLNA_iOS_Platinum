//
//  MainTableViewController.m
//  DLNA_iOS
//
//  Created by ennrd on 4/15/15.
//  Copyright (c) 2015 ws. All rights reserved.
//

#import "MainTableViewController.h"
#import "UPnPEngine.h"
#import "Macro.h"

@interface MainTableViewController () {
}


@property (weak, nonatomic) IBOutlet UITableViewCell *statusCell;
@property (strong, nonatomic)id statusChangeObserver;
@end

@implementation MainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.statusCell.textLabel.text = @"DMS Server";
}

- (void)viewWillAppear:(BOOL)animated {
    self.statusChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NotificationFlag_StatusChanged object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self setupStatusCellDisplay];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self.statusChangeObserver];
}

- (void)setupStatusCellDisplay {
    if([[UPnPEngine getEngine] isRunning]) {
        self.statusCell.imageView.image = [UIImage imageNamed:@"Up"];
        self.statusCell.detailTextLabel.text = @"Running";
    }else {
        self.statusCell.imageView.image = [UIImage imageNamed:@"Down"];
        self.statusCell.detailTextLabel.text = @"Stoped";
    }
}
@end
