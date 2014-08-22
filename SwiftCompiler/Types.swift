//
//  Types.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/26/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

func ==(lhs: TypeBase, rhs: TypeBase) -> Bool {
    return lhs.width == rhs.width && lhs.isNumeric !^ rhs.isNumeric
}

class TypeBase {
    var isNumeric: Bool = false
    var width: UInt = 0

    init(_ isNumeric: Bool, _ width: UInt) {
        self.isNumeric = isNumeric
        self.width = width
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