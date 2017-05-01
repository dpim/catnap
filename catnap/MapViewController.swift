//
//  MapViewController.swift
//  catnap
//
//  Created by Dmitry Pimenov on 4/29/17.
//  Copyright © 2017 Dmitry. All rights reserved.
//

import MapKit
import UIKit
import CoreLocation
import UserNotifications

let regionRadius: CLLocationDistance = 500
let degreeDelta: CLLocationDegrees = 0.05

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var location: Location?
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var centerButton: UIButton!
    
    var isSet: Bool?
    var circle: MKCircle?
    var locationManager: CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.mapView.showsCompass = false
        self.mapView.showsUserLocation = true
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        self.view.addGestureRecognizer(longPressGestureRecognizer)
        self.centerButton.isHidden = true
        self.isSet = false
        self.locationManager = CLLocationManager()
        self.locationManager?.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager?.delegate = self
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.locationManager?.startUpdatingLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func didSelectLocation(){
        self.centerButton.isHidden = false;
        self.statusLabel.text = "Alarm set"
        self.actionButton.setTitle("Cancel", for: .normal)
        self.isSet = true
        if let location = self.location {
            //ask for notificaitons
            askForNotifications()
            let region = CLCircularRegion(center: location.coordinate, radius: location.radius, identifier: "destination")
            self.locationManager?.startMonitoring(for: region)
            setNotifications(region: region)
        }
    }
    
    func askForNotifications(){
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound];
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
            }
        }
    }
    
    func setNotifications(region: CLCircularRegion){
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings{ (settings) in
            if settings.authorizationStatus == .authorized {
                self.createNotifications(region: region);
            } else {
                //show error message alert
                let alert = UIAlertController(title: "Couldn't set alarm", message: "We need notifications access to let you know when you're at your destination", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func createNotifications(region: CLCircularRegion){
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Wake up!"
        content.body = "You're at your destination"
        content.sound = UNNotificationSound.default()
        let trigger = UNLocationNotificationTrigger(region:region, repeats:true)
        let delete = UNNotificationAction(identifier: "DeleteAction",
                                                title: "Delete", options: [.destructive])
        let category = UNNotificationCategory(identifier: "actions", actions: [delete], intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
        content.categoryIdentifier = "CatNapCategory"
        let identifier = "CatNapNotification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print(error)
            }
        })
    }
    
    func didCancelLocation(){
        self.centerButton.isHidden = true;
        self.statusLabel.text = "Choose a destination"
        self.actionButton.setTitle("Set", for: .normal)
        self.isSet = false
        self.location = nil
        //cancel notifications
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
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
        didCancelLocation()
        let pressCenter = self.mapView.convert(sender.location(in: self.mapView), toCoordinateFrom: self.mapView)
        self.location = Location(title: "alarm", radius: regionRadius, coordinate: pressCenter)
        //replace overlay
        self.circle = MKCircle(center: pressCenter, radius: regionRadius)
        mapView.add(self.circle!)
        //center
        mapView.setRegion(MKCoordinateRegionMake(pressCenter, MKCoordinateSpanMake(degreeDelta, degreeDelta)), animated: true)
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
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("hurr2")
        if region is CLCircularRegion {
            print("entered")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            print("exited")
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

