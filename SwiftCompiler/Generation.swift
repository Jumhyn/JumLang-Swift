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
    var tempCount: UInt = 0
    var output = ""
    var betweenBlocks = false

    func reserveLabel() -> Label {
        currentLabel += 1
        return currentLabel - 1
    }

    func getTemporary(of type: TypeBase) -> Temporary {
        tempCount += 1
        return Temporary(number: tempCount, type: type, line: 0)
    }

    func append(_ label: Label) {
        output.append(line: "L\(label):")
    }

    func append(_ instruction: String) {
        output.append(line: instruction)
    }

    func generateLLVM(for program: Program) {
        for type in program.globalScope.typeTable.values {
            self.append("\(type.LLVMString()) = \(type.LLVMLongString())")
        }
        for function in program.funcs {
            if !function.signature.implemented {
                error("function \(function.signature) declared on line \(function.signature.id.line) is never defined", line: function.signature.id.line)
            }
            function.generateLLVM(with: self)
        }
    }
}
