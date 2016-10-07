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

    override func generateLLVM(with gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        let label = gen.reserveLabel()
        if let elseStmt = elseStmt {
            let elseLabel = gen.reserveLabel()
            expr.generateLLVMBranches(with: gen, trueLabel: label, falseLabel: elseLabel)
            gen.append(label)
            stmt.generateLLVM(with: gen, beforeLabel: label, afterLabel: after)
            gen.append("br label %L\(after)")
            gen.append(elseLabel)
            elseStmt.generateLLVM(with: gen, beforeLabel: elseLabel, afterLabel: after)
            gen.append("br label %L\(after)")
        }
        else {
            expr.generateLLVMBranches(with: gen, trueLabel: label, falseLabel: after)
            gen.append(label)
            stmt.generateLLVM(with: gen, beforeLabel: label, afterLabel: after)
            gen.append("br label %L\(after)")
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

    override func generateLLVM(with gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        let label = gen.reserveLabel()
        expr.generateLLVMBranches(with: gen, trueLabel: label, falseLabel: after)
        gen.append(label)
        stmt.generateLLVM(with: gen, beforeLabel: label, afterLabel: after)
        gen.append("br label %L\(before)")
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

    override func generateLLVM(with gen: Generator, beforeLabel before: Label, afterLabel after: Label) {
        let label = gen.reserveLabel()
        stmt.generateLLVM(with: gen, beforeLabel: before, afterLabel: label)
        gen.append(label)
        expr.generateLLVMBranches(with: gen, trueLabel: before, falseLabel: after)
    }

    override func needsBeforeLabel() -> Bool {
        return true
    }

    override func needsAfterLabel() -> Bool {
        return true
    }
}
