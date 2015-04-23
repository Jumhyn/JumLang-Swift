//
//  Types.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/26/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

func ==(lhs: TypeBase, rhs: TypeBase) -> Bool {
    return lhs.apparentSize == rhs.apparentSize
        && lhs.numeric == rhs.numeric
        && lhs.signed == rhs.signed
        && lhs.floatingPoint == rhs.floatingPoint
}

func !=(lhs: TypeBase, rhs: TypeBase) -> Bool {
    return !(lhs == rhs)
}

func ==(lhs: TypeBase?, rhs: TypeBase?) -> Bool {
    if let lhs = lhs {
        if let rhs = rhs {
            return lhs == rhs
        }
        return false
    }
    else {
        if let rhs = rhs {
            return false
        }
        return true
    }
}

func ==(lhs: PointerType, rhs: PointerType) -> Bool {
    return lhs.to == rhs.to
}

func ==(lhs: ArrayType, rhs: ArrayType) -> Bool {
    return lhs.to == rhs.to && lhs.numElements == rhs.numElements
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
    var numeric = false
    var signed = true
    var floatingPoint = false
    var apparentSize: UInt = 0
    var actualSize: UInt = 0

    init(numeric: Bool, signed: Bool, floatingPoint: Bool, apparentSize: UInt) {
        self.numeric = numeric
        self.signed = signed
        self.floatingPoint = floatingPoint
        self.apparentSize = apparentSize
        self.actualSize = (apparentSize / 8 + 1) * 8
    }

    func LLVMString() -> String {
        var ret = floatingPoint ? "f" : "i"
        ret += String(apparentSize)
        return ret
    }

    func defaultConstant() -> Constant {
        if numeric {
            if floatingPoint {
                return Constant(floatVal: 0, line: 0)
            }
            else {
                return Constant(intVal: 0, line: 0)
            }
        }
        else if apparentSize == 1 {
            return BooleanConstant(boolVal: false, line: 0)
        }
        else {
            error("cannot initialize \(self) with default value", 0)
        }
    }

    func writeTo<Target : OutputStreamType>(inout target: Target) {
        target.write(self.LLVMString())
    }

    class func voidType() -> TypeBase {
        return TypeBase(numeric: false, signed: false, floatingPoint: false, apparentSize: 0)
    }
    class func boolType() -> TypeBase {
        return TypeBase(numeric: false, signed: false, floatingPoint: false, apparentSize: 1)
    }
    class func charType() -> TypeBase {
        return TypeBase(numeric: true, signed: true, floatingPoint: false, apparentSize: 8)
    }
    class func intType() -> TypeBase {
        return TypeBase(numeric: true, signed: true, floatingPoint: false, apparentSize: 32)
    }
    class func floatType() -> TypeBase {
        return TypeBase(numeric: true, signed: true, floatingPoint: true, apparentSize: 64)
    }
}

class PointerType : TypeBase {
    var to: TypeBase

    init(to: TypeBase) {
        self.to = to
        super.init(numeric: false, signed: false, floatingPoint: false, apparentSize: 32)
    }
}

class ArrayType : PointerType {
    var numElements: UInt

    init(numElements: UInt, to: TypeBase) {
        self.numElements = numElements
        super.init(to: to)
    }

    override func LLVMString() -> String {
        return "[\(numElements) x \(to)]"
    }

    override func defaultConstant() -> Constant {
        var defaultVal = to.defaultConstant()
        return ArrayLiteral(values: Array<Constant>(count: Int(numElements), repeatedValue: defaultVal), line: 0)
    }
}