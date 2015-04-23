
//
//  Expressions.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/22/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

class Expression: Node, Printable {
    var op: Token
    var type: TypeBase

    var description: String {
        return op.description
    }

    init(op: Token, type: TypeBase, line: UInt) {
        self.op = op
        self.type = type
        super.init(line: line)
    }

    func generateRHS() -> Expression {
        return self
    }

    func reduceWithGenerator(gen: Generator) -> Expression {
        return self
    }

    func convertTo(to: TypeBase, withGenerator gen: Generator) -> Expression {
        let reduced = self.reduceWithGenerator(gen)
        if type == to {
            return reduced
        }
        else {
            let temp = gen.getTemporaryOfType(to)
            var opString = ""
            if to.floatingPoint {
                if type.numeric && !type.floatingPoint {
                    opString = "sitofp"
                }
            }
            else if to.numeric {
                if type.floatingPoint {
                    opString = "fptosi"
                }
                else if to.apparentSize > type.apparentSize {
                    opString = "zext"
                }
                else if to.apparentSize < type.apparentSize {
                    opString = "trunc"
                }
            }
            if opString == "" {
                error("can't convert \(type) to \(to)", line)
            }
            gen.appendInstruction("\(temp) = \(opString) \(type) \(reduced) to \(to)")
            return temp
        }
    }

    func LLVMString() -> String {
        return op.LLVMString()
    }
}

extension Expression: Printable, Streamable {
    //TODO: Move 'description' getter to this extension

    func writeTo<Target : OutputStreamType>(inout target: Target) {
        target.write(self.LLVMString())
    }
}

class Temporary: Identifier {
    var number: UInt

    init(number: UInt, type: TypeBase, line: UInt) {
        self.number = number
        super.init(op: .Temp, type: type, line: line)
        self.allocated = true
    }

    override func LLVMString() -> String {
        return "%t.\(number)"
    }
}

func ==(lhs: Identifier, rhs: Identifier) -> Bool {
    if lhs.offset == rhs.offset
        && lhs.isArgument == rhs.isArgument
        && lhs.enclosingFuncName == rhs.enclosingFuncName
        && lhs.scopeNumber == rhs.scopeNumber
        && lhs.op == rhs.op {
        return true
    }
    return false
}

class Identifier: Expression, Equatable {
    var offset = 0
    var allocated = false
    var isArgument = false
    var isGlobal = false
    var enclosingFuncName = ""
    var scopeNumber: UInt = 0

    override var description: String {
        return op.description
    }

    override init(op: Token, type: TypeBase, line: UInt) {
        super.init(op: op, type: type, line: line)
    }

    override func LLVMString() -> String {
        var prefix = isGlobal ? "@" : "%"
        var postfix = isArgument ? ".arg" : ".\(enclosingFuncName).\(scopeNumber)"
        if isGlobal {
            postfix = ""
        }
        return "\(prefix)\(op)\(postfix)"
    }

    override func reduceWithGenerator(gen: Generator) -> Expression {
        let temp = gen.getTemporaryOfType(type)
        gen.appendInstruction("\(temp) = load \(type)* \(self)")
        return temp
    }

    func getPointerWithGenerator(gen: Generator) -> Expression {
        if !allocated {
            gen.appendInstruction("\(self) = alloca \(self.type)")
            allocated = true
        }
        return self
    }
}

class ArrayAccess: Identifier {
    var indexExpr: Expression
    var arrayId: Identifier

    init(indexExpr: Expression, arrayId: Identifier, line: UInt) {
        self.indexExpr = indexExpr
        self.arrayId = arrayId
        if !(arrayId.type is ArrayType) {
            error("attempt to access member of non-array type", line)
        }
        super.init(op: arrayId.op, type: (arrayId.type as! ArrayType).to, line: line)
    }

    override func reduceWithGenerator(gen: Generator) -> Expression {
        let ptr = arrayId.getPointerWithGenerator(gen)
        let index = indexExpr.reduceWithGenerator(gen)
        let temp = gen.getTemporaryOfType(type)
        gen.appendInstruction("\(temp) = getelementptr \(ptr.type)* \(ptr), i32 0, i32 \(index)")
        let temp2 = gen.getTemporaryOfType(type)
        gen.appendInstruction("\(temp2) = load \(type)* \(temp)")
        return temp2
    }

    override func getPointerWithGenerator(gen: Generator) -> Expression {
        let ptr = arrayId.getPointerWithGenerator(gen)
        let index = indexExpr.reduceWithGenerator(gen)
        let temp = gen.getTemporaryOfType(type)
        gen.appendInstruction("\(temp) = getelementptr \(ptr.type)* \(ptr), i32 0, i32 \(index)")
        return temp
    }
}

