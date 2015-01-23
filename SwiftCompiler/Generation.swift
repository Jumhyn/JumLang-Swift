//
//  Generator.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/17/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

typealias Label = UInt

@objc class Generator {
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
        if !betweenBlocks {
            output.extendLn("br label %L\(label)")
        }
        output.extendLn("%L\(label):")
    }

    func appendInstruction(code: String) {
        if code.endsBasicBlock() {
            betweenBlocks = true
        }
        else {
            betweenBlocks = false
        }
        output.extendLn(code)
    }

    func generateLLVMForProgram(program: [Function]) {
        for function in program {
            function.generateLLVMWithGenerator(self)
        }
    }
}