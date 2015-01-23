//
//  Function.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

class Prototype {
    var id: Identifier
    var args: [Identifier]

    init(_ id: Identifier, _ args: [Identifier]) {
        self.id = id
        self.args = args
    }
}

class Function : Node {
    var signature: Prototype
    var body: Statement

    init(signature: Prototype, body: Statement, line: UInt) {
        self.signature = signature
        self.body = body
        super.init(line: line)
    }

    override func generateLLVMWithGenerator(gen: Generator) {
        var signatureString = "define \(self.signature.id.type.LLVMString()) \(self.signature.id.LLVMString()) ("
        for arg in signature.args {
            signatureString.extend("\(arg.type.LLVMString()) %\(arg.op.LLVMString())")
            if find(signature.args, arg) < signature.args.count {
                signatureString.extend(",")
            }
        }
        signatureString.extend(") {")
        gen.appendInstruction(signatureString)

        var before = gen.reserveLabel(), after = gen.reserveLabel()
        if body.needsBeforeLabel() {
            gen.appendLabel(before)
        }
        body.generateLLVMWithGenerator(gen, beforeLabel: before, afterLabel: after)
        if body.needsAfterLabel() {
            gen.appendLabel(after)
        }
        gen.appendInstruction("}")
    }
}