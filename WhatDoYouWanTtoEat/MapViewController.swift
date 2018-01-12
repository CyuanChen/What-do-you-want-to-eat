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
import SwiftyJSON
import Alamofire

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Int = 1000 // 1 km
    var currentLocation: CLLocationCoordinate2D?
    var restaurantArray: [Restaurant]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationService()
        centerMapOnUserLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()

        
        if #available(iOS 9.0, *) {
            mapView.showsCompass = true
            mapView.showsScale = true
            mapView.showsTraffic = true
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func centerMapButtonWasPressed(_ sender: Any) {
        print(authorizationStatus)
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            print("center")
            centerMapOnUserLocation()
        }
    }
    
    @IBAction func searchNearby(_ sender: Any) {
//        findRestaurantNearby()
       
        findRestaurant(withNextPageToken: nil)
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
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.currentLocation?.latitude = mapView.centerCoordinate.latitude
        self.currentLocation?.longitude = mapView.centerCoordinate.longitude
        print("Current view center: \(mapView.centerCoordinate)")
    }
    
    func centerMapOnUserLocation() {
        guard let location = locationManager.location?.coordinate else {
            return
        }
        print("Center location: \(location.latitude), \(location.longitude)")
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, Double(regionRadius * 2), Double(regionRadius * 2))


        // Change current view region
        mapView.setRegion(coordinateRegion, animated: true)
    }
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print(manager.location?.coordinate as Any)
        print("monitor: \(region)")
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationValue: CLLocationCoordinate2D = (manager.location?.coordinate)!
        self.currentLocation = locationValue
        print("Current location\(String(describing: self.currentLocation))")
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    func retriveUrls(forLocation location: CLLocationCoordinate2D, withRadius radius: Double, andSearchType: String) {
        
    }
    
    func findRestaurant(withNextPageToken token: String?) {
        let mapUrl: String = DataService.instance.getGoogleMapUrl(searchLocation: currentLocation, searchRadius: regionRadius, searchType: "restaurant")
        print(mapUrl)
        
        if token != nil{
            Alamofire.request(DataService.instance.getGoogleMapUrlWithPageToken(pageToken: token!)).responseJSON(completionHandler: { (response) in
                if response.result.isSuccess {
                    let json: JSON = JSON(data: response.data!)
                    print("PAGEEEE TOKEEN\(json["next_page_token"].string)")
                    if let nextPageToken = json["next_page_token"].string {
                        
                        self.findRestaurant(withNextPageToken: nextPageToken)
                    } else {
                        print("Response token error \(String(describing: response.error))")
                    }
                    if let result = json["results"].array {
                        
                        for data in result {
                            //                        var restaurant: Restaurant?
                            let name = data["name"].string
                            let latitude = data["geometry"]["location"]["latitude"].double
                            let longtitude = data["geometry"]["location"]["longtitude"].double
                            let openNow = data["opening_hours"]["open_now"].bool
                            let photoRef = data["photos"]["photo_reference"].string
                            let placeID = data["place_id"].string
                            let rating = data["rating"].double
                            let vicinity = data["vicinity"].string
                            let restaurant = Restaurant(name: name, latitude: latitude, longtitude: longtitude, openNow: openNow, photoRef: photoRef, placeID: placeID, rating: rating, vicinity: vicinity)
                            print("Restaurant \(restaurant.name)")
                            print(data["name"].string)
                        }
                    }
                } else {
                    print("error: \(String(describing: response.error))")
                }
            })
        } else {
            Alamofire.request(DataService.instance.getGoogleMapUrl(searchLocation: currentLocation, searchRadius: regionRadius, searchType: "restaurant")).responseJSON { (response) in
                if response.result.isSuccess {
                    let json: JSON = JSON(data: response.data!)
                    print("PAGGGE\(json["next_page_token"])")
                    print(json)
                    if let nextPageToken = json["next_page_token"].string {
                        self.findRestaurant(withNextPageToken: nextPageToken)
                    } else {
                        print("Response token error \(String(describing: response.error))")
                    }
                    if let result = json["results"].array {
                        
                        for data in result {
                            //                        var restaurant: Restaurant?
                            let name = data["name"].string
                            let latitude = data["geometry"]["location"]["latitude"].double
                            let longtitude = data["geometry"]["location"]["longtitude"].double
                            let openNow = data["opening_hours"]["open_now"].bool
                            let photoRef = data["photos"]["photo_reference"].string
                            let placeID = data["place_id"].string
                            let rating = data["rating"].double
                            let vicinity = data["vicinity"].string
                            let restaurant = Restaurant(name: name, latitude: latitude, longtitude: longtitude, openNow: openNow, photoRef: photoRef, placeID: placeID, rating: rating, vicinity: vicinity)
                            print("Restaurant \(String(describing: restaurant.name))")
                            print(data["name"].string as Any)
                        }
                    }
                } else {
                    print("error: \(String(describing: response.error))")
                }
            }
            
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
            request.region = MKCoordinateRegionMakeWithDistance(location, Double(regionRadius * 2), Double(regionRadius * 2))
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
                    let coordinateRegion = MKCoordinateRegionMakeWithDistance(locationCenter, Double(self.regionRadius * 2), Double(self.regionRadius * 2))
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
            print("configure location")
            return
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}




//    func searchNearrrr() {
//        removePin()
//        let searchRequest = MKLocalSearchRequest()
//        searchRequest.naturalLanguageQuery = "餐廳"
//        searchRequest.region = mapView.region
//        print("\(mapView.region) mapView region")
//        print("\(mapView.region.center) center")
//
//        let localSearch = MKLocalSearch(request: searchRequest)
//        localSearch.start { (response, error) -> Void in
//            guard let response = response else {
//                if let error = error {
//                    print(error)
//                }
//
//                return
//            }
//
//            let mapItems = response.mapItems
//            var nearbyAnnotations: [MKAnnotation] = []
//            if mapItems.count > 0 {
//                for item in mapItems {
//                    // Add annotation
//                    let annotation = MKPointAnnotation()
//                    annotation.title = item.name
//                    annotation.subtitle = item.placemark.title
//                    print(item.name)
//                    if let location = item.placemark.location {
//                        annotation.coordinate = location.coordinate
//                    }
//                    nearbyAnnotations.append(annotation)
//                }
//            }
//
//            self.mapView.showAnnotations(nearbyAnnotations, animated: true)
//        }
//    }












