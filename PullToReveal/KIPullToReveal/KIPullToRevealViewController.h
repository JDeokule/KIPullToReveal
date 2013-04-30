//
//  PullToRevealViewController.h
//  PullToReveal
//
//  Created by Marcus Kida on 02.11.12.
//  Copyright (c) 2012 Marcus Kida. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "KIPullToRevealCell.h"

typedef enum {
	/** Middle bar is shown using a UITextField. This is the default. */
	KIPullToRevealModeSearch,
	KIPullToRevealModeNone
} KIPullToRevealMode;


@protocol KIPullToRevealDelegate <NSObject>

@optional
- (void) pullToRevealDidSearchFor:(NSString *)searchText;

@end

@interface KIPullToRevealViewController : UITableViewController

@property (nonatomic) KIPullToRevealMode mode;

@property (nonatomic, weak) id <KIPullToRevealDelegate> pullToRevealDelegate;
@property (nonatomic, assign) BOOL centerUserLocation;
@property (nonatomic, retain) MKMapView *mapView;

@property (nonatomic, retain) UIToolbar *toolbar;

@end


