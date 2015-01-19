
//
//  Expressions.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/22/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

class Expression: Node {
    var op: Token
    var type: TypeBase

    init(op: Token, type: TypeBase) {
        self.op = op
        self.type = type
    }

    func generateRHS() -> Expression {
        return self
    }

    func reduce() -> Expression {
        return self
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
    var isAllocated = false
    var isArgument = false
    var isGlobal = false
    var enclosingFuncName = ""
    var scopeNumber: UInt = 0

    init(op: Token, type: TypeBase, offset: Int) {
        self.offset = offset
        super.init(op: op, type: type)
    }

    func LLVMString() -> String {
        var prefix = isGlobal ? "@" : "%"
        var postfix = isArgument ? ".arg" : ".\(enclosingFuncName).\(scopeNumber)"
        return "\(prefix)\(op)\(postfix)"
    }
}

class Operator: Expression {

}

class Arithmetic: Operator {
    var expr1: Expression
    var expr2: Expression

    init(op: Token, expr1: Expression, expr2: Expression) {
        self.expr1 = expr1
        self.expr2 = expr2
        super.init(op: op, type: Type_max(expr1.type, expr2.type))
    }
}

class Unary: Operator {
    var expr: Expression

    init(op: Token, expr: Expression) {
        self.expr = expr
        super.init(op: op, type: expr.type)
    }
}

class Constant: Expression {
    init(intVal val: Int) {
        super.init(op: .Integer(val), type: TypeBase.intType())
    }

    init (floatVal val: Double) {
        super.init(op: .Decimal(val), type: TypeBase.floatType())
    }
}

class Logical: Expression {
    func generateLLVMBranchesWithGenerator(gen: Generator, trueLabel: Label, falseLabel: Label) {

    }
}

class BooleanConstant: Logical {
    init(boolVal val: Bool) {
        super.init(op: .Boolean(val), type: TypeBase.boolType())
    }
}

class And: Logical {
    var expr1: Expression
    var expr2: Expression

    init(op: Token, expr1: Expression, expr2: Expression) {
        self.expr1 = expr1
        self.expr2 = expr2
        super.init(op: op, type:  TypeBase.boolType())
        //TODO: Add type checking
        if (expr1.type == expr2.type) {

        }
    }

    convenience init(expr1: Expression, expr2: Expression) {
        self.init(op: .And, expr1: expr1, expr2: expr2)
    }
}

class Or: Logical {
    var expr1: Expression
    var expr2: Expression

    init(op: Token, expr1: Expression, expr2: Expression) {
        self.expr1 = expr1
        self.expr2 = expr2
        super.init(op: op, type:  TypeBase.boolType())
        //TODO: Add type checking
        if (expr1.type == expr2.type) {

        }
    }

    convenience init(expr1: Expression, expr2: Expression) {
        self.init(op: .Or, expr1: expr1, expr2: expr2)
    }
}

class Not: Logical {
    var expr: Logical

    init(op: Token, expr: Logical) {
        self.expr = expr
        super.init(op: op, type: TypeBase.boolType())
    }

    override func generateLLVMBranchesWithGenerator(gen: Generator, trueLabel: Label, falseLabel: Label) {
        expr.generateLLVMBranchesWithGenerator(gen, trueLabel: falseLabel, falseLabel: trueLabel)
    }
}

class Relation: Logical {
    var expr1: Expression
    var expr2: Expression

    init(op: Token, expr1: Expression, expr2: Expression) {
        self.expr1 = expr1
        self.expr2 = expr2
        super.init(op: op, type:  TypeBase.boolType())
        //TODO: Add type checking
        if (expr1.type == expr2.type) {

        }
    }
}

class Call: Expression {
    var id: Identifier
    var args: [Expression]

    init(id: Identifier, args: [Expression]) {
        self.id = id
        self.args = args
        super.init(op: id.op, type: id.type)
    }
}

