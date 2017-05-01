//
//  MapViewController.swift
//  catnap
//
//  Created by Dmitry Pimenov on 4/29/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import MapKit
import UIKit
let regionRadius: CLLocationDistance = 500
let degreeDelta: CLLocationDegrees = 0.05

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var location: Location?
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var centerButton: UIButton!
    
    var isSet: Bool?
    var circle: MKCircle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        self.view.addGestureRecognizer(longPressGestureRecognizer)
        self.centerButton.isHidden = true
        self.isSet = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func didSelectLocation(){
        self.centerButton.isHidden = false;
        self.statusLabel.text = "Alarm set"
        self.actionButton.setTitle("Cancel", for: .normal)
        self.isSet = true
    }
    
    func didCancelLocation(){
        self.centerButton.isHidden = true;
        self.statusLabel.text = "Choose a destination"
        self.actionButton.setTitle("Set", for: .normal)
        self.isSet = false
        self.location = nil
        removeCircle()
    }
    
    func removeCircle(){
        if let circle = self.circle {
            self.mapView.remove(circle)
        }
    }
    
    func handleLongPress(sender: UILongPressGestureRecognizer)
    {
        //remove overlay if exists
        removeCircle()
        let pressCenter = self.mapView.convert(sender.location(in: self.mapView), toCoordinateFrom: self.mapView)
        self.location = Location(title: "alarm", radius: regionRadius, coordinate: pressCenter)
        //replace overlay
        self.circle = MKCircle(center: pressCenter, radius: regionRadius)
        mapView.add(self.circle!)
        //center
        mapView.setRegion(MKCoordinateRegionMake(pressCenter, MKCoordinateSpanMake(degreeDelta, degreeDelta)), animated: true)
        //show popup - confirm/favorite
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if self.location != nil {
            if overlay is MKCircle {
                let circle = MKCircle(center: (self.location?.coordinate)!, radius:  (self.location?.radius)!)
                let circleRenderer = MKCircleRenderer(circle: circle)
                circleRenderer.fillColor = UIColor.green
                circleRenderer.alpha = 0.5
                return circleRenderer
            }
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let location = annotation as? Location {
            var view: MKAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView {
                dequeuedView.image = UIImage(named: "second")
                view = dequeuedView
            } else {
                view = MKAnnotationView(annotation: location, reuseIdentifier: "identifier")
                view.canShowCallout = true
                view.image = UIImage(named: "second")
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            }
            return view
        } else {
            return nil
        }
    }
    
    @IBAction func actionButtonPressed(sender: UIButton) {
        if (self.location != nil) {
            if let set = self.isSet {
                if (!set){
                    didSelectLocation()
                } else {
                    didCancelLocation()
                }
            }
        }
    }
    
    @IBAction func centerButtonPressed(sender: UIButton) {
        if let loc = self.location {
            mapView.setRegion(MKCoordinateRegionMake(loc.coordinate,
                                                 MKCoordinateSpanMake(degreeDelta, degreeDelta)), animated: true)
        }
    }
}

