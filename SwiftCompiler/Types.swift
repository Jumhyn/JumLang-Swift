//
//  Types.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/26/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

func ==(lhs: TypeBase, rhs: TypeBase) -> Bool {
    return lhs.width == rhs.width && (lhs.isNumeric !^ rhs.isNumeric)
}

func ==(lhs: TypeBase?, rhs: TypeBase?) -> Bool {
    if let lhsUnwrapped = lhs {
        if let rhsUnwrapped = rhs {
            return lhsUnwrapped == rhsUnwrapped
        }
        else {
            return false
        }
    }
    else {
        if let rhsUnwrapped = rhs {
            return false
        }
        return true
    }
}

func ==(lhs: PointerType, rhs: PointerType) -> Bool {
    return lhs.to == rhs.to
}

func ==(lhs: ArrayType, rhs: ArrayType) -> Bool {
    return lhs.to == rhs.to && lhs.elements == rhs.elements
}

func Type_max(type1: TypeBase, type2: TypeBase) -> TypeBase {
    if (type1 == TypeBase.floatType() || type2 == TypeBase.floatType()) {
        return TypeBase.floatType();
    }
    else if (type1 == TypeBase.intType() || type2 == TypeBase.intType()) {
        return TypeBase.intType();
    }
    else {
        return TypeBase.charType();
    }
}

class TypeBase : LLVMPrintable {
    var isNumeric: Bool = false
    var width: UInt = 0

    init(_ isNumeric: Bool, _ width: UInt) {
        self.isNumeric = isNumeric
        self.width = width
    }

    func LLVMString() -> String {
        return "i32"
    }

    class func voidType() -> TypeBase {
        return TypeBase(false, 0)
    }
    class func boolType() -> TypeBase {
        return TypeBase(false, 1)
    }
    class func charType() -> TypeBase {
        return TypeBase(true, 1)
    }
    class func intType() -> TypeBase {
        return TypeBase(true, 4)
    }
    class func floatType() -> TypeBase {
        return TypeBase(true, 8)
    }
}

class PointerType : TypeBase {
    var to: TypeBase
    init(_ to: TypeBase) {
        self.to = to
        super.init(false, 4)
    }
}

class ArrayType : PointerType {
    var elements: UInt
    init(_ elements: UInt, _ to: TypeBase) {
        self.elements = elements
        super.init(to)
    }
}