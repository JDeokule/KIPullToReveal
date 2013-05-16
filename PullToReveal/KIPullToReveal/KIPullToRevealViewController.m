//
//  PullToRevealViewController.m
//  PullToReveal
//
//  Created by Marcus Kida on 02.11.12.
//  Copyright (c) 2012 Marcus Kida. All rights reserved.
//

#define kKIPTRTableViewContentInsetX     200.0f
#define kKIPTRAnimationDuration          0.5f

#import "KIPullToRevealViewController.h"

@interface KIPullToRevealViewController () <UIScrollViewDelegate, UITextFieldDelegate, MKMapViewDelegate>
{
    @private
    UITextField *_searchTextField;
    BOOL _scrollViewIsDraggedDownwards;
    double _lastDragOffset;
    int middleViewHeight;
}
@end

@implementation KIPullToRevealViewController

@synthesize pullToRevealDelegate = _pullToRevealDelegate;
@synthesize centerUserLocation = _centerUserLocation;
@synthesize mapView = _mapView;
@synthesize toolbar = _toolbar;
@synthesize middleView = _middleView;
@synthesize middleViewLabel = _middleViewLabel;
@synthesize mode = _mode;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        middleViewHeight = 30;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self initializeMapView];
    
    if (self.mode == KIPullToRevealModeMiddleView ) {
        middleViewHeight = 30;
        [self initializeView];
    } else {
        middleViewHeight = 44;
        [self initalizeToolbar];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self displayMapViewAnnotationsForTableViewCells];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private methods
- (void) initializeView
{
    if (!self.middleView) {
        self.middleView = [[UIView alloc] initWithFrame:CGRectMake(10, -middleViewHeight, 300, middleViewHeight)];
        _middleView.backgroundColor = [UIColor redColor];
        _middleView.alpha = .9;
        [_middleView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];

        _middleViewLabel = [UILabel new];
        _middleViewLabel.text = @"Happening in New York City";
        [_middleViewLabel sizeToFit];
        [_middleViewLabel setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
        _middleViewLabel.alpha = 1;
        CGPoint o = _middleViewLabel.frame.origin;
        int padding = 2;
        _middleViewLabel.frame = CGRectMake(o.x + padding, o.y + 4, 300 - (2*padding), _middleViewLabel.frame.size.height);
        _middleViewLabel.textAlignment = NSTextAlignmentCenter;
        _middleViewLabel.backgroundColor = [UIColor clearColor];

        [self.middleView addSubview:_middleViewLabel];
        
        [self.tableView insertSubview:self.middleView aboveSubview:self.tableView];
    }
}

- (void) initializeMapView
{
    if (!_mapView) {
        [self.tableView setContentInset:UIEdgeInsetsMake(kKIPTRTableViewContentInsetX,0,0,0)];
        _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, self.tableView.contentInset.top*-1, self.tableView.bounds.size.width, self.tableView.contentInset.top)];
        [_mapView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_mapView setShowsUserLocation:YES];
        [_mapView setUserInteractionEnabled:NO];
        
        if(_centerUserLocation)
        {
            [self centerToUserLocation];
            [self zoomToUserLocation];
        }
        
        _mapView.delegate = self;
        
        [self.tableView insertSubview:_mapView aboveSubview:self.tableView];
    }
}

- (void) initalizeToolbar
{
    if (!_toolbar) {
        _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, -middleViewHeight, self.tableView.bounds.size.width, middleViewHeight)];
        [_toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        if (self.mode == KIPullToRevealModeSearch) {
            _searchTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 7, _toolbar.bounds.size.width-20, 30)];
            [_searchTextField setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
            [_searchTextField setBorderStyle:UITextBorderStyleRoundedRect];
            [_searchTextField setReturnKeyType:UIReturnKeySearch];
            [_searchTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [_searchTextField addTarget:self action:@selector(searchTextFieldBecomeFirstResponder:) forControlEvents:UIControlEventEditingDidBegin];
            [_searchTextField setDelegate:self];
            [_toolbar addSubview:_searchTextField];
        }

        [self.tableView insertSubview:_toolbar aboveSubview:self.tableView];
    }
}

- (void) centerToUserLocation
{
    [_mapView setCenterCoordinate:_mapView.userLocation.coordinate animated:YES];
}

- (void) zoomToUserLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = _mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.2;
    mapRegion.span.longitudeDelta = 0.2;
    [_mapView setRegion:mapRegion animated: YES];
}

