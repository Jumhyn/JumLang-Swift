//
//  Generator.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/17/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

typealias Label = UInt

class Generator {
    var currentLabel: Label = 1
    var tempCount: UInt = 1
    var output = ""
    var betweenBlocks = false

    func reserveLabel() -> Label {
        return currentLabel++
    }

    func getTemporaryOfType(type: TypeBase) -> Temporary {
        return Temporary(number: tempCount++, type: type, line: 0)
    }

    func appendLabel(label: Label) {
        output.extendLn("L\(label):")
    }

    func appendInstruction(code: String) {
        output.extendLn(code)
    }

    func generateLLVMForProgram(program: Program) {
        for type in program.globalScope.typeTable.values {
            self.appendInstruction("\(type.LLVMString()) = \(type.LLVMLongString())")
        }
        for function in program.funcs {
            function.generateLLVMWithGenerator(self)
        }
    }
}