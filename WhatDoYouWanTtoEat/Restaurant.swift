//
//  Restaurant.swift
//  WhatDoYouWanTtoEat
//
//  Created by PeterChen on 2017/9/4.
//  Copyright © 2017年 PeterChen. All rights reserved.
//

import Foundation

class Restaurant {
    var name: String?
    var latitude: Double?
    var longitude: Double?
//    var type: String?
    var openNow: Bool?
    var photoRef: String?
    var placeID: String?
    var rating: Double?
    var vicinity: String?
    
    init(name: String?, latitude: Double?, longitude: Double?, openNow: Bool?, photoRef: String?, placeID: String?, rating: Double?, vicinity: String?) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
//        self.type = type
        self.openNow = openNow
        self.photoRef = photoRef
        self.placeID = placeID
        self.rating = rating
        self.vicinity = vicinity
    }
    

}