#pragma mark - ScrollView Delegate
- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    double contentOffset = scrollView.contentOffset.y;
    _lastDragOffset = contentOffset;

    if(contentOffset < kKIPTRTableViewContentInsetX*-1)
    {
        [self zoomMapToFitAnnotations];
        [_mapView setUserInteractionEnabled:YES];
        
        [UIView animateWithDuration:kKIPTRAnimationDuration
                         animations:^()
         {
             [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.bounds.size.height,0,0,0)];
             [self.tableView scrollsToTop];
         }];
    }
    else if (contentOffset >= kKIPTRTableViewContentInsetX*-1)
    {
        [_mapView setUserInteractionEnabled:NO];
        
        [UIView animateWithDuration:kKIPTRAnimationDuration
                         animations:^()
         {
             [self.tableView setContentInset:UIEdgeInsetsMake(kKIPTRTableViewContentInsetX,0,0,0)];

         }];
        
        if(_centerUserLocation)
        {
            [self centerToUserLocation];
            [self zoomToUserLocation];
        }
        
        [self.tableView scrollsToTop];
    }
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    double contentOffset = scrollView.contentOffset.y;
    
    if (contentOffset < _lastDragOffset)
        _scrollViewIsDraggedDownwards = YES;
    else
        _scrollViewIsDraggedDownwards = NO;

    if (!_scrollViewIsDraggedDownwards)
    {
        [_mapView setFrame:
         CGRectMake(0, self.tableView.contentInset.top*-1, self.tableView.bounds.size.width, self.tableView.contentInset.top)
         ];
        [_mapView setUserInteractionEnabled:NO];

        [self.tableView setContentInset:UIEdgeInsetsMake(kKIPTRTableViewContentInsetX,0,0,0)];
        
        if(_centerUserLocation)
        {
            [self centerToUserLocation];
            [self zoomToUserLocation];
        }
        
        [self.tableView scrollsToTop];
    }

    if(contentOffset >= -middleViewHeight)
    {
        [_toolbar removeFromSuperview];
        [_toolbar setFrame:CGRectMake(0, contentOffset, self.tableView.bounds.size.width, middleViewHeight)];
        [self.tableView addSubview:_toolbar];
    }
    else if(contentOffset < 0)
    {
        [_toolbar removeFromSuperview];
        [_toolbar setFrame:CGRectMake(0, -middleViewHeight, self.tableView.bounds.size.width, middleViewHeight)];
        [self.tableView insertSubview:_toolbar aboveSubview:self.tableView];
        
        // Resize map to viewable size
        [_mapView setFrame:
         CGRectMake(0, self.tableView.bounds.origin.y, self.tableView.bounds.size.width, contentOffset*-1)
         ];
        [self zoomMapToFitAnnotations];
    }
    
    if(_centerUserLocation)
    {
        [self centerToUserLocation];
        [self zoomToUserLocation];
        [self displayMapViewAnnotationsForTableViewCells];
    }
}

#pragma mark - TextField Delegate
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if(_pullToRevealDelegate && [_pullToRevealDelegate respondsToSelector:@selector(PullToRevealDidSearchFor:)])
        [[self pullToRevealDelegate] pullToRevealDidSearchFor:textField.text];
    
    [_searchTextField resignFirstResponder];
    return YES;
}

#pragma mark - SearchTextField
- (void) searchTextFieldBecomeFirstResponder: (id)sender
{
    [UIView animateWithDuration:kKIPTRAnimationDuration
                     animations:^()
     {
         [self.tableView setContentInset:UIEdgeInsetsMake(kKIPTRTableViewContentInsetX+middleViewHeight,0,0,0)];
         [_mapView setFrame:
          CGRectMake(0, self.tableView.contentInset.top*-1, self.tableView.bounds.size.width, self.tableView.contentInset.top)
          ];
         [_mapView setUserInteractionEnabled:NO];
         
         if(_centerUserLocation)
         {
             [self centerToUserLocation];
             [self zoomToUserLocation];
         }
         
         [self.tableView scrollsToTop];
     }];
    [_searchTextField becomeFirstResponder];
}
#pragma mark - MapView
- (void) displayMapViewAnnotationsForTableViewCells
{
    [_mapView removeAnnotations:_mapView.annotations];

    for (int i = 0; i < [self.pullToRevealDelegate numberOfAnnotations]; i++) {
        id<MKAnnotation> annotation = [self.pullToRevealDelegate annotationForIndex:i];
        if (annotation)
            [_mapView addAnnotation:annotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKAnnotationView *pin = [mapView dequeueReusableAnnotationViewWithIdentifier:@"Board Pin"];
    if (!pin) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Board Pin"];
        
        UIButton *disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        pin.rightCalloutAccessoryView = disclosureButton;
        pin.canShowCallout = YES;
    } else {
        pin.annotation = annotation;
    }
    
    return pin;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([_pullToRevealDelegate respondsToSelector:@selector(didSelectAnnotation:)])
        [_pullToRevealDelegate didSelectAnnotation:view.annotation];
}


- (void) zoomMapToFitAnnotations
{
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in _mapView.annotations)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        if (MKMapRectIsNull(zoomRect)) {
            zoomRect = pointRect;
        } else {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }
    [_mapView setVisibleMapRect:zoomRect animated:NO];
}

//- (void) mapViewDidFinishLoadingMap:(MKMapView *)mapView
//{
//    [self displayMapViewAnnotationsForTableViewCells];
//}

@end
