//
//  RoundButton.swift
//  MyRunApp
//
//  Created by Jody Abney on 5/18/20.
//  Copyright © 2020 AbneyAnalytics. All rights reserved.
//

import UIKit

@IBDesignable

class RoundButton: UIButton {

    override  func prepareForInterfaceBuilder() {
        customizeView()
    }
    
    override func awakeFromNib() {
        customizeView()
    }
    
    func customizeView() {
        
        //MARK: - Corner Redius
        self.layer.cornerRadius = self.frame.height / 2
        
        //MARK: - Configure Shadow
        self.layer.shadowRadius = 20
        self.layer.shadowOpacity = 0.5
        self.layer.shadowColor = UIColor.black.cgColor
    }
}
