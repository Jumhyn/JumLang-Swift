
//
//  Expressions.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/22/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

class Expression: Node, CustomStringConvertible {
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

    func reduce(with gen: Generator) -> Expression {
        return self
    }

    func convert(to: TypeBase, with gen: Generator) -> Expression {
        let reduced = self.reduce(with: gen)
        if type == to {
            return reduced
        }
        else {
            let temp = gen.getTemporary(of: to)
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
                error("can't convert \(type) to \(to)", line: line)
            }
            gen.append("\(temp) = \(opString) \(type) \(reduced) to \(to)")
            return temp
        }
    }

    func LLVMString() -> String {
        return op.LLVMString()
    }
}

extension Expression: TextOutputStreamable {
    //TODO: Move 'description' getter to this extension

    func write<Target : TextOutputStream>(to target: inout Target) {
        target.write(self.LLVMString())
    }
}

class Temporary: Identifier {
    var number: UInt

    init(number: UInt, type: TypeBase, line: UInt) {
        self.number = number
        super.init(op: .temp, type: type, line: line)
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
        let prefix = isGlobal ? "@" : "%"
        var postfix = isArgument ? ".arg" : ".\(enclosingFuncName).\(scopeNumber)"
        if isGlobal {
            postfix = ""
        }
        return "\(prefix)\(op)\(postfix)"
    }

    override func reduce(with gen: Generator) -> Expression {
        let temp = gen.getTemporary(of: type)
        gen.append("\(temp) = load \(type)* \(self)")
        return temp
    }

    func getPointer(with gen: Generator) -> Expression {
        if !allocated {
            gen.append("\(self) = alloca \(self.type)")
            allocated = true
        }
        return self
    }
}

class MemberAccess: Identifier {
    var index: UInt
    var parent: Identifier

    init(member: Expression, parent: Identifier, line: UInt) {
        if let type = parent.type as? AggregateType {
            self.parent = parent
            if let actualMember = type.getMember(withName: member.op), let index = type.getIndex(of: actualMember) {
                 self.index = UInt(index)
            }
            else {
                error("could not find member \(member) in type \(parent.type)", line: line)
            }
        }
        else {
            error("attempt to access member of non-aggregate type", line: line)
        }
        super.init(op: parent.op, type: member.type, line: line)
    }

    override func reduce(with gen: Generator) -> Expression {
        let ptr = getPointer(with: gen)
        let temp = gen.getTemporary(of: type)
        gen.append("\(temp) = load \(type)* \(ptr)");
        return temp
    }

    override func getPointer(with gen: Generator) -> Expression {
        let parentPtr = parent.getPointer(with: gen)
        let temp = gen.getTemporary(of: type)
        gen.append("\(temp) = getelementptr \(parentPtr.type)* \(parentPtr), i32 0, i32 \(self.index)")
        return temp;
    }
}

class ArrayAccess: Identifier {
    var indexExpr: Expression
    var arrayId: Identifier

    init(indexExpr: Expression, arrayId: Identifier, line: UInt) {
        self.indexExpr = indexExpr
        self.arrayId = arrayId
        if !(arrayId.type is ArrayType) {
            error("attempt to access index of non-array type", line: line)
        }
        if (!indexExpr.type.numeric || indexExpr.type.floatingPoint) {
            error("array index must have integer-valued type", line: line)
        }
        super.init(op: arrayId.op, type: (arrayId.type as! ArrayType).to, line: line)
    }

    override func reduce(with gen: Generator) -> Expression {
        let ptr = getPointer(with: gen)
        let temp2 = gen.getTemporary(of: type)
        gen.append("\(temp2) = load \(type)* \(ptr)")
        return temp2
    }

