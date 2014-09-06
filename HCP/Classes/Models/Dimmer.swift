@objc(Dimmer)
class Dimmer: _Dimmer {

	// Custom logic goes here.
    
    func dim(dimValue: Int) -> Void {
		
		(self.controller! as HomeWizard).performAction(String(format: "/sw/dim/%d/%@", self.id!, self.stateValue()), completion: { (results) -> Void in
			self.dimValue = dimValue;
		});
		
    }

}