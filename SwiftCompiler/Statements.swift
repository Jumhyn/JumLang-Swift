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

    init(stmt: Statement) {
        self.stmt1 = stmt
    }

    init(stmt1: Statement, stmt2: Statement) {
        self.stmt1 = stmt1
        self.stmt2 = stmt2
    }

    init(stmt1: Statement, stmt2Opt: Statement?) {
        self.stmt1 = stmt1
        self.stmt2 = stmt2Opt
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

class If: Statement {
    var expr: Logical
    var stmt: Statement
    var elseStmt: Statement?

    init(expr: Logical, stmt: Statement) {
        self.expr = expr
        self.stmt = stmt
    }

    init(expr: Logical, stmt: Statement, elseStmt: Statement) {
        self.expr = expr
        self.stmt = stmt
        self.elseStmt = elseStmt
    }

    override func generateLLVMWithGenerator(gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        let label = gen.reserveLabel()
        if let elseStmtUnwrapped = elseStmt {
            let elseLabel = gen.reserveLabel()
            expr.generateLLVMBranchesWithGenerator(gen, trueLabel: label, falseLabel: elseLabel)
            gen.appendLabel(label)
            stmt.generateLLVMWithGenerator(gen, beforeLabel: label, afterLabel: after)
            gen.appendInstruction("br label %\(after)")
            gen.appendLabel(elseLabel)
            elseStmtUnwrapped.generateLLVMWithGenerator(gen, beforeLabel: elseLabel, afterLabel: after)
        }
        else {
            expr.generateLLVMBranchesWithGenerator(gen, trueLabel: label, falseLabel: after)
            gen.appendLabel(label)
            stmt.generateLLVMWithGenerator(gen, beforeLabel: label, afterLabel: after)
        }
    }

    override func needsAfterLabel() -> Bool {
        return true
    }
}

class While: Statement {
    var expr: Logical
    var stmt: Statement

    init(expr: Logical, stmt: Statement) {
        self.expr = expr
        self.stmt = stmt
    }

    override func generateLLVMWithGenerator(gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        let label = gen.reserveLabel()
        expr.generateLLVMBranchesWithGenerator(gen, trueLabel: label, falseLabel: after)
        gen.appendLabel(label)
        stmt.generateLLVMWithGenerator(gen, beforeLabel: label, afterLabel: after)
        gen.appendInstruction("br label %\(before)")
    }

    override func needsBeforeLabel() -> Bool {
        return true
    }

    override func needsAfterLabel() -> Bool {
        return true
    }
}

class DoWhile: Statement {
    var stmt: Statement
    var expr: Logical

    init(stmt: Statement, expr: Logical) {
        self.stmt = stmt
        self.expr = expr
    }

    override func generateLLVMWithGenerator(gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        var label = gen.reserveLabel()
        stmt.generateLLVMWithGenerator(gen, beforeLabel: before, afterLabel: label)
        gen.appendLabel(label)
        expr.generateLLVMBranchesWithGenerator(gen, trueLabel: before, falseLabel: after)
    }

    override func needsBeforeLabel() -> Bool {
        return true
    }

    override func needsAfterLabel() -> Bool {
        return true
    }
}

class Assignment: Statement {
    var id: Identifier
    var expr: Expression

    init(id: Identifier, expr: Expression) {
        self.id = id
        self.expr = expr
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

    init(from: Prototype) {
        self.from = from
    }

    init(expr: Expression, from: Prototype) {
        self.expr = expr
        self.from = from
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

    init(expr: Expression) {
        self.expr = expr
    }

    override func generateLLVMWithGenerator(gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        expr.reduceWithGenerator(gen)
    }
}