    override func getPointer(with gen: Generator) -> Expression {
        let ptr = arrayId.getPointer(with: gen)
        let index = indexExpr.reduce(with: gen)
        let temp = gen.getTemporary(of: type)
        gen.append("\(temp) = getelementptr \(ptr.type)* \(ptr), i32 0, i32 \(index)")
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
        if self.op == .divide {
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

    override func reduce(with gen: Generator) -> Expression {
        let reduced1 = expr1.reduce(with: gen)
        let reduced2 = expr2.reduce(with: gen)
        let temp = gen.getTemporary(of: type)
        let result = Arithmetic(op: op, expr1: reduced1, expr2: reduced2, line: line)
        gen.append("\(temp) = \(result)")
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
        super.init(op: .integer(val), type: TypeBase.intType(), line: line)
        //FIXME: CHAR_MIN??
        if /*val >= Int(CHAR_MIN) && */val <= Int(CHAR_MAX) {
            type = TypeBase.charType()
        }
    }

    init(floatVal val: Double, line: UInt) {
        super.init(op: .decimal(val), type: TypeBase.floatType(), line: line)
    }

    override init(op: Token, type: TypeBase, line: UInt) {
        super.init(op: op, type: type, line: line)
    }

    override func convert(to: TypeBase, with gen: Generator) -> Expression {
        if to != type {
            if to.numeric != type.numeric {
                error("cannot convert \(type) to \(to)", line: line)
            }
            type = to
            if to == TypeBase.charType() {
                switch op {
                case .integer(let val):
                    op = .integer(Int(Int8(val)))
                case .decimal(let val):
                    op = .integer(Int(Int8(val)))
                default:
                    return super.convert(to: to, with: gen)
                }
            }
            else if to == TypeBase.intType() {
                switch op {
                case .integer(_):
                    break
                case .decimal(let val):
                    op = .integer(Int(val))
                default:
                    return super.convert(to: to, with: gen)
                }
            }
            else if to == TypeBase.floatType() {
                switch op {
                case .integer(let val):
                    op = .decimal(Double(val))
                default:
                    return super.convert(to: to, with: gen)
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
        super.init(op: .unknown, type: ArrayType(numElements: UInt(values.count), to: elementType), line: line)
    }

    override func convert(to: TypeBase, with gen: Generator) -> Expression {
        if let to = to as? ArrayType {
            for value in values {
                _ = value.convert(to: to.to, with: gen)
            }
            type = to
            return self
        }
        else {
            error("cannot convert array to non-array type", line: line)
        }
    }

    override func LLVMString() -> String {
        var ret = "["
        for i in 0 ..< values.count {
            ret += "\(values[i].type) \(values[i])"
            if i < values.count - 1 {
                ret += ", "
            }
        }
        ret += "]"
        return ret
    }
}

protocol Logical {
    var type: TypeBase { get }

    func generateLLVMBranches(with gen: Generator, trueLabel: Label, falseLabel: Label)
}

class BooleanConstant: Constant, Logical {
    init(boolVal val: Bool, line: UInt) {
        super.init(op: .boolean(val), type: TypeBase.boolType(), line: line)
    }

   func generateLLVMBranches(with gen: Generator, trueLabel: Label, falseLabel: Label) {
        switch op {
        case .boolean(let val):
            if val {
                gen.append("br label %L\(trueLabel)")
            }
            if !val {
                gen.append("br label %L\(falseLabel)")
            }
        default:
            error("how did this even happen", line: line)
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
        self.init(op: .and, expr1: expr1, expr2: expr2, line: line)
    }

    func generateLLVMBranches(with gen: Generator, trueLabel: Label, falseLabel: Label) {
        let label = (falseLabel == 0) ? gen.reserveLabel() : falseLabel

        expr1.generateLLVMBranches(with: gen, trueLabel: 0, falseLabel: label)
        expr2.generateLLVMBranches(with: gen, trueLabel: trueLabel, falseLabel: falseLabel)

        if falseLabel == 0 {
            gen.append(label)
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
        self.init(op: .or, expr1: expr1, expr2: expr2, line: line)
    }

    func generateLLVMBranches(with gen: Generator, trueLabel: Label, falseLabel: Label) {
        let label = (trueLabel == 0) ? gen.reserveLabel() : trueLabel

        expr1.generateLLVMBranches(with: gen, trueLabel: label, falseLabel: 0)
        expr2.generateLLVMBranches(with: gen, trueLabel: trueLabel, falseLabel: falseLabel)

        if trueLabel == 0 {
            gen.append(label)
        }
    }
}

class Not: Expression, Logical {
    var expr: Logical

    init(op: Token, expr: Logical, line: UInt) {
        self.expr = expr
        super.init(op: op, type: TypeBase.boolType(), line: line)
    }

    func generateLLVMBranches(with gen: Generator, trueLabel: Label, falseLabel: Label) {
        expr.generateLLVMBranches(with: gen, trueLabel: falseLabel, falseLabel: trueLabel)
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

    func generateLLVMBranches(with gen: Generator, trueLabel: Label, falseLabel: Label) {
        let maxType = Type_max(expr1.type, expr2.type)
        let reduced1 = expr1.convert(to: maxType, with: gen)
        let reduced2 = expr2.convert(to: maxType, with: gen)

        var cmpPrefix = "i"
        if maxType == TypeBase.floatType() {
            cmpPrefix = "f"
        }

        var testPrefix = "s"
        if op == .equal || op == .nEqual {
            testPrefix = ""
        }
        if maxType == TypeBase.floatType() {
            testPrefix = "o"
        }

        let temp = gen.getTemporary(of: TypeBase.boolType())
        gen.append("\(temp) = \(cmpPrefix)cmp \(testPrefix)\(op) \(maxType) \(reduced1), \(reduced2)")
        if trueLabel != 0 && falseLabel != 0 {
            gen.append("br i1 \(temp), label %L\(trueLabel), label %L\(falseLabel)");
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

    override func reduce(with gen: Generator) -> Expression {
        var reducedArray: [Expression] = []
        let index = 0
        for arg in args {
            reducedArray.append(arg.convert(to: signature.args[index].type, with: gen))
        }
        self.args = reducedArray
        let temp = gen.getTemporary(of: type)
        gen.append("\(temp) = \(self)")
        return temp
    }

    override func LLVMString() -> String {
        var callString = "call \(type) \(id) ("
        var index = 0
        for arg in args {
            callString += "\(arg.type) \(arg)"
            if index < args.count-1 {
                callString += ","
            }
            index += 1
        }
        callString += ")"
        return callString
    }
}

