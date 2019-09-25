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
            return view as! AttitudeIndicatorView;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager.startDeviceMotionUpdates()
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update(sender: )))
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: RunLoop.current, forMode: RunLoop.Mode.default)
    }
    
    @objc func update(sender: CADisplayLink) {
        
        if let motion = motionManager.deviceMotion {
            _ = motion.attitude.quaternion
            _ = radiansToDegrees(radians: motion.attitude.roll)
            _ = radiansToDegrees(radians: motion.attitude.pitch) - 90
            
            let transformedMatrix = remapCoordinateSystem(rotationMatrix: motion.attitude.rotationMatrix, X: axisX, Y: axisZ)
            let pitch2 = -radiansToDegrees(radians: -asin(transformedMatrix.m32))
            _ = radiansToDegrees(radians: atan2(-transformedMatrix.m31, transformedMatrix.m33))
            
            _ = radiansToDegrees(radians: atan2(motion.gravity.z, motion.gravity.y) - .pi)
            let roll3 = radiansToDegrees(radians: atan2(motion.gravity.x, motion.gravity.y) - .pi)
            
            attitudeIndicatorView.updateAttitude(pitch: pitch2, roll: roll3)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func radiansToDegrees(radians:CDouble) -> CGFloat {
        return CGFloat(radians * (180.0 / .pi))
    }
    
    func remapCoordinateSystem(rotationMatrix: CMRotationMatrix, X: Int, Y: Int) -> CMRotationMatrix {
        var inR = [rotationMatrix.m11, rotationMatrix.m12, rotationMatrix.m13,
                   rotationMatrix.m21, rotationMatrix.m22, rotationMatrix.m23,
                   rotationMatrix.m31, rotationMatrix.m32, rotationMatrix.m33]
        var outR: [Double] = [0,0,0,0,0,0,0,0,0]
        
        // Z is "the other" axis, its sign is either +/- sign(X)*sign(Y)
        // this can be calculated by exclusive-or'ing X and Y; except for
        // the sign inversion (+/-) which is calculated below.
        var Z = X ^ Y;
        
        // extract the axis (remove the sign), offset in the range 0 to 2.
        let x = (X & 0x3)-1;
        let y = (Y & 0x3)-1;
        let z = (Z & 0x3)-1;
        
        // compute the sign of Z (whether it needs to be inverted)
        let axis_y = (z+1)%3;
        let axis_z = (z+2)%3;
        if (((x^axis_y)|(y^axis_z)) != 0) {
            Z ^= 0x80;
        }
        
        let sx = (X>=0x80);
        let sy = (Y>=0x80);
        let sz = (Z>=0x80);
        
        // Perform R * r, in avoiding actual muls and adds.
        let rowLength = 3
        for j in 0...2 {
            let offset = j*rowLength
            for i in 0...2 {
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

