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
    KIPullToRevealModeMiddleView,
	KIPullToRevealModeNone
} KIPullToRevealMode;


@protocol KIPullToRevealDelegate <NSObject>

@required
- (NSUInteger) numberOfAnnotations;
- (id<MKAnnotation>) annotationForIndex:(NSUInteger)index;

@optional
- (void) pullToRevealDidSearchFor:(NSString *)searchText;
- (void) didSelectAnnotation:(id<MKAnnotation>)annotation;

@end

@interface KIPullToRevealViewController : UITableViewController<MKMapViewDelegate>

@property (nonatomic) KIPullToRevealMode mode;

@property (nonatomic, strong) id <KIPullToRevealDelegate> pullToRevealDelegate;
@property (nonatomic, assign) BOOL centerUserLocation;
@property (nonatomic, retain) MKMapView *mapView;

@property (nonatomic, retain) UIToolbar *toolbar;

@property (nonatomic, retain) UIView *middleView;
@property (nonatomic, retain) UILabel *middleViewLabel;
@property (nonatomic, retain) UIImageView *middleViewImageView;

- (void) zoomMapToFitAnnotations;

@end


