//
//  UIVIew+takeScreenShot.swift
//  MyRunApp
//
//  Created by Jody Abney on 5/28/20.
//  Copyright © 2020 AbneyAnalytics. All rights reserved.
//

import UIKit

//MARK: - UIView Extension to create a screenshot

extension UIView {
    
    func takeScreenshot() -> UIImage? {
        
        //begin
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        
        // draw view in that context.
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        // get iamge
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
        
    }
    
}
