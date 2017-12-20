//
//  MapViewController.swift
//  WhatDoYouWanTtoEat
//
//  Created by PeterChen on 2017/9/4.
//  Copyright © 2017年 PeterChen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationService()
        centerMapOnUserLocation()
        searchNearrrr()
        centerMapOnUserLocation()
        
//        findRestaurantNearby()

        
        if #available(iOS 9.0, *) {
            mapView.showsCompass = true
            mapView.showsScale = true
            mapView.showsTraffic = true
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func centerMapButtonWasPressed(_ sender: Any) {
        print(authorizationStatus)
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            print("cennnter")
            centerMapOnUserLocation()
        }
    }
    
    @IBAction func searchNearby(_ sender: Any) {
        findRestaurantNearby()
//        searchNearrrr()
    }

    

   

}

extension MapViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "My pin"
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView: MKPinAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        }
        return annotationView
    }
    
    func centerMapOnUserLocation() {
        guard let location = locationManager.location?.coordinate else {
            return
        }
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, regionRadius * 2.0, regionRadius * 2.0)


        // Change current view region
        mapView.setRegion(coordinateRegion, animated: true)

        
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print(location.coordinate)
        }
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func searchNearrrr() {
        removePin()
        
        
        
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = "餐廳"
        searchRequest.region = mapView.region
        print("\(mapView.region) mapView region")
        print("\(mapView.region.center) center")
        
        let localSearch = MKLocalSearch(request: searchRequest)
        localSearch.start { (response, error) -> Void in
            guard let response = response else {
                if let error = error {
                    print(error)
                }
                
                return
            }
            
            let mapItems = response.mapItems
            var nearbyAnnotations: [MKAnnotation] = []
            if mapItems.count > 0 {
                for item in mapItems {
                    // Add annotation
                    let annotation = MKPointAnnotation()
                    annotation.title = item.name
                    annotation.subtitle = item.placemark.title
                    print(item.name)
                    if let location = item.placemark.location {
                        annotation.coordinate = location.coordinate
                    }
                    nearbyAnnotations.append(annotation)
                }
            }
            
            self.mapView.showAnnotations(nearbyAnnotations, animated: true)
        }
    }
    
    func findRestaurantNearby() {
        removePin()
        guard (locationManager.location?.coordinate) != nil else {
            return
        }
        let querys: [String] = ["餐廳","咖啡廳", "拉麵", "壽司","素食","速食","日本菜"]
        var nearbyAnnotation: [MKAnnotation] = []
        var queryTimes: Int = 0
        for query in querys {
            let request = MKLocalSearchRequest()
            request.naturalLanguageQuery = query
            guard let location = locationManager.location?.coordinate else {
                return
            }
            request.region = MKCoordinateRegionMakeWithDistance(location, regionRadius * 2.0, regionRadius * 2.0)
//            request.region = mapView.region
            let localSearch = MKLocalSearch(request: request)
            localSearch.start(completionHandler: { (response, error) in
                guard let response = response else {
                    if let error = error {
                        print("Searching Error: \(error)")
                    }
                    return
                }
                let mapItems = response.mapItems
                
                if mapItems.count > 0 {
                    for item in mapItems {
                        print(item)
                        let annotation = MKPointAnnotation()
                        annotation.title = item.placemark.name
                        annotation.subtitle = item.placemark.title
                        if let location = item.placemark.location {
                            annotation.coordinate = location.coordinate
                        }
                        nearbyAnnotation.append(annotation)
                        print("Nearby: \(item.placemark.name!)")
                        print(item)
                    }
                }
                queryTimes+=1
                print(queryTimes)
                print(querys.count)
                if queryTimes == querys.count {
                    self.mapView.showAnnotations(nearbyAnnotation, animated: true)
                    
//                    let coordinateRegion = MKCoordinateRegionMakeWithDistance(, regionRadius * 2.0, regionRadius * 2.0)
                    
                    let locationCenter = self.mapView.region.center
                    let coordinateRegion = MKCoordinateRegionMakeWithDistance(locationCenter, self.regionRadius * 2.0, self.regionRadius * 2.0)
                    // Change current view region
                    self.mapView.setRegion(coordinateRegion, animated: true)
                    
                    
                }
            })
            
        }
        
        
    }

    
    
    
}



extension MapViewController: CLLocationManagerDelegate
{
    func configureLocationService() {
        if authorizationStatus == .notDetermined {
            print("not determined")
            locationManager.requestAlwaysAuthorization()
        } else {
            print("else")
            return
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}











