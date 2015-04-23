//
//  Parser.swift
//  SwiftCompiler
//
//  Created by Freddy Kellison-Linn on 8/22/14.
//  Copyright (c) 2014 Jumhyn. All rights reserved.
//

import Foundation

class Parser {
    var lexer: Lexer

    var lookahead: Token
    var globalScope: Scope
    var topScope: Scope
    weak var currentFunc: Prototype! = nil

    init(lexer: Lexer) {
        self.lexer = lexer
        self.lookahead = lexer.nextToken()
        self.globalScope = Scope()
        self.topScope = self.globalScope
    }

    func program() -> [Function] {
        //a program is an array of functions
        var ret: [Function] = []
        while (lookahead == .LBrack) {
            ret.append(self.function())
        }
        return ret
    }

    func function() -> Function {
        let savedScope = topScope
        topScope = Scope(previousScope: savedScope, globalScope: globalScope)
        let proto = self.prototype()
        currentFunc = proto
        globalScope.setPrototype(proto, forToken: proto.id.op)
        self.match(.LBrace)
        if let stmt = self.sequence() {
            self.match(.RBrace)
            topScope = savedScope
            return Function(signature: proto, body: stmt, line: lexer.line)
        }
        error("expected statement", lexer.line)
    }

    func prototype() -> Prototype {
        self.match(.LBrack)
        //get the return type of the function
        let funcType = self.type()

        //get the identifier
        let funcIdTok = lookahead
        self.match(.Identifier(nil))

        var args: [Identifier] = []
        //if there are arguments, get them
        if lookahead == .Colon {
            self.match(.Colon)
            do {
                let varType = self.type()
                let varIdTok = lookahead
                self.match(.Identifier(nil))

                let id = Identifier(op: varIdTok, type: varType, line: lexer.line)
                id.isArgument = true
                args.append(id)
                topScope.setIdentifier(id, forToken: varIdTok)

                //if we are done, exit the loop
                if lookahead == .RBrack {
                    break
                }
                //otherwise, match a comma and possibly exit
                self.match(.Comma)
            } while (lookahead == .Type(nil))
        }
        self.match(.RBrack)

        //create the identifier for the function and return the prototype
        let funcId = Identifier(op: funcIdTok, type: funcType, line: lexer.line)
        funcId.isGlobal = true
        return Prototype(id: funcId, args: args, line: lexer.line)
    }

    func type() -> TypeBase {
        //match a type token and return the corresponding type
        switch lookahead {
        case .Type(let type):
            var ret = type!
            self.match(.Type(nil))
            if lookahead == .LBrack {
                self.match(.LBrack)
                arraySizeLoop: while lookahead != .RBrack {
                    switch lookahead {
                    case .Integer(let val):
                        self.match(.Integer(nil))
                        ret = ArrayType(numElements: UInt(val!), to: ret)
                        if lookahead == .RBrack {
                            self.match(.RBrack)
                            break arraySizeLoop
                        }
                        self.match(.Comma)
                    case .Comma:
                        self.match(.Comma)
                        ret = ArrayType(numElements: 0, to: ret)
                    case .RBrack:
                        self.match(.RBrack)
                        ret = ArrayType(numElements: 0, to: ret)
                        break arraySizeLoop
                    default:
                        error("expected array type declaration", lexer.line)
                    }
                }
            }
            return ret
        default:
            error("expected type", lexer.line)
        }
    }

    func match(token: Token) {
        //match a specific token
        if token == lookahead || token == .Any {
            lookahead = lexer.nextToken()
        }
        else {
            error("expected '\(token)' but found '\(lookahead)'", lexer.line)
        }
    }

    func match(tokens: Token ...) {
        //match any one of multiple tokens
        if (contains(tokens, lookahead) || contains(tokens, .Any)) {
            lookahead = lexer.nextToken()
        }
        else {
            error("expected \(tokens) instead of \(lookahead)", lexer.line)
        }
    }

}

//MARK: - Statements
extension Parser {
    func statement() -> Statement {
        switch lookahead {
        case .If:
            return self.ifStatement()
        case .While:
            return self.whileStatement()
        case .Do:
            return self.doWhileStatement()
        case .Return:
            return self.returnStatement()
        case .Type(_):
            return self.declaration()
        case .LBrack:
            //the beginning of a call
            let expr = self.callExpression()
            return Expratement(expr: expr, line: lexer.line)
        case .LBrace:
            return self.block()
        default:
            return self.assignment()
        }
    }

    func declaration() -> Statement {
        //a type indicates either a array or variable declaration
        let type = self.type()
        if type is ArrayType {
            return self.arrayDeclaration(type as! ArrayType)
        }
        else {
            return self.variableDeclaration(type)
        }
    }

