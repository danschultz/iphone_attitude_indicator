//
//  AttitudeIndicatorView.swift
//  Attitude Indicator
//
//  Created by Dan Schultz on 6/8/14.
//  Copyright (c) 2014 Dan Schultz. All rights reserved.
//

import Foundation
import UiKit
import QuartzCore

class AttitudeIndicatorView : UIView {
    let degreeDistance:CGFloat = 5.0
    
    var _pitch:CGFloat = 0.0
    var _roll:CGFloat = 0.0
    
    var _worldLayer:CALayer = CALayer()
    var _worldSize:CGSize = CGSizeMake(1600, 1600)
    
    var _miniPlane:CALayer = CALayer()
    var _miniPlaneSize:CGSize = CGSizeMake(220, 8)
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        
        _worldLayer.contents = drawWorldImage(_worldSize).CGImage
        _worldLayer.contentsGravity = kCAGravityTopLeft
        _worldLayer.frame = CGRectMake(0, 0, _worldSize.width, _worldSize.height)
        layer.addSublayer(_worldLayer)
        
        _miniPlane.contents = drawMiniPlane(_miniPlaneSize).CGImage
        _miniPlane.contentsGravity = kCAGravityCenter
        layer.addSublayer(_miniPlane)
    }
    
    func updateAttitude(pitch: CGFloat, roll: CGFloat) {
        _pitch = pitch
        _roll = roll
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        setNeedsDisplay()
        CATransaction.commit()
    }
    
    func drawWorldImage(size: CGSize) -> UIImage {
        var skyColor = UIColor(red: 72.0 / 255.0, green: 121.0 / 255.0, blue: 202.0 / 255.0, alpha: 1.0)
        var groundColor = UIColor(red: 90.0 / 255.0, green: 83.0 / 255.0, blue: 75.0 / 255.0, alpha: 1.0)
        var horizon = size.height / 2
        
        UIGraphicsBeginImageContext(size)
        var context = UIGraphicsGetCurrentContext()
        
        // Draw the sky
        skyColor.setFill()
        CGContextAddRect(context, CGRectMake(0, 0, size.width, horizon))
        CGContextFillPath(context)
        
        // Draw the ground
        println(horizon)
        println(size.height / 2)
        groundColor.setFill()
        CGContextAddRect(context, CGRectMake(0, horizon, size.width, size.height / 2))
        CGContextFillPath(context)
        
        // Draw the horizon line
        CGContextSetLineWidth(context, 3.0)
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextMoveToPoint(context, 0, horizon)
        CGContextAddLineToPoint(context, size.width, horizon)
        CGContextStrokePath(context)
        
        // Draw 10 degree marks above the horizon
        CGContextSetLineWidth(context, 1.0)
        for index in 1...6 {
            var y = horizon - CGFloat(CGFloat(index) * 10.0 * degreeDistance)
            CGContextMoveToPoint(context, size.width / 2 - 40, y)
            CGContextAddLineToPoint(context, size.width / 2 + 40, y)
        }
        
        // Draw 10 degree marks below the horizon
        for index in 1...6 {
            var y = horizon + CGFloat(CGFloat(index) * 10 * degreeDistance)
            CGContextMoveToPoint(context, size.width / 2 - 40, y)
            CGContextAddLineToPoint(context, size.width / 2 + 40, y)
        }
        
        CGContextStrokePath(context)
        
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func drawMiniPlane(size: CGSize) -> UIImage {
        var wingColor = UIColor(red: 255.0 / 255.0, green: 253.0 / 255.0, blue: 93.0 / 255.0, alpha: 1.0)
        
        UIGraphicsBeginImageContext(size)
        var context = UIGraphicsGetCurrentContext()
        
        wingColor.setStroke()
        CGContextSetLineWidth(context, 8)
        
        CGContextMoveToPoint(context, 0, size.height / 2)
        CGContextAddLineToPoint(context, size.width / 2 - 45, size.height / 2)
        
        CGContextMoveToPoint(context, size.width / 2 + 45, size.height / 2)
        CGContextAddLineToPoint(context, size.width, size.height / 2)
        
        CGContextStrokePath(context)
        
        var centerDotArea = CGRectMake(size.width / 2 - 4, 0, 8, 8)
        wingColor.setFill()
        CGContextFillEllipseInRect(context, centerDotArea)
        
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    override func drawRect(rect: CGRect) {
        _miniPlane.frame = rect
        
        // Transform the world layer
        var worldCenter = CGPointMake(rect.width / 2 - _worldSize.width / 2, rect.height / 2 - _worldSize.height / 2)
        var worldOffset = CGPointMake(rect.width / 2, rect.height / 2 + _pitch * degreeDistance)
        
        var transform = CGAffineTransformMakeTranslation(worldCenter.x, worldCenter.y)
        transform = CGAffineTransformRotate(transform, _roll / 180.0 * CGFloat(M_PI))
        transform = CGAffineTransformTranslate(transform, 0, _pitch * degreeDistance)
        
        _worldLayer.setAffineTransform(transform)
    }
}
