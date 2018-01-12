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
    var restaurantArray: [Restaurant]? = []
    var nextPageCount: Int = 0
    
    
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
//        findRestaurant()
//        DispatchQueue.main.sync {
            findRestaurant()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4.0) {
            self.pinRestaurant()
        }
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
    
    func nextPageRestaurant(withToken token: String) {
        print("Next Page")
        let nextPageToken = DataService.instance.getGoogleMapUrlWithPageToken(pageToken: token)
//        print(" ha next page token: \(nextPageToken)")
        Alamofire.request(nextPageToken).responseJSON(completionHandler: { (response) in
            if response.result.isSuccess {
                print("Response status: \(JSON(response.data!)["status"])")
                let json: JSON = JSON(data: response.data!)
                if json["status"].string != "OK" {
                    if self.nextPageCount > 5 {
                        print("Status is not OK, but finish.")
                    } else {
                        print("Status is not OK, try again")
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                            self.nextPageRestaurant(withToken: token)
                            self.nextPageCount += 1
                        })
                        
                    }
                } else {
                    print("Status OK")
                    if let nextPageToken = json.dictionaryValue["next_page_token"]?.string {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                            self.nextPageRestaurant(withToken: nextPageToken)
                        })
                        
                    } else {
                        print("Response token error \(String(describing: response.error))")
                    }
                    if let result = json["results"].array {
                        for data in result {
                            let name = data["name"].string
                            let latitude = data["geometry"]["location"]["lat"].double ?? 0
                            let longitude = data["geometry"]["location"]["lng"].double ?? 0
                            let openNow = data["opening_hours"]["open_now"].bool
                            let photoRef = data["photos"]["photo_reference"].string
                            let placeID = data["place_id"].string
                            let rating = data["rating"].double
                            let vicinity = data["vicinity"].string
                            let restaurant = Restaurant(name: name, latitude: latitude, longitude: longitude, openNow: openNow, photoRef: photoRef, placeID: placeID, rating: rating, vicinity: vicinity)
                            self.restaurantArray?.append(restaurant)
                            print("Restaurant Array: \(self.restaurantArray)")
                        }
                    } else {
                    print("Alamofire Error: \(String(describing: response.error))")
                    }
                print("Alamorire finish")
                }
            }
        })
    }
    
    func findRestaurant() {
        // clean the restaurant list
        self.restaurantArray?.removeAll()
        nextPageCount = 0
        
        let mapUrl: String = DataService.instance.getGoogleMapUrl(searchLocation: currentLocation, searchRadius: regionRadius, searchType: "restaurant")
        print(mapUrl)
        print("first page")
        Alamofire.request(DataService.instance.getGoogleMapUrl(searchLocation: currentLocation, searchRadius: regionRadius, searchType: "restaurant")).responseJSON { (response) in
            if response.result.isSuccess {
                let json: JSON = JSON(data: response.data!)
                if let nextPageToken = json.dictionaryValue["next_page_token"]?.string {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                        self.nextPageRestaurant(withToken: nextPageToken)
                    })
                } else {
                    print("Response token error \(String(describing: response.error))")
                }
                if let result = json["results"].array {
                    
                    for data in result {
                        let name = data["name"].string
                        let latitude = data["geometry"]["location"]["lat"].double! ?? 0
                        let longitude = data["geometry"]["location"]["lng"].double ?? 0
                        let openNow = data["opening_hours"]["open_now"].bool
                        let photoRef = data["photos"]["photo_reference"].string
                        let placeID = data["place_id"].string
                        let rating = data["rating"].double
                        let vicinity = data["vicinity"].string
                        let restaurant = Restaurant(name: name, latitude: latitude, longitude: longitude, openNow: openNow, photoRef: photoRef, placeID: placeID, rating: rating, vicinity: vicinity)
                        DispatchQueue.main.async {
                            print("Res:\(restaurant.name)")
                            self.restaurantArray?.append(restaurant)
                            print("Arr: \(self.restaurantArray?.count)")
                        }
                        print("Restaurant \(restaurant.name!)")
                    }
                }
            } else {
                print("Alamofire Error: \(String(describing: response.error))")
            }
        }
    }
    func pinRestaurant() {
        removePin()
        print("pinnnnn")
        if restaurantArray != nil {
            print("restaurant not nil")
            var nearbyAnnotation: [MKAnnotation] = []
            if let resArr = restaurantArray {
                print("Unwrap res")
                for item in resArr {
                    let annotation = MKPointAnnotation()
                    annotation.title = item.name
                    print("Item name \(item.name)")
                    annotation.subtitle = "Opening: \(item.openNow!)"
                    print("Lat: \(item.latitude), Long:\(item.longitude)")
                    annotation.coordinate.latitude = item.latitude!
                    annotation.coordinate.longitude = item.longitude!
                    nearbyAnnotation.append(annotation)
                }
                self.mapView.showAnnotations(nearbyAnnotation, animated: true)
            } else {
                print("Restaurant problem")
            }
            
            
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                self.pinRestaurant()
            })
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



