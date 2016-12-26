//
//  NewsSerialCollectionViewCell.h
//  SerialPLayer
//
//  Created by Vadim Denisuk on 15.08.16.
//  Copyright © 2016 Vadim Denisuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsSerialCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UIImageView *posterNewsSerial;
@property (strong, nonatomic) IBOutlet UILabel *SerialName;
@property (strong, nonatomic) IBOutlet UIView *bgBackgroundWhiteView;
@property (strong, nonatomic) IBOutlet UILabel *pubDate;
@property (strong, nonatomic) IBOutlet UIButton *favoritButton;
@property (strong, nonatomic) IBOutlet UIButton *downloadStatus;

@end
