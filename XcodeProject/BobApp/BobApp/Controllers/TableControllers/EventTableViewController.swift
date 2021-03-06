//
//  EventTableViewController.swift
//  BobApp
//
//  Created by Joachim Zeelmaekers on 28/10/2017.
//  Copyright © 2017 Joachim Zeelmaekers. All rights reserved.
//
import UIKit
import FBSDKLoginKit
import Foundation
import Alamofire
import SwiftyJSON
import CoreLocation
import SDWebImage

class EventTableViewController: UITableViewController {
    var mappedEvents: [Event] = []
    var favoriteEvents: [Event] = []
    var longitude:Double!
    var latitude:Double!
    var radiusInMeters: Int!
    var time:String!
    var accessToken:String! = FBSDKAccessToken.current().tokenString
    var selectedRow: Int = -1
    
    @IBAction func unwindToDetail(segue: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let decoded = UserDefaults.standard.object(forKey: "RestFavoriteEvents") as? Data
        if decoded == nil {
            favoriteEvents = []
        } else {
            favoriteEvents = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Event]
        }
        DispatchQueue.global(qos: .background).async {

            if(self.latitude != nil && self.longitude != nil) {
            self.getEventsFromApi(radiusInMeters: self.radiusInMeters, time: self.time, latitude: self.latitude, longitude: self.longitude, accessToken: self.accessToken, completion: {
                self.tableView.reloadData()
                self.dismiss(animated: false, completion: nil)
                
                if(self.mappedEvents.count == 1) {
                    let alertController = UIAlertController(title: "Evenementen", message:
                        "Er is \(self.mappedEvents.count) evenement gevonden.", preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "Ga door", style: UIAlertActionStyle.destructive,handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    let alertController = UIAlertController(title: "Evenementen", message:
                        "Er zijn \(self.mappedEvents.count) evenementen gevonden.", preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "Ga door", style: UIAlertActionStyle.destructive,handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            })
            } else {
                self.dismiss(animated: false, completion: nil)
                let alertController = UIAlertController(title: "Foutmelding", message:
                    "Je locatievoorzieningen staan niet aan, gelieve deze aan te zetten.", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Annuleer", style: UIAlertActionStyle.destructive,handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: "Even geduld aub...", preferredStyle: .alert)
            
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            loadingIndicator.startAnimating();
            
            alert.view.addSubview(loadingIndicator)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mappedEvents.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
        self.performSegue(withIdentifier: "ShowDetailOfEventSegue", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "EventUITableCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? EventUITableViewCell  else {
            fatalError("The dequeued cell is not an instance of EventUITableCell.")
        }
        let event = mappedEvents[indexPath.row]
        cell.eventNam.text = event.name
        cell.attenders.text = "Aanwezigen: \(event.attending)"
        cell.organisator.text = event.organisator
        cell.photoEvent.sd_setImage(with: URL(string: event.profilePicture), placeholderImage: UIImage(named: ""))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let favorite = UITableViewRowAction(style: .normal, title: "❤ \n Favoriet") { action, index in
            self.favoriteEvents.append(self.mappedEvents[indexPath.row])
            tableView.reloadData()
        }
        favorite.backgroundColor = UIColor.green
        return [favorite]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowDetailOfEventSegue") {
            if let navigationViewController = segue.destination as? UINavigationController {
                let detailViewController = navigationViewController.topViewController as! DetailViewController;
                detailViewController.selectedEvent = mappedEvents[selectedRow]
            }
        }
        if (segue.identifier == "FavoriteEventsSegue") {
            if let navigationViewController = segue.destination as? UINavigationController {
                let favoriteViewController = navigationViewController.topViewController as! FavoriteEventTableViewController;
                    let defaults = UserDefaults.standard
                    let encodedData = NSKeyedArchiver.archivedData(withRootObject: favoriteEvents)
                    defaults.set(encodedData, forKey: "FavoriteEvents")
            }
        }
    }
    
    func getEventsFromApi(radiusInMeters: Int, time: String, latitude: Double, longitude: Double, accessToken: String, completion: @escaping () -> ()) {
        let url = "http://0.0.0.0:3000/events?&lat=\(latitude)&lng=\(longitude)&distance=\(radiusInMeters)&sort=venue&accessToken=\(accessToken)"
        print(url);
        Alamofire.request(url).validate().responseJSON { response in
            if let jsonObj = response.result.value {
                let json = JSON(jsonObj)
                for (_, event) in json["events"] {
                    // get coordinates from event and your current to calculate distance.
                    let coordinate₀ = CLLocation(latitude: event["place"]["location"]["latitude"].double!, longitude: event["place"]["location"]["longitude"].double!)
                    let coordinate₁ = CLLocation(latitude: latitude, longitude: longitude)
                    // distance result in meters
                    let distanceInMeters = coordinate₀.distance(from: coordinate₁)
                    // properties from event only those who we need
                    let title = event["name"].string
                    let attending = event["stats"]["attending"].int
                    let startdate = event["startTime"].string
                    let enddate = event["endTime"].string
                    let organisator = event["venue"]["name"].string
                    let description = event["description"].string
                    let lat = event["place"]["location"]["latitude"].double
                    let long = event["place"]["location"]["longitude"].double
                    let id = event["id"].string
                    let link = "https://www.facebook.com/events/" + id!
                    let profilePic = event["coverPicture"].string
                    let bannerPic = event["coverPicture"].string
                    var e : Event?
                    if(enddate != nil && startdate != nil && organisator != nil && description != nil && title != nil && profilePic != nil && bannerPic != nil) {
                        e = Event(name: title!, attending: attending!, afstand: distanceInMeters, startdate: startdate!, enddate: enddate!, organisator: organisator!, description: description!, lat: lat!, long: long!, link: link, profilePicture: profilePic!, bannerPicture: bannerPic! )
                    }
                    
                    if(e != nil) {
                        self.mappedEvents.append(e!)
                    }
                }
            }
            completion()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let _:CLLocationCoordinate2D = manager.location!.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error)")
    }
    
}