class Operator: Expression {

}

class Arithmetic: Operator {
    var expr1: Expression
    var expr2: Expression

    override func LLVMString() -> String {
        var prefix = ""
        if self.op == .Divide {
            prefix = "s"
        }
        else if self.type == TypeBase.floatType() {
            prefix = "f"
        }
        let opString = prefix + op.LLVMString()
        return "\(opString) \(type) \(expr1), \(expr2)"
    }

    init(op: Token, expr1: Expression, expr2: Expression, line: UInt) {
        self.expr1 = expr1
        self.expr2 = expr2
        super.init(op: op, type: Type_max(expr1.type, expr2.type), line: line)
    }

    override func reduceWithGenerator(gen: Generator) -> Expression {
        let reduced1 = expr1.reduceWithGenerator(gen)
        let reduced2 = expr2.reduceWithGenerator(gen)
        let temp = gen.getTemporaryOfType(type)
        let result = Arithmetic(op: op, expr1: reduced1, expr2: reduced2, line: line)
        gen.appendInstruction("\(temp) = \(result)")
        return temp
    }
}

class Unary: Operator {
    var expr: Expression

    init(op: Token, expr: Expression, line: UInt) {
        self.expr = expr
        super.init(op: op, type: expr.type, line: line)
    }
}

class Constant: Expression {
    init(intVal val: Int, line: UInt) {
        super.init(op: .Integer(val), type: TypeBase.intType(), line: line)
        //FIXME: CHAR_MIN??
        if /*val >= Int(CHAR_MIN) && */val <= Int(CHAR_MAX) {
            type = TypeBase.charType()
        }
    }

    init(floatVal val: Double, line: UInt) {
        super.init(op: .Decimal(val), type: TypeBase.floatType(), line: line)
    }

    override init(op: Token, type: TypeBase, line: UInt) {
        super.init(op: op, type: type, line: line)
    }

    override func convertTo(to: TypeBase, withGenerator gen: Generator) -> Expression {
        if to != type {
            type = to
            if to == TypeBase.charType() {
                switch op {
                case .Integer(let val):
                    op = .Integer(Int(Int8(val!)))
                case .Decimal(let val):
                    op = .Integer(Int(Int8(val!)))
                default:
                    return super.convertTo(to, withGenerator: gen)
                }
            }
            else if to == TypeBase.intType() {
                switch op {
                case .Integer(_):
                    break
                case .Decimal(let val):
                    op = .Integer(Int(val!))
                default:
                    return super.convertTo(to, withGenerator: gen)
                }
            }
            else if to == TypeBase.floatType() {
                switch op {
                case .Integer(let val):
                    op = .Decimal(Double(val!))
                default:
                    return super.convertTo(to, withGenerator: gen)
                }
            }
        }
        return self
    }
}

class ArrayLiteral: Constant {
    var values: [Constant]

    init(values: [Constant], line: UInt) {
        self.values = values
        let elementType = values[0].type
        super.init(op: .Unknown, type: ArrayType(numElements: UInt(values.count), to: elementType), line: line)
    }

    override func convertTo(to: TypeBase, withGenerator gen: Generator) -> Expression {
        if !(to is ArrayType) {
            error("cannot convert array to non-array type", line)
        }
        for value in values {
            value.convertTo((to as! ArrayType).to, withGenerator: gen)
        }
        type = to
        return self
    }

    override func LLVMString() -> String {
        var ret = "["
        for i in 0 ..< values.count {
            ret.extend("\(values[i].type) \(values[i])")
            if i < values.count - 1 {
                ret.extend(", ")
            }
        }
        ret.extend("]")
        return ret
    }
}

protocol Logical {
    var type: TypeBase { get }

    func generateLLVMBranchesWithGenerator(gen: Generator, trueLabel: Label, falseLabel: Label)
}

class BooleanConstant: Constant, Logical {
    init(boolVal val: Bool, line: UInt) {
        super.init(op: .Boolean(val), type: TypeBase.boolType(), line: line)
    }

   func generateLLVMBranchesWithGenerator(gen: Generator, trueLabel: Label, falseLabel: Label) {
        switch op {
        case .Boolean(let val):
            if val! {
                gen.appendInstruction("br label %L\(trueLabel)")
            }
            if !val! {
                gen.appendInstruction("br label %L\(falseLabel)")
            }
        default:
            error("how did this even happen", line)
        }
    }
}

class And: Expression, Logical {
    var expr1: Logical
    var expr2: Logical

    init(op: Token, expr1: Logical, expr2: Logical, line: UInt) {
        self.expr1 = expr1
        self.expr2 = expr2
        super.init(op: op, type:  TypeBase.boolType(), line: line)
        //TODO: Add type checking
        if (expr1.type == expr2.type) {

        }
    }

