import SwiftyJSON
import Runes

/**
* This file defines a new operator which is used to create a mapping between an object and a JSON key value.
* There is an overloaded operator definition for each type of object that is supported in ObjectMapper.
* This provides a way to add custom logic to handle specific types of objects
*/

infix operator >*< { associativity right }

public func >*< <T, U>(left: T, right: U) -> (T, U) {
    return (left, right)
}

public func >*< <T: CRMappingKey, U>(left: T, right: U) -> (CRMappingKey, U) {
    return (left, right)
}

infix operator <- { associativity right }

// MARK:- Objects with Basic types

/// Object of Basic type
public func <- <T: CRFieldType, C: CRMappingContext>(inout field: T, map:(key: CRMappingKey, context: C)) -> C {
    
    if case .Error(_)? = map.context.result {
        return map.context
    }
    
    switch map.context.dir {
    case .ToJSON:
        let json = map.context.json
        let result = mapToJson(json, fromField: field, viaKey: map.key)
        
        switch result {
        case .Value(let json):
            map.context.json = json
            map.context.result = Result.Value(json)
        case .Error(let error):
            map.context.result = Result.Error(error)
        }
    case .FromJSON:
        let baseJSON = map.context.json[map.key]
        map.context.result = mapFromJson(baseJSON, toField: &field)
    }
    
    return map.context
}

func mapToJson<T: CRFieldType>(var json: JSON, fromField field: T, viaKey key: CRMappingKey) -> Result<JSON> {
    
    switch field {
    case is Bool:
        json[key] = JSON(field as! Bool)
    case is Int:
        json[key] = JSON(field as! Int)
    case is NSNumber:
        json[key] = JSON(field as! NSNumber)
    case is String:
        json[key] = JSON(field as! String)
    case is Double:
        json[key] = JSON(field as! Double)
    case is Array<CRFieldType>:
        // TODO: Iterate through each element and wrap as JSON and add to our json.
//        json[key] = JSON(field as! Array)
        break
    case is Dictionary<String, CRFieldType>:
        // TODO: Iterate through each element and wrap as JSON and add to our json.
//        json[key] = JSON(field as! Dictionary)
        break
    }
    
    if let error = json.error {
        // TODO: Wrap this error in our own error.
        return Result.Error(error)
    }
    
    return Result.Value(json)
}

/// Map to JSON with field as optional type.
func mapToJson<T: CRFieldType>(var json: JSON, fromField field: T?, viaKey key: CRMappingKey) -> Result<JSON> {
    
    if let field = field {
        return mapToJson(json, fromField: field, viaKey: key)
    } else {
        json[key] = JSON(NSNull)
        return Result.Value(json)
    }
}

// TODO: Have a map for optional fields. .Null will map to `nil`.
func mapFromJson<T: CRFieldType>(json: JSON, inout toField field: T) -> Result<Any>? {
    
    // TODO: Clarify our errors.
    let error: NSError = NSError(domain: "CRMappingDomain", code: -1, userInfo: nil)
    
    if case .Unknown = json.type {
        return Result.Error(error)
    }
    
    switch field {
    case is Bool:
        if let rawBool = json.bool {
            field = rawBool as! T
        } else {
            return Result.Error(error)
        }
    case is Int:
        if let rawInt = json.number {
            field = rawInt as! T
        } else {
            return Result.Error(error)
        }
    case is NSNumber:
        if let rawNumber = json.number {
            field = rawNumber as! T
        } else {
            return Result.Error(error)
        }
    case is String:
        if let rawString = json.string {
            field = rawString as! T
        } else {
            return Result.Error(error)
        }
    case is Double:
        if let rawDouble = json.double {
            field = rawDouble as! T
        } else {
            return Result.Error(error)
        }
    case is Array<CRFieldType>:
        if let rawArray = json.array {
            field = rawArray as! T
        } else {
            return Result.Error(error)
        }
    case is Dictionary<String, CRFieldType>:
        if let rawDictionary = json.dictionary {
            field = rawDictionary as! T
        } else {
            return Result.Error(error)
        }
    }
    
    return nil
}

