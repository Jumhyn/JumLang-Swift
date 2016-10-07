//
//  Statements.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

class Statement: Node {
    func generateLLVM(with gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        
    }

    func needsBeforeLabel() -> Bool {
        return false
    }

    func needsAfterLabel() -> Bool {
        return false
    }
}

class Sequence: Statement {
    var stmt1: Statement
    var stmt2: Statement? = nil

    init(stmt: Statement, line: UInt) {
        self.stmt1 = stmt
        super.init(line: line)
    }

    init(stmt1: Statement, stmt2: Statement, line: UInt) {
        self.stmt1 = stmt1
        self.stmt2 = stmt2
        super.init(line: line)
    }

    init(stmt1: Statement, stmt2Opt: Statement?, line: UInt) {
        self.stmt1 = stmt1
        self.stmt2 = stmt2Opt
        super.init(line: line)
    }

    override func generateLLVM(with gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        if let stmt2 = stmt2 {
            let between = gen.reserveLabel()
            stmt1.generateLLVM(with: gen, beforeLabel: before, afterLabel: between)
            if stmt1.needsAfterLabel() || stmt2.needsBeforeLabel() {
                gen.append(between)
            }
            stmt2.generateLLVM(with: gen, beforeLabel: between, afterLabel: after)
        }
        else {
            stmt1.generateLLVM(with: gen, beforeLabel: before, afterLabel: after)
        }
    }

    override func needsBeforeLabel() -> Bool {
        return stmt1.needsBeforeLabel()
    }

    override func needsAfterLabel() -> Bool {
        if let stmt2 = stmt2 {
            return stmt2.needsAfterLabel()
        }
        return stmt1.needsAfterLabel()
    }
}

class Assignment: Statement {
    var id: Identifier
    var expr: Expression

    init(id: Identifier, expr: Expression, line: UInt) {
        self.id = id
        self.expr = expr
        super.init(line: line)
    }

    override func generateLLVM(with gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        let reduced = expr.convert(to: id.type, with: gen)
        gen.append("store \(reduced.type) \(reduced), \(id.type)* \(id.getPointer(with: gen))")
    }
}

class Return: Statement {
    var expr: Expression? = nil
    var from: Prototype

    init(from: Prototype, line: UInt) {
        self.from = from
        super.init(line: line)
    }

    init(expr: Expression, from: Prototype, line: UInt) {
        self.expr = expr
        self.from = from
        super.init(line: line)
    }

    override func generateLLVM(with gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        if let expr = expr {
            let reduced = expr.convert(to: from.id.type, with: gen)
            gen.append("ret \(reduced.type) \(reduced)")
        }
        else {
            gen.append("ret void")
        }
    }
}

class Expratement: Statement {
    var expr: Expression

    init(expr: Expression, line: UInt) {
        self.expr = expr
        super.init(line: line)
    }

    override func generateLLVM(with gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        _ = expr.reduce(with: gen)
    }
}
