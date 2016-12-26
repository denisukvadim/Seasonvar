//
//  DetailsSerialViewController.h
//  SerialPLayer
//
//  Created by Vadim Denisuk on 15.08.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentManager.h"
#import "DetailsSerialModel.h"

@interface DetailsSerialViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>{
    UICollectionView *_collectionView;
    UIView* loadingView;
} 
-(void) serialDetails:(NSString *)serialID serialLink:(NSString *)link;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollerView;
@property (strong, nonatomic) IBOutlet UILabel *NameSerial;

@end
