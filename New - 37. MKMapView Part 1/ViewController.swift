//
//  ViewController.swift
//  New - 37. MKMapView Part 1
//
//  Created by Oleksandr Bardashevskyi on 3/4/19.
//  Copyright © 2019 Oleksandr Bardashevskyi. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    var locationManager = CLLocationManager()
    var pinPoint = CGPoint()
    
    var geoCoder = CLGeocoder()
    
    var directions: MKDirections?
    
    @IBOutlet weak var mapView: MKMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestWhenInUseAuthorization()
        
        
        if CLLocationManager.locationServicesEnabled() { //User Location
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(actionAdd))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(actionShowAll))
    }
    
    deinit {
        if geoCoder.isGeocoding {
            geoCoder.cancelGeocode()
        }
        if directions!.isCalculating {
            directions!.cancel()
        }
    }
    
    //MARK: - Actions
    @objc func actionShowAll(_ sender: UIBarButtonItem) {
        
        var zoomRect = MKMapRect.null
        
        for annotation:MKAnnotation in (self.mapView?.annotations)! {
            let location = annotation.coordinate
            let center = MKMapPoint.init(location)
            let delta: Double = 10000
            
            let rect = MKMapRect(x: center.x - delta, y: center.y - delta, width: delta * 2, height: delta * 2) //span
            
            zoomRect = zoomRect.union(rect)
        }
        zoomRect = (self.mapView?.mapRectThatFits(zoomRect))!
        self.mapView?.setVisibleMapRect(zoomRect,
                                        edgePadding: .init(top: 50, left: 50, bottom: 50, right: 50),
                                        animated: true)
    }
    @objc func actionAdd(_ sender: UIBarButtonItem) {
        
        guard let coordinate = self.mapView?.region.center else {
            return
        }
        let annotation = OBMapAnnotation(coordinate: coordinate,
                                         title: "Test Title",
                                         subtitle: "Test Subtitle")
        self.mapView?.addAnnotation(annotation)
        
    }
    @objc func actionDescription(_ sender: UIButton) {
        
        guard let annotationView = sender.superAnnotationView() else {
            return
        }
        
        let coordinate = annotationView.annotation?.coordinate
        let location = CLLocation(latitude: (coordinate?.latitude)!,
                                  longitude: (coordinate?.longitude)!)
        
        //MARK: - Takes adress
        if geoCoder.isGeocoding {
            geoCoder.cancelGeocode()
        }
        
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in //берем данные из локации можно на оборот reverseGeocodeLocation
            var message = ""
            if let letError = error {
                message = letError.localizedDescription
            } else {
                if (placemarks?.count)! > 0 {
                    let placeMark = placemarks!.first!
                    let address = "country: \(placeMark.country ?? "")\nregion: \(placeMark.administrativeArea ?? "")\ntown: \(placeMark.locality ?? "")\nStreet: \(placeMark.name ?? "")"
                    message = address
                } else {
                    message = "No placemarks found"
                }
            }
            self.showAllertWith(title: "Adress:", andMessage: message)
        }
    }
    @objc func actionDirection(_ sender: UIButton) {
        guard let annotationView = sender.superAnnotationView(), let coordinate = annotationView.annotation?.coordinate else {
            return
        }
        if directions != nil {
            if directions!.isCalculating {
                directions!.cancel()
            }
        }
        let placeMark = MKPlacemark(coordinate: coordinate)
        let destination = MKMapItem(placemark: placeMark)
        let request = MKDirections.Request()
        
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .walking
        
        directions = MKDirections(request: request)
        directions!.calculate { (response, error) in
            if let error = error {
                self.showAllertWith(title: "Error", andMessage: error.localizedDescription)
            } else if response?.routes.count == 0 {
                self.showAllertWith(title: "Error", andMessage: "No routs found")
            } else {
                self.mapView?.removeOverlays((self.mapView?.overlays)!)
                var array = [MKPolyline]()
                
                for route in (response?.routes)! {
                    array.append(route.polyline)
                }
                self.mapView?.addOverlays(array, level: MKOverlayLevel.aboveRoads)
            }
            
        }
    }
    //MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.pinPoint = (touches.first?.location(in: mapView))!
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        
        if self.pinPoint == touch.location(in: mapView) {
            guard let coordinate = self.mapView?.convert(self.pinPoint, toCoordinateFrom: self.mapView) else {
                return
            }
            let annotation = OBMapAnnotation(coordinate: coordinate,
                                             title: "Test Title",
                                             subtitle: "Test Subtitle")
            self.mapView?.addAnnotation(annotation)
        }
        
        
    }
    //MARK: - Alert
    func showAllertWith(title: String, andMessage: String) {
        let alert = UIAlertController(title: title, message: andMessage, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}
//MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //user location
        let locValue: CLLocationCoordinate2D = (manager.location?.coordinate)!
        print("location = \(locValue.latitude), \(locValue.longitude)")
        let userLocation = locations.last
        let viewRedion = MKCoordinateRegion.init(center: (userLocation?.coordinate)!, latitudinalMeters: 600, longitudinalMeters: 600)
        self.mapView?.setRegion(viewRedion, animated: true)
    }
}


//MARK: - MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? { //создает свою вью по анотации
        if annotation is MKUserLocation {
            return nil //меп вью сам заботится, что бы показать синенькую штучку
        }
        let identifier = "Annotation"
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        
        if pin == nil {
            pin = MKPinAnnotationView.init(annotation: annotation, reuseIdentifier: identifier)
            pin?.tintColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
            pin?.animatesDrop = true
            pin?.canShowCallout = true
            pin?.isDraggable = true
            
            let descriptionButton = UIButton(type: .detailDisclosure)
            descriptionButton.addTarget(self, action: #selector(actionDescription), for: .touchUpInside)
            pin?.rightCalloutAccessoryView = descriptionButton
            
            let directionButton = UIButton(type: .contactAdd)
            directionButton.addTarget(self, action: #selector(actionDirection), for: .touchUpInside)
            pin?.leftCalloutAccessoryView = directionButton
            
        } else {
            pin?.annotation = annotation
        }
        
        return pin
    }
    
    //MARK: - Dragging Pin
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        
        if newState == MKAnnotationView.DragState.ending {
            let location = view.annotation?.coordinate
            let point = MKMapPoint.init(location!)
            print("longitude = \(point.coordinate.longitude), latitude = \(point.coordinate.latitude)")
        }
        
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 2
        renderer.strokeColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        return renderer
        
    }
    

//    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
//        print("regionWillChangeAnimated")
//    }
//    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//        print("regionDidChangeAnimated")
//    }
//    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
//        print("mapViewWillStartLoadingMap")
//    }
//    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
//        print("mapViewDidFinishLoadingMap")
//    }
//    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
//        print("mapViewDidFailLoadingMap")
//    }
//    func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
//        print("mapViewWillStartRenderingMap")
//    }
//    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
//        print("mapViewDidFinishRenderingMap")
//    }
}
