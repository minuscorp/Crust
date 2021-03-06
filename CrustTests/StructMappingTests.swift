import XCTest
import Crust
import JSONValueRX

class StructMappingTests: XCTestCase {

    func testStructMapping() {
        
        let stub = PersonStub()
        let json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Person, PersonMapping>()
        let object = try! mapper.mapFromJSONToNewObject(json, mapping: PersonMapping())
        
        XCTAssertTrue(stub.matches(object))
    }
    
    func testNilClearsOptionalValue() {
        
        let stub = PersonStub()
        var json = try! JSONValue(object: stub.generateJsonObject())
        let mapper = CRMapper<Person, PersonMapping>()
        var object = try! mapper.mapFromJSONToNewObject(json, mapping: PersonMapping())
        
        XCTAssertTrue(object.ownsCat!)
        
        stub.ownsCat = nil
        json = try! JSONValue(object: stub.generateJsonObject())
        object = try! mapper.mapFromJSON(json, toObject: object, mapping: PersonMapping())
        
        XCTAssertNil(object.ownsCat)
    }
}
