import CoreData
import Foundation


//
//  RKObjectUtilities.m
//  RestKit
//
//  Created by Blake Watters on 9/30/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

//#import <objc/message.h>
//#import <objc/runtime.h>

let _C_ID: Character =       "@"
let _C_CLASS: Character =    "#"
let _C_SEL: Character =      ":"
let _C_CHR: Character =      "c"
let _C_UCHR: Character =     "C"
let _C_SHT: Character =      "s"
let _C_USHT: Character =     "S"
let _C_INT: Character =      "i"
let _C_UINT: Character =     "I"
let _C_LNG: Character =      "l"
let _C_ULNG: Character =     "L"
let _C_LNG_LNG: Character =  "q"
let _C_ULNG_LNG: Character = "Q"
let _C_FLT: Character =      "f"
let _C_DBL: Character =      "d"
let _C_BFLD: Character =     "b"
let _C_BOOL: Character =     "B"
let _C_VOID: Character =     "v"
let _C_UNDEF: Character =    "?"
let _C_PTR: Character =      "^"
let _C_CHARPTR: Character =  "*"
let _C_ATOM: Character =     "%"
let _C_ARY_B: Character =    "["
let _C_ARY_E: Character =    "]"
let _C_UNION_B: Character =  "("
let _C_UNION_E: Character =  ")"
let _C_STRUCT_B: Character = "{"
let _C_STRUCT_E: Character = "}"
let _C_VECTOR: Character =   "!"
let _C_CONST: Character =    "r"

func classIsNSCollection(aClass: AnyObject.Type) -> Bool {
    return aClass == NSSet.self || aClass == NSArray.self || aClass == NSOrderedSet.self
}

func objectIsNSCollection(object: AnyObject) -> Bool {
    return classIsNSCollection(object.dynamicType)
}

func objectIsNSCollectionContainingOnlyManagedObjects(object: AnyObject) -> Bool {
    if !objectIsNSCollection(object) {
        return false
    }
    
    for subobject in (object as SequenceType) {
        if NSManagedObject.self != subobject.dynamictype {
            return false
        }
    }
    
    return true
}

func objectIsNSCollectionOfNSCollections(object: AnyObject) -> Bool {
    if !objectIsNSCollection(object) {
        return false
    }
    
    var sanityCheck: AnyObject? = nil
    if object.respondsToSelector(Selector("anyObject")) {
        sanityCheck = object.anyObject()
    }
    if object.respondsToSelector(Selector("lastObject")) {
        sanityCheck = object.lastObject()
    }
    return objectIsNSCollection(sanityCheck)
}

func keyValueCodingClassForObjCType(type: [Character]) -> AnyObject.Type {
    if (type.count > 0) {
        switch (type[0]) {
        case _C_ID: {
            let data = (String(type) as NSString).UTF8String
            let openingQuoteLoc = strchr(data, "\"")
            if (openingQuoteLoc) {
                let closingQuoteLoc = strchr(openingQuoteLoc + 1, "\"");
                if (closingQuoteLoc) {
                    let classNameStrLen = closingQuoteLoc - openingQuoteLoc;
                    let className[classNameStrLen];
                    memcpy(className, openingQuoteLoc+1, classNameStrLen - 1);
                    // Null-terminate the array to stringify
                    className[classNameStrLen - 1] = "\0";
                    objc_getClass(className);
                }
            }
        // If there is no quoted class type (id), it can be used as-is.
        return Nil;
        }
        
        case _C_CHR: fallthrough // char
        case _C_UCHR: fallthrough // unsigned char
        case _C_SHT: fallthrough // short
        case _C_USHT: fallthrough // unsigned short
        case _C_INT: fallthrough // int
        case _C_UINT: fallthrough // unsigned int
        case _C_LNG: fallthrough // long
        case _C_ULNG: fallthrough // unsigned long
        case _C_LNG_LNG: fallthrough // long long
        case _C_ULNG_LNG: fallthrough // unsigned long long
        case _C_FLT: fallthrough // float
        case _C_DBL: // double
        return [NSNumber class];
        
        case _C_BOOL: // C++ bool or C99 _Bool
            return objc_getClass("NSCFBoolean")
            ?: objc_getClass("__NSCFBoolean")
            ?: [NSNumber class];
        
        case _C_STRUCT_B: // struct
        case _C_BFLD: // bitfield
        case _C_UNION_B: // union
        return [NSValue class];
        
        case _C_ARY_B: // c array
        case _C_PTR: // pointer
        case _C_VOID: // void
        case _C_CHARPTR: // char *
        case _C_CLASS: // Class
        case _C_SEL: // selector
        case _C_UNDEF: // unknown type (function pointer, etc)
        default:
        break;
    }
}
return nil;
}

Class RKKeyValueCodingClassFromPropertyAttributes(const char *attr)
{
    if (attr) {
        const char *typeIdentifierLoc = strchr(attr, 'T');
        if (typeIdentifierLoc) {
            return RKKeyValueCodingClassForObjCType(typeIdentifierLoc+1);
        }
    }
    return Nil;
}

NSString *RKPropertyTypeFromAttributeString(NSString *attributeString)
{
    NSString *type = [NSString string];
    NSScanner *typeScanner = [NSScanner scannerWithString:attributeString];
    [typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"@"] intoString:NULL];
    
    // we are not dealing with an object
    if ([typeScanner isAtEnd]) {
        return @"NULL";
    }
    [typeScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"@"] intoString:NULL];
    // this gets the actual object type
    [typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&type];
    return type;
}
