//
//  Statements.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

class Statement: Node {
    func generateLLVMWithGenerator(gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        
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

    override func generateLLVMWithGenerator(gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        if let stmt2Unwrapped = stmt2 {
            let between = gen.reserveLabel()
            stmt1.generateLLVMWithGenerator(gen, beforeLabel: before, afterLabel: between)
            if stmt1.needsAfterLabel() || stmt2Unwrapped.needsBeforeLabel() {
                gen.appendLabel(between)
            }
            stmt2Unwrapped.generateLLVMWithGenerator(gen, beforeLabel: between, afterLabel: after)
        }
        else {
            stmt1.generateLLVMWithGenerator(gen, beforeLabel: before, afterLabel: after)
        }
    }

    override func needsBeforeLabel() -> Bool {
        return stmt1.needsBeforeLabel()
    }

    override func needsAfterLabel() -> Bool {
        if let stmt2Unwrapped = stmt2 {
            return stmt2Unwrapped.needsAfterLabel()
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

    override func generateLLVMWithGenerator(gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        if !id.allocated {
            gen.appendInstruction("\(id.LLVMString()) = alloca \(id.type.LLVMString())")
            id.allocated = true
        }
        let reduced = expr.convertTo(id.type, withGenerator: gen)
        gen.appendInstruction("store \(reduced.type.LLVMString()) \(reduced.LLVMString()), \(id.type.LLVMString())* \(id.LLVMString())")
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

    override func generateLLVMWithGenerator(gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        if let exprUnwrapped = expr {
            let reduced = exprUnwrapped.convertTo(from.id.type, withGenerator: gen)
            gen.appendInstruction("ret \(reduced.type.LLVMString()) \(reduced.LLVMString())")
        }
        else {
            gen.appendInstruction("ret void")
        }
    }
}

class Expratement: Statement {
    var expr: Expression

    init(expr: Expression, line: UInt) {
        self.expr = expr
        super.init(line: line)
    }

    override func generateLLVMWithGenerator(gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        expr.reduceWithGenerator(gen)
    }
}