    convenience init(expr1: Logical, expr2: Logical, line: UInt) {
        self.init(op: .And, expr1: expr1, expr2: expr2, line: line)
    }

    func generateLLVMBranchesWithGenerator(gen: Generator, trueLabel: Label, falseLabel: Label) {
        var label = (falseLabel == 0) ? gen.reserveLabel() : falseLabel

        expr1.generateLLVMBranchesWithGenerator(gen, trueLabel: 0, falseLabel: label)
        expr2.generateLLVMBranchesWithGenerator(gen, trueLabel: trueLabel, falseLabel: falseLabel)

        if falseLabel == 0 {
            gen.appendLabel(label)
        }
    }
}

class Or: Expression, Logical {
    var expr1: Logical
    var expr2: Logical

    init(op: Token, expr1: Logical, expr2: Logical, line: UInt) {
        self.expr1 = expr1
        self.expr2 = expr2
        super.init(op: op, type:  TypeBase.boolType(), line: line)
        //TODO: Add type checking
        if (expr1.type == expr2.type) {

        }
    }

    convenience init(expr1: Logical, expr2: Logical, line: UInt) {
        self.init(op: .Or, expr1: expr1, expr2: expr2, line: line)
    }

    func generateLLVMBranchesWithGenerator(gen: Generator, trueLabel: Label, falseLabel: Label) {
        var label = (trueLabel == 0) ? gen.reserveLabel() : trueLabel

        expr1.generateLLVMBranchesWithGenerator(gen, trueLabel: label, falseLabel: 0)
        expr2.generateLLVMBranchesWithGenerator(gen, trueLabel: trueLabel, falseLabel: falseLabel)

        if trueLabel == 0 {
            gen.appendLabel(label)
        }
    }
}

class Not: Expression, Logical {
    var expr: Logical

    init(op: Token, expr: Logical, line: UInt) {
        self.expr = expr
        super.init(op: op, type: TypeBase.boolType(), line: line)
    }

    func generateLLVMBranchesWithGenerator(gen: Generator, trueLabel: Label, falseLabel: Label) {
        expr.generateLLVMBranchesWithGenerator(gen, trueLabel: falseLabel, falseLabel: trueLabel)
    }
}

class Relation: Expression, Logical {
    var expr1: Expression
    var expr2: Expression

    init(op: Token, expr1: Expression, expr2: Expression, line: UInt) {
        self.expr1 = expr1
        self.expr2 = expr2
        super.init(op: op, type:  TypeBase.boolType(), line: line)
        //TODO: Add type checking
        if (expr1.type == expr2.type) {

        }
    }

    func generateLLVMBranchesWithGenerator(gen: Generator, trueLabel: Label, falseLabel: Label) {
        let maxType = Type_max(expr1.type, expr2.type)
        let reduced1 = expr1.convertTo(maxType, withGenerator: gen)
        let reduced2 = expr2.convertTo(maxType, withGenerator: gen)

        var cmpPrefix = "i"
        if maxType == TypeBase.floatType() {
            cmpPrefix = "f"
        }

        var testPrefix = "s"
        if op == .Equal || op == .NEqual {
            testPrefix = ""
        }
        if maxType == TypeBase.floatType() {
            testPrefix = "o"
        }

        let temp = gen.getTemporaryOfType(TypeBase.boolType())
        gen.appendInstruction("\(temp) = \(cmpPrefix)cmp \(testPrefix)\(op) \(maxType) \(reduced1), \(reduced2)")
        if trueLabel != 0 && falseLabel != 0 {
            gen.appendInstruction("br i1 \(temp), label %L\(trueLabel), label %L\(falseLabel)");
        }
    }
}

class Call: Expression {
    var id: Identifier
    var args: [Expression]
    var signature: Prototype

    init(id: Identifier, args: [Expression], signature: Prototype, line: UInt) {
        self.id = id
        self.args = args
        self.signature = signature
        super.init(op: id.op, type: id.type, line: line)
    }

    override func reduceWithGenerator(gen: Generator) -> Expression {
        var reducedArray: [Expression] = []
        var index = 0
        for arg in args {
            reducedArray.append(arg.convertTo(signature.args[index].type, withGenerator: gen))
        }
        self.args = reducedArray
        let temp = gen.getTemporaryOfType(type)
        gen.appendInstruction("\(temp) = \(self)")
        return temp
    }

    override func LLVMString() -> String {
        var callString = "call \(type) \(id) ("
        var index = 0
        for arg in args {
            callString.extend("\(arg.type) \(arg)")
            if index < args.count-1 {
                callString.extend(",")
            }
            index++
        }
        callString.extend(")")
        return callString
    }
}