    func variableDeclaration(type: TypeBase) -> Statement {
        let idTok = lookahead
        self.match(.Identifier(nil))
        let id = Identifier(op: idTok, type: type, line: lexer.line)
        id.enclosingFuncName = currentFunc.id.op.LLVMString()
        id.scopeNumber = globalScope.scopeCount
        topScope.setIdentifier(id, forToken: idTok)

        switch lookahead {
        case .Semi:
            self.match(.Semi)
            return self.statement()
        case .Assign:
            self.match(.Assign)
            let expr = self.orExpression()
            self.match(.Semi)
            return Assignment(id: id, expr: expr, line: lexer.line)
        default:
            error("expected variable declaration", lexer.line)
        }
    }

    func arrayDeclaration(type: ArrayType) -> Statement {
        let idTok = lookahead
        self.match(.Identifier(nil))
        let id = Identifier(op: idTok, type: type, line: lexer.line)
        id.enclosingFuncName = currentFunc.id.op.LLVMString()
        id.scopeNumber = globalScope.scopeCount
        topScope.setIdentifier(id, forToken: idTok)
        if lookahead == .Assign {
            self.match(.Assign)
            let expr = self.arrayLiteral()
            let numElements = (expr.type as! ArrayType).numElements
            if type.numElements !=  numElements {
                error("array literal and declaration must agree in number of elements", lexer.line)
            }
            self.match(.Semi)
            return Assignment(id: id, expr: expr, line: lexer.line)
        }
        else if type.numElements == 0 {
            self.match(.Assign)
            let expr = self.arrayLiteral()
            type.numElements = (expr.type as! ArrayType).numElements
            self.match(.Semi)
            return Assignment(id: id, expr: expr, line: lexer.line)
        }
        else {
            self.match(.Semi)
            return Assignment(id: id, expr: type.defaultConstant(), line: lexer.line)
        }
    }

    func block() -> Statement {
        //a block is just a sequence with its own scope
        self.match(.LBrace)

        //save the current scope and create a new one
        topScope = Scope(previousScope: topScope, globalScope: globalScope)
        if let stmt = self.sequence() {
            self.match(.RBrace)

            //restore the scope
            topScope = topScope.previousScope!
            return stmt
        }
        error("expected statement", lexer.line)
    }

    func sequence() -> Statement? {
        if lookahead == .RBrace {
            return nil
        }
        else {
            return Sequence(stmt1: self.statement(), stmt2Opt: self.sequence(), line: lexer.line)
        }
    }

    func ifStatement() -> If {
        self.match(.If)
        let expr = self.expression()
        if !(expr is Logical) {
            error("expected expression with boolean result", lexer.line)
        }
        let stmt = self.statement()
        if self.lookahead == .Else {
            self.match(.Else)
            return If(expr: expr as! Logical, stmt: stmt, elseStmt: self.statement(), line: lexer.line)
        }
        return If(expr: expr as! Logical, stmt: stmt, line: lexer.line)
    }

    func whileStatement() -> While {
        self.match(.While)
        let expr = self.expression()
        if !(expr is Logical) {
            error("expected expression with boolean result", lexer.line)
        }
        return While(expr: expr as! Logical, stmt: self.statement(), line: lexer.line)
    }

    func doWhileStatement() -> DoWhile {
        self.match(.Do)
        let stmt = self.statement()
        self.match(.While)
        let expr = self.expression()
        if !(expr is Logical) {
            error("expected expression with boolean result", lexer.line)
        }
        self.match(.Semi)
        return DoWhile(stmt: stmt, expr: expr as! Logical, line: lexer.line)
    }

    func returnStatement() -> Return {
        self.match(.Return)
        if lookahead == .Semi {
            self.match(.Semi)
            return Return(from: currentFunc, line: lexer.line)
        }
        if currentFunc.id.type == TypeBase.voidType() {
            error("returning value from void function", lexer.line)
        }
        let expr = self.orExpression()
        self.match(.Semi)
        return Return(expr: expr, from: currentFunc, line: lexer.line)
    }

    func assignment() -> Assignment {
        let id = self.identifier()
        self.match(.Assign)
        let stmt = Assignment(id: id, expr: self.orExpression(), line: lexer.line)
        self.match(.Semi)
        return stmt
    }
}

//MARK: - Expressions

extension Parser {
    func expression() -> Expression {
        switch lookahead {
        case .LParen:
            self.match(.LParen)
            let expr = self.orExpression()
            self.match(.RParen)
            return expr
        case .Integer(_),.Decimal(_),.Boolean(_):
            return self.constantExpression()
        case .LBrack:
            return self.callExpression()
        case .Identifier(_):
            return self.identifier()
        default:
            error("expected expression", lexer.line)
        }
    }

    func orExpression() -> Expression {
        var lhs = self.andExpression()
        while lookahead == .Or {
            self.match(.Or)
            let rhs = self.andExpression()
            if !(lhs is Logical && rhs is Logical) {
                error("expected expression with boolean result", lexer.line)
            }
            lhs = Or(expr1: lhs as! Logical, expr2: rhs as! Logical, line: lexer.line)
        }
        return lhs
    }

