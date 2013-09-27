//
//  PullToRevealViewController.h
//  PullToReveal
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "KIPullToRevealCell.h"

@protocol KIPullToRevealDelegate <NSObject>

@required
- (NSUInteger) numberOfAnnotations;
- (id<MKAnnotation>) annotationForIndex:(NSUInteger)index;

@optional
- (void) didSelectAnnotation:(id<MKAnnotation>)annotation;

@end

@interface KIPullToRevealViewController : UITableViewController<MKMapViewDelegate>


@property (nonatomic, strong) id <KIPullToRevealDelegate> pullToRevealDelegate;
@property (nonatomic, assign) BOOL centerUserLocation;
@property (nonatomic, retain) MKMapView *mapView;

@property (nonatomic, retain) UIView *middleView;
@property (nonatomic, retain) UILabel *middleViewLabel;
@property (nonatomic, retain) UIImageView *middleViewImageView;

@property (nonatomic, readonly) BOOL pinSelectionEnabled;

- (void) zoomMapToFitAnnotations;
- (void) setPinSelection:(BOOL)enabled;

@end


