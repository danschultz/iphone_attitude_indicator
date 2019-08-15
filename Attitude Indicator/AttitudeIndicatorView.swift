//
//  AttitudeIndicatorView.swift
//  Attitude Indicator
//
//  Created by Dan Schultz on 6/8/14.
//  Copyright (c) 2014 Dan Schultz. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class AttitudeIndicatorView : UIView {
    let degreeDistance:CGFloat = 5.0
    
    var _pitch:CGFloat = 0.0
    var _roll:CGFloat = 0.0
    
    var _worldLayer:CALayer = CALayer()
    var _worldSize:CGSize = CGSize(width: 1600, height: 1600)
    
    var _miniPlane:CALayer = CALayer()
    var _miniPlaneSize:CGSize = CGSize(width: 220, height: 8)
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        _worldLayer.contents = drawWorldImage(size: _worldSize).cgImage
        _worldLayer.contentsGravity = CALayerContentsGravity.topLeft
        _worldLayer.frame = CGRect(x: 0, y: 0, width: _worldSize.width, height: _worldSize.height)
        layer.addSublayer(_worldLayer)
        
        _miniPlane.contents = drawMiniPlane(size: _miniPlaneSize).cgImage
        _miniPlane.contentsGravity = CALayerContentsGravity.center
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
        let skyColor = UIColor(red: 72.0 / 255.0, green: 121.0 / 255.0, blue: 202.0 / 255.0, alpha: 1.0)
        let groundColor = UIColor(red: 90.0 / 255.0, green: 83.0 / 255.0, blue: 75.0 / 255.0, alpha: 1.0)
        let horizon = size.height / 2
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        
        // Draw the sky
        skyColor.setFill()
        context!.addRect(CGRect(x: 0, y: 0, width: size.width, height: horizon))
        context!.fillPath()
        
        // Draw the ground
        //println(horizon)
        //println(size.height / 2)
        groundColor.setFill()
        context!.addRect(CGRect(x: 0, y: horizon, width: size.width, height: size.height / 2))
        context!.fillPath()
        
        // Draw the horizon line
        context!.setLineWidth(3.0)
        context!.setStrokeColor(UIColor.white.cgColor)
        context!.move(to: CGPoint(x: 0,y: horizon))
        context!.addLine(to: CGPoint(x: size.width, y: horizon))
        context!.strokePath()
        
        // Draw 10 degree marks above the horizon
        context!.setLineWidth(1.0)
        for index in 1...6 {
            let y = horizon - CGFloat(CGFloat(index) * 10.0 * degreeDistance)
            context!.move(to: CGPoint(x: size.width / 2 - 40,y: y))
            context!.addLine(to: CGPoint(x: size.width / 2 + 40, y: y))
            
        }
        
        // Draw 10 degree marks below the horizon
        for index in 1...6 {
            let y = horizon + CGFloat(CGFloat(index) * 10 * degreeDistance)
            context!.move(to: CGPoint(x: size.width / 2 - 40,y: y))
            context!.addLine(to: CGPoint(x: size.width / 2 + 40, y: y))
            
        }
        
        context!.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    func drawMiniPlane(size: CGSize) -> UIImage {
        let wingColor = UIColor(red: 255.0 / 255.0, green: 253.0 / 255.0, blue: 93.0 / 255.0, alpha: 1.0)
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        
        wingColor.setStroke()
        context!.setLineWidth(8)
        
        context!.move(to: CGPoint(x: 0,y: size.height / 2))
        context!.addLine(to: CGPoint(x: size.width / 2 - 45, y: size.height / 2))
        
        context!.move(to: CGPoint(x: size.width / 2 + 45,y: size.height / 2))
        context!.addLine(to: CGPoint(x: size.width, y: size.height / 2))
        
        
        context!.strokePath()
        
        let centerDotArea = CGRect(x: size.width / 2 - 4, y: 0, width: 8, height: 8)
        wingColor.setFill()
        context!.fillEllipse(in: centerDotArea)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    override func draw(_ rect: CGRect) {
        _miniPlane.frame = rect
        
        // Transform the world layer
        let worldCenter = CGPoint(x: rect.width / 2 - _worldSize.width / 2, y: rect.height / 2 - _worldSize.height / 2)
        _ = CGPoint(x: rect.width / 2, y: rect.height / 2 + _pitch * degreeDistance)
        
        var transform = CGAffineTransform(translationX: worldCenter.x, y: worldCenter.y)
        
        transform = transform.rotated(by: CGFloat(_roll / 180.0) * CGFloat.pi)
        transform = transform.translatedBy(x: 0, y: CGFloat(_pitch * degreeDistance))
        
        
        _worldLayer.setAffineTransform(transform)
    }
}
