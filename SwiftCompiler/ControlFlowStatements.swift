//
//  ControlFlowStatements.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/23/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

class If: Statement {
    var expr: Logical
    var stmt: Statement
    var elseStmt: Statement?

    init(expr: Logical, stmt: Statement, line: UInt) {
        self.expr = expr
        self.stmt = stmt
        super.init(line: line)
    }

    init(expr: Logical, stmt: Statement, elseStmt: Statement, line: UInt) {
        self.expr = expr
        self.stmt = stmt
        self.elseStmt = elseStmt
        super.init(line: line)
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

    init(expr: Logical, stmt: Statement, line: UInt) {
        self.expr = expr
        self.stmt = stmt
        super.init(line: line)
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

    init(stmt: Statement, expr: Logical, line: UInt) {
        self.stmt = stmt
        self.expr = expr
        super.init(line: line)
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