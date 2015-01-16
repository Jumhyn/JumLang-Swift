//
//  Globals.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 1/15/15.
//  Copyright (c) 2015 Jumhyn. All rights reserved.
//

import Foundation

func error(err: String, line: UInt) {
    println("\(err) on line \(line)")
    exit(1)
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

infix operator !^ {

}

func !^(lhs: Bool, rhs: Bool) -> Bool {
    return !(lhs ^ rhs)
}