//
//  DataService.swift
//  WhatDoYouWanTtoEat
//
//  Created by PeterChen on 2018/1/2.
//  Copyright © 2018年 PeterChen. All rights reserved.
//

import Foundation
import CoreLocation

class DataService {
    static let instance = DataService()
    // get photos
    //https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=CnRtAAAATLZNl354RwP_9UKbQ_5Psy40texXePv4oAlgP4qNEkdIrkyse7rPXYGd9D_Uj1rVsQdWT4oRz4QrYAJNpFX7rzqqMlZw2h2E2y5IKMUZ7ouD_SlcHxYq1yL4KbKUv3qtWgTK0A6QbGh87GB3sscrHRIQiG2RrmU_jF4tENr9wGS_YxoUSSDrYjWmrNfeEHSGSc3FyhNLlBU&key=YOUR_API_KEY
    let placeUrlAPI: String = SecretKey.instance.getPlaceUrlAPIKey()
    // type: cafe, restaurant
    func getGoogleMapUrl(searchLocation location: CLLocationCoordinate2D?, searchRadius radius: Int, searchType type: String) -> String {
        if let location = location {
            return "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(location.latitude),\(location.longitude)&radius=\(radius)&type=\(type)&key=\(placeUrlAPI)"
        } else {
            return "Not yet load location"
        }
    }
    func getGoogleMapUrlWithPageToken(pageToken token: String) -> String{
        print("token: https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=\(token)&key=\(placeUrlAPI)")
        return "https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=\(token)&key=\(placeUrlAPI)"
    }
    
    
    
    
    
    
}
