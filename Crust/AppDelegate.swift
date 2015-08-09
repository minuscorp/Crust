import UIKit
import SwiftyJSON

private let kDefaultLatitude = 37.775
private let kDefaultLongitude = -122.0
private let kDefaultEndLatitude = 38.0

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let uberProductsRequest = CRUberProductsRequest(withLatitude: kDefaultLatitude,
            longitude: kDefaultLongitude)
        uberProductsRequest.send()
        
        let uberPriceEstimatesRequest = CRUberPriceEstimatesRequest(withStartLatitude: kDefaultLatitude,
            startLongitude: kDefaultLongitude,
            endLatitude: kDefaultEndLatitude, endLongitude: kDefaultLongitude)
        uberPriceEstimatesRequest.send()
        
        let uberTimeEstimatesRequest = CRUberTimeEstimatesRequest(withStartLatitude: kDefaultLatitude, startLongitude: kDefaultLongitude)
        uberTimeEstimatesRequest.send()
        
        let uberPromotionsRequest = CRUberPromotionsRequest(withStartLatitude: kDefaultLatitude,
            startLongitude: kDefaultLongitude,
            endLatitude: kDefaultEndLatitude,
            endLongitude: kDefaultLongitude)
        uberPromotionsRequest.send()
        
        testMapper()
        
        return true
    }
    
    func testMapper() {
        let key = "1.2"
        let array = [ "derp", "blah", 1 ]
        let json:JSON = [:]
        print(json)
        let result = mapToJson(json, fromField: array, viaKey: key)
        
        switch result {
        case .Value(let json):
            print(json)
        case .Error(let error):
            print(error)
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

