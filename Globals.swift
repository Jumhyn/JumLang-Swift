//
//  Globals.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

@noreturn func error(err: String, line: UInt) {
    fatalError("\(err) near line \(line)")
}

func <(lhs: String.Index, rhs: String.Index) -> Bool {
    return distance(lhs, rhs) > 0
}

func >(lhs: String.Index, rhs: String.Index) -> Bool {
    return distance(lhs, rhs) < 0
}

func ^(lhs: Double, rhs: Double) -> Double {
    return pow(lhs, rhs)
}

protocol LLVMPrintable: Streamable {
    func LLVMString() -> String
}