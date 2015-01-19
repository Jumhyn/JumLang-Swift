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

    init(_ signature: Prototype, _ body: Statement) {
        self.signature = signature
        self.body = body
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

        gen.appendLabel(before)
        body.generateLLVMWithGenerator(gen, beforeLabel: before, afterLabel: after)
    }
}