/// Optional object of basic type
public func <- <T>(inout left: T?, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalBasicType(&left, object: right.value())
    } else {
        ToJSON.optionalBasicType(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Implicitly unwrapped optional object of basic type
public func <- <T>(inout left: T!, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalBasicType(&left, object: right.value())
    } else {
        ToJSON.optionalBasicType(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

// MARK:- Raw Representable types

/// Object of Raw Representable type
public func <- <T: RawRepresentable>(inout left: T, right: Map) {
    left <- (right, EnumTransform())
}

/// Optional Object of Raw Representable type
public func <- <T: RawRepresentable>(inout left: T?, right: Map) {
    left <- (right, EnumTransform())
}

/// Implicitly Unwrapped Optional Object of Raw Representable type
public func <- <T: RawRepresentable>(inout left: T!, right: Map) {
    left <- (right, EnumTransform())
}

// MARK:- Arrays of Raw Representable type

/// Array of Raw Representable object
public func <- <T: RawRepresentable>(inout left: [T], right: Map) {
    left <- (right, EnumTransform())
}

/// Array of Raw Representable object
public func <- <T: RawRepresentable>(inout left: [T]?, right: Map) {
    left <- (right, EnumTransform())
}

/// Array of Raw Representable object
public func <- <T: RawRepresentable>(inout left: [T]!, right: Map) {
    left <- (right, EnumTransform())
}

// MARK:- Dictionaries of Raw Representable type

/// Dictionary of Raw Representable object
public func <- <T: RawRepresentable>(inout left: [String: T], right: Map) {
    left <- (right, EnumTransform())
}

/// Dictionary of Raw Representable object
public func <- <T: RawRepresentable>(inout left: [String: T]?, right: Map) {
    left <- (right, EnumTransform())
}

/// Dictionary of Raw Representable object
public func <- <T: RawRepresentable>(inout left: [String: T]!, right: Map) {
    left <- (right, EnumTransform())
}

// MARK:- Transforms

/// Object of Basic type with Transform
public func <- <T, Transform: TransformType where Transform.Object == T>(inout left: T, right: (Map, Transform)) {
    if right.0.mappingType == MappingType.FromJSON {
        let value: T? = right.1.transformFromJSON(right.0.currentValue)
        FromJSON.basicType(&left, object: value)
    } else {
        let value: Transform.JSON? = right.1.transformToJSON(left)
        ToJSON.optionalBasicType(value, key: right.0.currentKey!, dictionary: &right.0.JSONDictionary)
    }
}

/// Optional object of basic type with Transform
public func <- <T, Transform: TransformType where Transform.Object == T>(inout left: T?, right: (Map, Transform)) {
    if right.0.mappingType == MappingType.FromJSON {
        let value: T? = right.1.transformFromJSON(right.0.currentValue)
        FromJSON.optionalBasicType(&left, object: value)
    } else {
        let value: Transform.JSON? = right.1.transformToJSON(left)
        ToJSON.optionalBasicType(value, key: right.0.currentKey!, dictionary: &right.0.JSONDictionary)
    }
}

/// Implicitly unwrapped optional object of basic type with Transform
public func <- <T, Transform: TransformType where Transform.Object == T>(inout left: T!, right: (Map, Transform)) {
    if right.0.mappingType == MappingType.FromJSON {
        let value: T? = right.1.transformFromJSON(right.0.currentValue)
        FromJSON.optionalBasicType(&left, object: value)
    } else {
        let value: Transform.JSON? = right.1.transformToJSON(left)
        ToJSON.optionalBasicType(value, key: right.0.currentKey!, dictionary: &right.0.JSONDictionary)
    }
}

/// Array of Basic type with Transform
public func <- <T: TransformType>(inout left: [T.Object], right: (Map, T)) {
    let (map, transform) = right
    if map.mappingType == MappingType.FromJSON {
        let values = fromJSONArrayWithTransform(map.currentValue, transform: transform)
        FromJSON.basicType(&left, object: values)
    } else {
        let values = toJSONArrayWithTransform(left, transform: transform)
        ToJSON.optionalBasicType(values, key: map.currentKey!, dictionary: &map.JSONDictionary)
    }
}

/// Optional array of Basic type with Transform
public func <- <T: TransformType>(inout left: [T.Object]?, right: (Map, T)) {
    let (map, transform) = right
    if map.mappingType == MappingType.FromJSON {
        let values = fromJSONArrayWithTransform(map.currentValue, transform: transform)
        FromJSON.optionalBasicType(&left, object: values)
    } else {
        let values = toJSONArrayWithTransform(left, transform: transform)
        ToJSON.optionalBasicType(values, key: map.currentKey!, dictionary: &map.JSONDictionary)
    }
}

/// Implicitly unwrapped optional array of Basic type with Transform
public func <- <T: TransformType>(inout left: [T.Object]!, right: (Map, T)) {
    let (map, transform) = right
    if map.mappingType == MappingType.FromJSON {
        let values = fromJSONArrayWithTransform(map.currentValue, transform: transform)
        FromJSON.optionalBasicType(&left, object: values)
    } else {
        let values = toJSONArrayWithTransform(left, transform: transform)
        ToJSON.optionalBasicType(values, key: map.currentKey!, dictionary: &map.JSONDictionary)
    }
}

/// Dictionary of Basic type with Transform
public func <- <T: TransformType>(inout left: [String: T.Object], right: (Map, T)) {
    let (map, transform) = right
    if map.mappingType == MappingType.FromJSON {
        let values = fromJSONDictionaryWithTransform(map.currentValue, transform: transform)
        FromJSON.basicType(&left, object: values)
    } else {
        let values = toJSONDictionaryWithTransform(left, transform: transform)
        ToJSON.optionalBasicType(values, key: map.currentKey!, dictionary: &map.JSONDictionary)
    }
}

/// Optional dictionary of Basic type with Transform
public func <- <T: TransformType>(inout left: [String: T.Object]?, right: (Map, T)) {
    let (map, transform) = right
    if map.mappingType == MappingType.FromJSON {
        let values = fromJSONDictionaryWithTransform(map.currentValue, transform: transform)
        FromJSON.optionalBasicType(&left, object: values)
    } else {
        let values = toJSONDictionaryWithTransform(left, transform: transform)
        ToJSON.optionalBasicType(values, key: map.currentKey!, dictionary: &map.JSONDictionary)
    }
}

/// Implicitly unwrapped optional dictionary of Basic type with Transform
public func <- <T: TransformType>(inout left: [String: T.Object]!, right: (Map, T)) {
    let (map, transform) = right
    if map.mappingType == MappingType.FromJSON {
        let values = fromJSONDictionaryWithTransform(map.currentValue, transform: transform)
        FromJSON.optionalBasicType(&left, object: values)
    } else {
        let values = toJSONDictionaryWithTransform(left, transform: transform)
        ToJSON.optionalBasicType(values, key: map.currentKey!, dictionary: &map.JSONDictionary)
    }
}

private func fromJSONArrayWithTransform<T: TransformType>(input: AnyObject?, transform: T) -> [T.Object] {
    if let values = input as? [AnyObject] {
        return values.flatMap { value in
            return transform.transformFromJSON(value)
        }
    } else {
        return []
    }
}

private func fromJSONDictionaryWithTransform<T: TransformType>(input: AnyObject?, transform: T) -> [String: T.Object] {
    if let values = input as? [String: AnyObject] {
        return values.filterMap { value in
            return transform.transformFromJSON(value)
        }
    } else {
        return [:]
    }
}

private func toJSONArrayWithTransform<T: TransformType>(input: [T.Object]?, transform: T) -> [T.JSON]? {
    return input?.flatMap { value in
        return transform.transformToJSON(value)
    }
}

private func toJSONDictionaryWithTransform<T: TransformType>(input: [String: T.Object]?, transform: T) -> [String: T.JSON]? {
    return input?.filterMap { value in
        return transform.transformToJSON(value)
    }
}

// MARK:- Mappable Objects - <T: Mappable>

/// Object conforming to Mappable
public func <- <T: Mappable>(inout left: T, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.object(&left, object: right.currentValue)
    } else {
        ToJSON.object(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Optional Mappable objects
public func <- <T: Mappable>(inout left: T?, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObject(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObject(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Implicitly unwrapped optional Mappable objects
public func <- <T: Mappable>(inout left: T!, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObject(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObject(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

// MARK:- Dictionary of Mappable objects - Dictionary<String, T: Mappable>

/// Dictionary of Mappable objects <String, T: Mappable>
public func <- <T: Mappable>(inout left: Dictionary<String, T>, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.objectDictionary(&left, object: right.currentValue)
    } else {
        ToJSON.objectDictionary(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Optional Dictionary of Mappable object <String, T: Mappable>
public func <- <T: Mappable>(inout left: Dictionary<String, T>?, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObjectDictionary(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObjectDictionary(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Implicitly unwrapped Optional Dictionary of Mappable object <String, T: Mappable>
public func <- <T: Mappable>(inout left: Dictionary<String, T>!, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObjectDictionary(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObjectDictionary(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Dictionary of Mappable objects <String, T: Mappable>
public func <- <T: Mappable>(inout left: Dictionary<String, [T]>, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.objectDictionaryOfArrays(&left, object: right.currentValue)
    } else {
        ToJSON.objectDictionaryOfArrays(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Optional Dictionary of Mappable object <String, T: Mappable>
public func <- <T: Mappable>(inout left: Dictionary<String, [T]>?, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObjectDictionaryOfArrays(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObjectDictionaryOfArrays(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Implicitly unwrapped Optional Dictionary of Mappable object <String, T: Mappable>
public func <- <T: Mappable>(inout left: Dictionary<String, [T]>!, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObjectDictionaryOfArrays(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObjectDictionaryOfArrays(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

// MARK:- Array of Mappable objects - Array<T: Mappable>

/// Array of Mappable objects
public func <- <T: Mappable>(inout left: Array<T>, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.objectArray(&left, object: right.currentValue)
    } else {
        ToJSON.objectArray(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Optional array of Mappable objects
public func <- <T: Mappable>(inout left: Array<T>?, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObjectArray(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObjectArray(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Implicitly unwrapped Optional array of Mappable objects
public func <- <T: Mappable>(inout left: Array<T>!, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObjectArray(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObjectArray(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}


// MARK:- Set of Mappable objects - Set<T: Mappable where T: Hashable>

/// Array of Mappable objects
public func <- <T: Mappable where T: Hashable>(inout left: Set<T>, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.objectSet(&left, object: right.currentValue)
    } else {
        ToJSON.objectSet(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}


/// Optional array of Mappable objects
public func <- <T: Mappable where T: Hashable>(inout left: Set<T>?, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObjectSet(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObjectSet(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}

/// Implicitly unwrapped Optional array of Mappable objects
public func <- <T: Mappable where T: Hashable>(inout left: Set<T>!, right: Map) {
    if right.mappingType == MappingType.FromJSON {
        FromJSON.optionalObjectSet(&left, object: right.currentValue)
    } else {
        ToJSON.optionalObjectSet(left, key: right.currentKey!, dictionary: &right.JSONDictionary)
    }
}
