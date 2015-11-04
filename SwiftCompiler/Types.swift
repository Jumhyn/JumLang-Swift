//
//  Types.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 7/26/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

func ==(lhs: TypeBase, rhs: TypeBase) -> Bool {
    return lhs.equals(rhs)
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

class TypeBase : LLVMPrintable, Equatable {
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
        self.actualSize = apparentSize == 0 ? 0 : ((apparentSize - 1) / 8 + 1) * 8 //TODO: fix actualSize calculation
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
            error("cannot initialize \(self) with default value", line: 0)
        }
    }

    func writeTo<Target : OutputStreamType>(inout target: Target) {
        target.write(self.LLVMString())
    }

    func equals(other: TypeBase) -> Bool {
        return self.apparentSize == other.apparentSize
            && self.numeric == other.numeric
            && self.signed == other.signed
            && self.floatingPoint == other.floatingPoint
    }

    func canConvertTo(other: TypeBase) -> Bool {
        if self == other {
            return true
        }
        return false
    }

    class func voidType() -> TypeBase {
        return TypeBase(numeric: false, signed: false, floatingPoint: false, apparentSize: 0)
    }
    class func boolType() -> TypeBase {
        return BoolType()
    }
    class func charType() -> TypeBase {
        return IntegerType(bytes: 1)
    }
    class func intType() -> TypeBase {
        return IntegerType(bytes: 4)
    }
    class func floatType() -> TypeBase {
        return FloatType(doubleWidth: true)
    }
}

class NumericType : TypeBase {
    init(signed: Bool, floatingPoint: Bool, apparentSize: UInt) {
        super.init(numeric: true, signed: signed, floatingPoint: floatingPoint, apparentSize: apparentSize)
    }

    override func canConvertTo(other: TypeBase) -> Bool {
        return other is NumericType || self == other
    }
}

class BoolType : TypeBase {
    init() {
        super.init(numeric: false, signed: false, floatingPoint: false, apparentSize: 1)
    }

    override func LLVMString() -> String {
        return "i1"
    }
}

class FloatType : NumericType {
    var doubleWidth: Bool = false

    init(doubleWidth: Bool) {
        self.doubleWidth = doubleWidth
        super.init(signed: true, floatingPoint: true, apparentSize: doubleWidth ? 64 : 32)
    }

    override func LLVMString() -> String {
        return doubleWidth ? "double" : "float"
    }
}

class IntegerType : NumericType {
    init(bytes: UInt) {
        super.init(signed: true, floatingPoint: false, apparentSize: bytes * 8)
    }

    override func LLVMString() -> String {
        return "i" + String(apparentSize)
    }
}

class PointerType : TypeBase {
    var to: TypeBase

    init(to: TypeBase) {
        self.to = to
        super.init(numeric: false, signed: false, floatingPoint: false, apparentSize: 32)
    }

    override func equals(other: TypeBase) -> Bool {
        if let other = other as? PointerType {
            return self.to == other.to && super.equals(other)
        }
        else {
            return false
        }
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
        let defaultVal = to.defaultConstant()
        return ArrayLiteral(values: Array<Constant>(count: Int(numElements), repeatedValue: defaultVal), line: 0)
    }

    override func equals(other: TypeBase) -> Bool {
        if let other = other as? ArrayType {
            return self.numElements == other.numElements && super.equals(other)
        }
        else {
            return false
        }
    }
}