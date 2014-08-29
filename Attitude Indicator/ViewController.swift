//
//  ViewController.swift
//  Attitude Indicator
//
//  Created by Dan Schultz on 6/8/14.
//  Copyright (c) 2014 Dan Schultz. All rights reserved.
//

import UIKit
import CoreMotion
import GLKit
import QuartzCore

class ViewController: UIViewController {
    let motionManager = CMMotionManager()
    let axisX = 1
    let axisY = 2
    let axisZ = 3
    
    var attitudeIndicatorView: AttitudeIndicatorView {
        get {
            return view as AttitudeIndicatorView;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrameXArbitraryZVertical)
        
        var displayLink = CADisplayLink(target: self, selector: "update:")
        displayLink.frameInterval = 2
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func update(sender: CADisplayLink) {
        var motion = motionManager.deviceMotion
        
        if (motion != nil) {
            var quat = motion.attitude.quaternion
            var roll = radiansToDegrees(asin(2*(quat.x*quat.z - quat.w*quat.y)))
            var pitch = radiansToDegrees(atan2(2*(quat.x*quat.w + quat.y*quat.z), 1 - 2*quat.x*quat.x - 2*quat.z*quat.z)) - 90
            
            var transformedMatrix = remapCoordinateSystem(motion.attitude.rotationMatrix, X: axisX, Y: axisZ)
            var pitch2 = -radiansToDegrees(-asin(transformedMatrix.m32))
            var roll2 = radiansToDegrees(atan2(-transformedMatrix.m31, transformedMatrix.m33))
            
            var pitch3 = radiansToDegrees(atan2(motion.gravity.z, motion.gravity.y) - M_PI)
            var roll3 = radiansToDegrees(atan2(motion.gravity.x, motion.gravity.y) - M_PI)
            
//            println("roll: \(roll3)")
//            println("pitch: \(pitch3)")
            
            attitudeIndicatorView.updateAttitude(pitch2, roll: roll3)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func radiansToDegrees(radians:CDouble) -> CGFloat {
        return CGFloat(radians * (180.0 / M_PI))
    }
    
    func remapCoordinateSystem(rotationMatrix: CMRotationMatrix, X: Int, Y: Int) -> CMRotationMatrix {
        var inR = [rotationMatrix.m11, rotationMatrix.m12, rotationMatrix.m13,
                   rotationMatrix.m21, rotationMatrix.m22, rotationMatrix.m23,
                   rotationMatrix.m31, rotationMatrix.m32, rotationMatrix.m33]
        var outR = CDouble[](count: 9, repeatedValue: 0.0)
        
        // Z is "the other" axis, its sign is either +/- sign(X)*sign(Y)
        // this can be calculated by exclusive-or'ing X and Y; except for
        // the sign inversion (+/-) which is calculated below.
        var Z = X ^ Y;
    
        // extract the axis (remove the sign), offset in the range 0 to 2.
        var x = (X & 0x3)-1;
        var y = (Y & 0x3)-1;
        var z = (Z & 0x3)-1;
    
        // compute the sign of Z (whether it needs to be inverted)
        var axis_y = (z+1)%3;
        var axis_z = (z+2)%3;
        if (((x^axis_y)|(y^axis_z)) != 0) {
            Z ^= 0x80;
        }
    
        var sx = (X>=0x80);
        var sy = (Y>=0x80);
        var sz = (Z>=0x80);
    
        // Perform R * r, in avoiding actual muls and adds.
        var rowLength = 3
        for (var j=0 ; j<3 ; j++) {
            var offset = j*rowLength;
            for (var i=0 ; i<3 ; i++) {
                if (x==i) {
                    outR[offset+i] = sx ? -inR[offset+0] : inR[offset+0]
                }
                
                if (y==i) {
                    outR[offset+i] = sy ? -inR[offset+1] : inR[offset+1]
                }
                
                if (z==i) {
                    outR[offset+i] = sz ? -inR[offset+2] : inR[offset+2]
                }
            }
        }
        
//        println("\(inR[0])\t\t\(inR[1])\t\t\(inR[2])");
//        println("\(inR[3])\t\t\(inR[4])\t\t\(inR[5])");
//        println("\(inR[6])\t\t\(inR[7])\t\t\(inR[8])");
//        println()
        
        return CMRotationMatrix(m11: outR[0], m12: outR[1], m13: outR[2],
                                m21: outR[3], m22: outR[4], m23: outR[5],
                                m31: outR[6], m32: outR[7], m33: outR[8])
    }
}

