//
//  MKAnnptationView.swift
//  New - 37. MKMapView Part 1
//
//  Created by Oleksandr Bardashevskyi on 3/4/19.
//  Copyright © 2019 Oleksandr Bardashevskyi. All rights reserved.
//

import Foundation
import UIKit
import MapKit

extension UIView {
    func superAnnotationView() -> MKAnnotationView? { //рекурсивный метод который ищет анотейшн вью по всем родителям
        
        if self.superview is MKAnnotationView {
            return self.superview as? MKAnnotationView
        }
        if self.superview == nil {
            return nil
        }
        
        return self.superview?.superAnnotationView()
    }
}
