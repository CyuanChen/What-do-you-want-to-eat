//
//  Restaurant.swift
//  WhatDoYouWanTtoEat
//
//  Created by PeterChen on 2017/9/4.
//  Copyright © 2017年 PeterChen. All rights reserved.
//

import Foundation

class Restaurant {
    var name = ""
    var type = ""
    var location = ""
    var image = ""
    var isVisited = false
    var phone = ""
    var rating = ""
    
    init(name: String, type: String, location: String, image: String, phone: String, rating: String) {
        self.name = name
        self.type = type
        self.location = location
        self.image = image
        self.phone = phone
        self.rating = rating
    }
    
    func visit() {
        self.isVisited = true
    }
}
