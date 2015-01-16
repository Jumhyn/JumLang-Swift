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

    init(_ op: Token, _ type: TypeBase) {
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

class Identifier: Expression {
    var offset = 0
    var isAllocated = false
    var isArgument = false
    var isGlobal = false
    var enclosingFuncName = ""
    var scopeNumber: UInt = 0

    init(_ op: Token, _ type: TypeBase, offset: Int) {
        self.offset = offset
        super.init(op, type)
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
        super.init(op, Type_max(expr1.type, expr2.type))
    }
}

class Unary: Operator {
    var expr: Expression

    init( op: Token, expr: Expression) {
        self.expr = expr
        super.init(op, expr.type)
    }
}

class Constant: Expression {
    init(intVal val: Int) {
        super.init(.Integer(val), TypeBase.intType())
    }

    init (floatVal val: Double) {
        super.init(.Decimal(val), TypeBase.floatType())
    }
}

class Logical: Expression {
    var expr1: Expression
    var expr2: Expression

    init(op: Token, expr1: Expression, expr2: Expression) {
        self.expr1 = expr1
        self.expr2 = expr2
        super.init(op, TypeBase.boolType())
        //TODO: Add type checking
        if (expr1.type == expr2.type) {
            
        }
    }
}

class And: Logical {

}

class Or: Logical {

}

class Not: Logical {
    init(op: Token, expr: Expression) {
        super.init(op: op, expr1: expr, expr2: expr)
    }
}

class Relation: Logical {

}

class Call: Expression {
    var id: Identifier
    var args: [Expression]

    init(id: Identifier, args: [Expression]) {
        self.id = id
        self.args = args
        super.init(id.op, id.type)
    }
}