    func andExpression() -> Expression {
        var lhs = self.equalityExpression()
        while lookahead == .And {
            self.match(.And)
            let rhs = self.equalityExpression()
            if !(lhs is Logical && rhs is Logical) {
                error("expected expression with boolean result", lexer.line)
            }
            lhs = And(expr1: lhs as! Logical, expr2: rhs as! Logical, line: lexer.line)
        }
        return lhs
    }

    func equalityExpression() -> Expression {
        var lhs = self.inequalityExpression()
        while lookahead == .Equal || lookahead == .NEqual {
            let op = lookahead
            self.match(.Equal, .NEqual)
            let rhs = self.inequalityExpression()
            lhs = Relation(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func inequalityExpression() -> Expression {
        var lhs = self.additionExpression()
        while lookahead == .Less || lookahead == .LEqual || lookahead == .Greater || lookahead == .GEqual {
            let op = lookahead
            self.match(.Less, .LEqual, .Greater, .GEqual)
            let rhs = self.additionExpression()
            lhs = Relation(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func additionExpression() -> Expression {
        var lhs = self.multiplicationExpression()
        while lookahead == .Plus || lookahead == .Minus {
            let op = lookahead
            self.match(.Plus, .Minus)
            let rhs = self.multiplicationExpression()
            lhs = Arithmetic(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func multiplicationExpression() -> Expression {
        var lhs = self.unaryExpression()
        while lookahead == .Times || lookahead == .Divide {
            let op = lookahead
            self.match(.Times, .Divide)
            let rhs = self.unaryExpression()
            lhs = Arithmetic(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func unaryExpression() -> Expression {
        if lookahead == .Minus {
            self.match(.Minus)
            switch lookahead {
            case .Integer(let val):
                return Constant(intVal: -val!, line: lexer.line)
            case .Decimal(let val):
                return Constant(floatVal: -val!, line: lexer.line)
            default:
                let expr = self.unaryExpression()
                if expr is Unary && expr.op == .Minus {
                    return (expr as! Unary).expr
                }
                return Unary(op: .Minus, expr: expr, line: lexer.line)
            }
        }
        else if lookahead == .Not {
            self.match(.Not)
            let expr = self.unaryExpression()
            if !(expr is Logical) {
                error("expected expression with boolean result", lexer.line)
            }
            return Not(op: .Not, expr: expr as! Logical, line: lexer.line)
        }
        else {
            return self.expression()
        }
    }

    func callExpression() -> Expression {
        self.match(.LBrack)
        let idTok = lookahead
        let id = self.identifier()
        var args: [Expression] = []
        let signature = globalScope.prototypeForToken(idTok)
        if signature.args.count > 0 {
            self.match(.Colon)
            while (true) {
                let expr = self.orExpression()
                args.append(expr)
                if lookahead == .RBrack {
                    break
                }
                self.match(.Comma)
            }
        }
        self.match(.RBrack)
        return Call(id: id, args: args, signature: signature, line: lexer.line)
    }

    func identifier() -> Identifier {
        var id = topScope.identifierForToken(lookahead)
        self.match(.Identifier(nil))
        var exprStack: [Expression] = []
        if lookahead == .LBrack {
            self.match(.LBrack)
            while lookahead != .RBrack {
                let expr = self.orExpression()
                if !expr.type.numeric || expr.type.floatingPoint {
                    error("expected numeric expression for array index", lexer.line)
                }
                exprStack.append(expr)
                if lookahead == .RBrack {
                    self.match(.RBrack)
                    break
                }
                self.match(.Comma)
            }
            while exprStack.count > 0 {
                id = ArrayAccess(indexExpr: exprStack.removeLast(), arrayId: id, line: lexer.line)
            }
        }
        return id
    }

    func constantExpression() -> Constant {
        switch lookahead {
        case .Integer(let val):
            self.match(.Integer(nil))
            return Constant(intVal: val!, line: lexer.line)
        case .Decimal(let val):
            self.match(.Decimal(nil))
            return Constant(floatVal: val!, line: lexer.line)
        case .Boolean(let val):
            self.match(.Boolean(nil))
            return BooleanConstant(boolVal: val!, line: lexer.line)
        case .LBrack:
            return self.arrayLiteral()
        default:
            error("expected constant", lexer.line)
        }
    }

    func arrayLiteral() -> ArrayLiteral {
        self.match(.LBrack)
        var values: [Constant] = []
        while true {
            let const = self.constantExpression()
            values.append(const)
            if lookahead != .Comma {
                break
            }
            self.match(.Comma)
        }
        self.match(.RBrack)
        return ArrayLiteral(values: values, line: lexer.line)
    }
}