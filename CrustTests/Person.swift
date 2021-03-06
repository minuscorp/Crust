import Foundation
import Crust
import JSONValueRX

enum HairColor : String, AnyMappable {
    case Blue
    case Brown
    case Gold
    case Unknown
    
    init() {
        self = .Unknown
    }
}

struct Person : AnyMappable {
    
    var bankAccounts: Array<Int> = [ 1234, 5678 ]
    var attitude: String = "awesome"
    var hairColor: HairColor = .Unknown
    var ownsCat: Bool? = nil
}

class HairColorMapping : Transform {
    typealias MappedObject = HairColor
    
    func fromJSON(json: JSONValue) throws -> HairColor {
        switch json {
        case .JSONString(let str):
            switch str {
            case "Gold":
                return .Gold
            case "Brown":
                return .Brown
            case "Blue":
                return .Blue
            default:
                return .Unknown
            }
        default:
            return .Unknown
        }
    }
    
    func toJSON(obj: HairColor) -> JSONValue {
        return .JSONString(obj.rawValue)
    }
}

class PersonMapping : AnyMapping {
    
    typealias MappedObject = Person
    
    func mapping(inout tomap: Person, context: MappingContext) {
        tomap.bankAccounts  <- "bank_accounts" >*<
        tomap.attitude      <- "traits.attitude" >*<
        tomap.hairColor     <- .Mapping("traits.bodily.hair_color", HairColorMapping()) >*<
        tomap.ownsCat       <- "owns_cat" >*<
        context
    }
}

class PersonStub {
    
    var bankAccounts: Array<Int> = [ 0987, 6543 ]
    var attitude: String = "whoaaaa"
    var hairColor: HairColor = .Blue
    var ownsCat: Bool? = true
    
    init() { }
    
    func generateJsonObject() -> Dictionary<String, AnyObject> {
        var ownsCatVal: AnyObject
        if let cat = self.ownsCat {
            ownsCatVal = cat
        } else {
            ownsCatVal = NSNull()
        }
        
        return [
            "owns_cat" : ownsCatVal,
            "bank_accounts" : bankAccounts,
            "traits" : [
                "attitude" : attitude,
                "bodily" : [
                    "hair_color" : hairColor.rawValue
                ]
            ],
        ]
    }
    
    func matches(object: Person) -> Bool {
        var matches = true
        matches &&= attitude == object.attitude
        matches &&= hairColor == object.hairColor
        matches &&= bankAccounts == object.bankAccounts
        matches &&= ownsCat == object.ownsCat
        
        return matches
    }
}
