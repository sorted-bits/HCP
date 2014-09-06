@objc(HomeWizard)
class HomeWizard: _HomeWizard {
	
	private var _fetchDataTimer: NSTimer? = nil;
	private var _fetchSensorsTimer: NSTimer? = nil;
    
    override class func discover(includeStored: Bool, completion: (results: [Controller]) -> Void) {
        
        let discoveryUrl = "http://gateway.homewizard.nl/discovery.php";
		
		logDebug("HomeWizard Discovery: " + discoveryUrl);
		
        let manager = AFHTTPRequestOperationManager();
        
        manager.GET(discoveryUrl, parameters: nil, success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
				
				if (responseObject.objectForKey("status") as String == "ok") {
					var ipAddress = responseObject.objectForKey("ip") as String
					var match: AnyObject! = HomeWizard.findFirstByAttribute("ip", withValue: ipAddress);
					
					if (match == nil) {
						
						logInfo("Discovered HomeWizard not yet in database (" + ipAddress + ")");
						
						var foundObject: HomeWizard = HomeWizard.createEntityInContext(nil) as HomeWizard;
						foundObject.ip = ipAddress;
						foundObject.name = ipAddress;
						foundObject.lastUpdate = NSDate.date();
						completion(results: [foundObject]);
					}
					else {
						
						logInfo("Discovered HomeWizard is already in database (" + ipAddress + ")");
						
						if  (includeStored) {
							var foundObject: HomeWizard = match as HomeWizard
							completion(results: [foundObject])
						}
						else {
							completion(results: []);
						}
					}
					
				}
				else {
					completion(results: []);
				}
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                logError("Error: " + error.localizedDescription)
            }
        )
    }
    
    func performAction(command: String, completion: (results: AnyObject!) -> Void ) -> Void {
		logDebug("Performing HomeWizard Command: " + command);
		
		let url = "http://" + self.ip! + "/" + self.password! + command;
		
		let manager = AFHTTPRequestOperationManager();
		manager.GET(url, parameters: nil, success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
			completion(results: responseObject);
		},
		failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
		});
    }
	
	func login(password: String, completion: (success: Bool) -> Void) -> Void {
		self.password = password;
		self.performAction("/enlist", completion: { (results) -> Void in
			if (results.objectForKey("status") != nil) {
				var status: String = results.objectForKey("status") as String;
				completion(success: (status == "ok"));
			}
		});
	}
	
	func fetchSensors() {
		
		// Disable data fetch, to make sure that values don't overwrite eachother
		if (_fetchDataTimer != nil) {
			_fetchDataTimer?.invalidate();
			_fetchDataTimer = nil;
		}
		
		logInfo("Fetching sensors");
		
		
		self.performAction("/get-sensors", completion: { (results) -> Void in
			
			if (results != nil && results.objectForKey("response") != nil) {
				let response = results.objectForKey("response");
				
				println(response);
			}
			if (self._fetchDataTimer == nil) {
				self._fetchDataTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("fetchData"), userInfo: nil, repeats: true);
			}
		});
		
		
		// When done, start updating data (again)
	}
	
	func fetchData() {
		logInfo("Fetching data");
	}
	
	override func start() {
		
		if (self.managedObjectContext == nil) {
			logError("This object is not saved, you cannot store sensors for this device.");
			return;
		}
		
		_fetchSensorsTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: Selector("fetchSensors"), userInfo: nil, repeats: true);
		
		// Because we don't want to wait for the timer to trigger, call fetchSensors now also
		self.fetchSensors();
	}
	
	override func stop() {
		
		if (_fetchDataTimer != nil) {
			_fetchDataTimer?.invalidate();
			_fetchDataTimer = nil;
		}
		
		if (_fetchSensorsTimer != nil) {
			_fetchSensorsTimer?.invalidate();
			_fetchSensorsTimer = nil;
		}
		
	}
    
}
