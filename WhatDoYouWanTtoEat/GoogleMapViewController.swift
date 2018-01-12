//
//  GoogleMapViewController.swift
//  WhatDoYouWanTtoEat
//
//  Created by PeterChen on 2018/1/2.
//  Copyright © 2018年 PeterChen. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps

class GoogleMapViewController: UIViewController {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []
    // The currently selected place.
    var selectedPlace: GMSPlace?
    var defaultLocation: CLLocation = CLLocation(latitude: 25.03746, longitude: 121.564558)

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        mapView.isHidden = true

        
//        let placeID = "ChIJV4k8_9UodTERU5KXbkYpSYs"
//
//        placesClient.lookUpPlaceID(placeID, callback: { (place, error) -> Void in
//            if let error = error {
//                print("lookup place id query error: \(error.localizedDescription)")
//                return
//            }
//
//            guard let place = place else {
//                print("No place details for \(placeID)")
//                return
//            }
//
//            print("Place name \(place.name)")
//            print("Place address \(place.formattedAddress)")
//            print("Place placeID \(place.placeID)")
//            print("Place attributions \(place.attributions)")
//        })
        
        placeAutocomplete()
    }
    func placeAutocomplete() {
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        placesClient.autocompleteQuery("Sydney Oper", bounds: nil, filter: filter, callback: {(results, error) -> Void in
            if let error = error {
                print("Autocomplete error \(error)")
                return
            }
            if let results = results {
                for result in results {
                    print("Result \(result.attributedFullText) with placeID \(result.placeID)")
                }
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension GoogleMapViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
        listLikelyPlaces()
    }
    // Populate the array with the list of likely places.
    func listLikelyPlaces() {
        // Clean up from previous sessions.
        print("Run list likely places")
        likelyPlaces.removeAll()
        placesClient.currentPlace { (placeLikelihoods, error) in
            if let error = error {
                print("Current place error \(error.localizedDescription)")
                return
            }
            // Get likely places and add to the list.
            if let likelihoodList = placeLikelihoods {
                for likelihood in likelihoodList.likelihoods {
                    let place = likelihood.place
                    self.likelyPlaces.append(place)
                }
            }
        }
        print(likelyPlaces)
        
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}
