//
//  RiderViewController.swift
//  UberDemo
//
//  Created by 洋蔥胖 on 2018/7/25.
//  Copyright © 2018年 ChrisYoung. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase
import GoogleMobileAds

class RiderViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callAnUberButton: UIButton!
    
    @IBOutlet weak var bannerView: GADBannerView!
    
    
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var uberHasBeenCalled = false
    var driverOnTheWay = false
    var driverLocation = CLLocationCoordinate2D()
    
    let riderDB = Database.database().reference().child("Rider")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //新增一個廣告 如果有bug 記得看一下main.storyboard的bannerView Class有沒有選 GADBnnerView
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        //取得你的經緯度
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        
        if let email = Auth.auth().currentUser?.email{
            riderDB.queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded) { (snapshot) in
                self.uberHasBeenCalled = true
                self.callAnUberButton.setTitle("取消打車", for: .normal)
                self.riderDB.removeAllObservers()
                
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                        if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            self.driverOnTheWay = true
                            self.displayDriverAndRider()
                            
                            if let email = Auth.auth().currentUser?.email { self.riderDB.queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged, with: { (snapshot) in
                                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                                        if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                            self.driverOnTheWay = true
                                            self.displayDriverAndRider()
                                        }
                                    }
                                }
                            })
                            }
                        }
                    }
                }
            }
        }
    }
    
    func displayDriverAndRider() {
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        callAnUberButton.setTitle("Your driver is \(roundedDistance)km away!", for: .normal)
        map.removeAnnotations(map.annotations)
        
        let latDelta = abs(driverLocation.latitude - userLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - userLocation.longitude) * 2 + 0.005
        
        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        map.setRegion(region, animated: true)
        
        let riderAnno = MKPointAnnotation()
        riderAnno.coordinate = userLocation
        riderAnno.title = "你的位址"
        map.addAnnotation(riderAnno)
        
        let driverAnno = MKPointAnnotation()
        driverAnno.coordinate = driverLocation
        driverAnno.title = "你的司機"
        map.addAnnotation(driverAnno)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            userLocation = center
            
            if uberHasBeenCalled {
                displayDriverAndRider()
            }else{
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                map.setRegion(region, animated: true)
                map.removeAnnotations(map.annotations)
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "你的位址"
                map.addAnnotation(annotation)
            }
            
            
        }
    }
    
    //叫車功能
    @IBAction func callUberTapped(_ sender: Any) {
        if !driverOnTheWay {
            if let email = Auth.auth().currentUser?.email {
                
                
                if uberHasBeenCalled {
                    uberHasBeenCalled = false
                    callAnUberButton.setTitle("打車", for: .normal)
                    riderDB.queryOrdered(byChild: "email").queryEqual(toValue: email).observe(DataEventType.childAdded) { (snapshot) in
                        snapshot.ref.removeValue()
                        self.riderDB.removeAllObservers()
                    }
                }else{
                    let riderDictionary: [String: Any] = ["email":email , "lat": userLocation.latitude , "lon":userLocation.longitude]
                    riderDB.childByAutoId().setValue(riderDictionary)
                    uberHasBeenCalled = true
                    callAnUberButton.setTitle("Cancel Uber", for: .normal)
                    
                }
            }
        }
    }
    
    @IBAction func logOutTapped(_ sender: Any) {
        
        try? Auth.auth().signOut()
        navigationController?.dismiss(animated: true, completion: nil)
        
    }
    
}
