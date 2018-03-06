//
//  Weather.swift
//  Simple Chat
//
//  Created by Pacino Zhang on 2018/2/8.
//  Copyright © 2018年 Glenn R. Fisher. All rights reserved.
//

import Foundation
import MapKit
import OpenWeatherSwift


public class WeatherPart {
    
    func getWeather(_ location: String) -> String{
        var result = ""
        //print(location)
        let client = OpenWeatherSwift(apiKey: "ed9049dc12e1698ee3b17de097abadaa", temperatureFormat: .Celsius)
        let semaphore = DispatchSemaphore(value: 0)
        if (location == "Columbus"){
            let myLocation = CLLocation(latitude: 39.96, longitude: -83)
            client.currentWeatherByCoordinates(coords: myLocation.coordinate){results in
                let weather = Weather2.init(data: results)
                result = "In " + location + " The Temperature is " + (String) (weather.temperature) + " celsius. The weather condition is " + (String)(weather.condition) + ". Visibility is " + (String)(weather.visibility) + " meters."
                semaphore.signal()
            }
        }else{
            client.currentWeatherByCity(name: location){results in
                let weather = Weather2.init(data: results)
                result = "In " + location + " The Temperature is " + (String) (weather.temperature) + " celsius. The weather condition is " + (String)(weather.condition) + ". Visibility is " + (String)(weather.visibility) + " meter."
                semaphore.signal()
            }
        }
        semaphore.wait()
        print (result)
        return result
    }
}




