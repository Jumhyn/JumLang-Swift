//
//  Statements.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

class Statement: Node {

}

class Sequence: Statement {
    var stmt1: Statement
    var stmt2: Statement?

    init(stmt: Statement) {
        self.stmt1 = stmt
    }

    init(stmt1: Statement, stmt2: Statement) {
        self.stmt1 = stmt1
        self.stmt2 = stmt2
    }
}

class If: Statement {
    var expr: Expression
    var stmt: Statement
    var elseStmt: Statement?

    init(expr: Expression, stmt: Statement) {
        self.expr = expr
        self.stmt = stmt
    }

    init(expr: Expression, stmt: Statement, elseStmt: Statement) {
        self.expr = expr
        self.stmt = stmt
        self.elseStmt = elseStmt
    }
}

class While: Statement {
    var expr: Expression
    var stmt: Statement

    init(expr: Expression, stmt: Statement) {
        self.expr = expr
        self.stmt = stmt
    }
}

class DoWhile: Statement {
    var stmt: Statement
    var expr: Expression

    init(stmt: Statement, expr: Expression) {
        self.stmt = stmt
        self.expr = expr
    }
}

class Assignment: Statement {
    var id: Identifier
    var expr: Expression

    init(id: Identifier, expr: Expression) {
        self.id = id
        self.expr = expr
    }
}

class Expratement: Statement {
    var expr: Expression

    init(expr: Expression) {
        self.expr = expr
    }
}