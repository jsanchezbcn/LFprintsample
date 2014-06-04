//
//  PRPageRenderer.h
//
//
//  Created by Jose A  Sanchez on 31/07/13.
//  Copyright (c) 2013 Jose A  Sanchez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PRPageRenderer : UIPrintPageRenderer{
       NSURL *_pdfURL;
       CGFloat _scale;
}



- (instancetype)initWithPDFPath:(NSURL*) pdfURL;


@end
