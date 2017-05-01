//
//  Location.swift
//  catnap
//
//  Created by Dmitry Pimenov on 4/29/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import Foundation
import MapKit

class Location: NSObject, MKAnnotation {
    let title: String!
    let radius: CLLocationDistance
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, radius: CLLocationDistance, coordinate: CLLocationCoordinate2D){
        self.title = title;
        self.radius = radius;
        self.coordinate = coordinate;
        
        super.init();
    }
}
