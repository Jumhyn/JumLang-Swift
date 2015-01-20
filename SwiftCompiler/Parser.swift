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

    init(_ lexer: Lexer) {
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
            return Function(proto, stmt)
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

                let id = Identifier(op: varIdTok, type: varType, offset: 0)
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
        let funcId = Identifier(op: funcIdTok, type: funcType, offset: 0)
        funcId.isGlobal = true
        return Prototype(funcId, args)
    }

    func type() -> TypeBase {
        //match a type token and return the corresponding type
        switch lookahead {
        case .Type(let type):
            match(.Type(nil))
            return type!
        default:
            error("expected type", lexer.line)
        }
    }

    func match(token: Token) {
        //match a specific token
        if (token == lookahead || token == .Any) {
            lookahead = lexer.nextToken()
        }
        else {
            error("expected \(token) instead of \(lookahead)", lexer.line)
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
            //a type indicates either a bare declaration, or an
            //initialization
            let type = self.type()
            let idTok = lookahead
            self.match(.Identifier(nil))
            switch lookahead {
            case .Semi:
                let id = Identifier(op: idTok, type: type, offset: 0)
                id.enclosingFuncName = currentFunc.id.op.description
                id.scopeNumber = globalScope.scopeCount
                topScope.setIdentifier(id, forToken: idTok)
                self.match(.Semi)
                return self.statement()
            case .Assign:
                let id = Identifier(op: idTok, type: type, offset: 0)
                id.enclosingFuncName = currentFunc.id.op.description
                id.scopeNumber = globalScope.scopeCount
                topScope.setIdentifier(id, forToken: idTok)
                self.match(.Assign)
                let expr = self.orExpression()
                self.match(.Semi)
                return Assignment(id: id, expr: expr)
            default:
                error("expected variable declaration", lexer.line)
            }
        case .LBrack:
            //the beginning of a call
            let expr = self.callExpression()
            return Expratement(expr: expr)
        case .LBrace:
            return self.block()
        default:
            return self.assignment()
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
            return Sequence(stmt1: self.statement(), stmt2Opt: self.sequence())
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
            return If(expr: expr as Logical, stmt: stmt, elseStmt: self.statement())
        }
        return If(expr: expr as Logical, stmt: stmt)
    }

    func whileStatement() -> While {
        self.match(.While)
        let expr = self.expression()
        if !(expr is Logical) {
            error("expected expression with boolean result", lexer.line)
        }
        return While(expr: expr as Logical, stmt: self.statement())
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
        return DoWhile(stmt: stmt, expr: expr as Logical)
    }

    func returnStatement() -> Return {
        self.match(.Return)
        if lookahead == .Semi {
            self.match(.Semi)
            return Return(from: currentFunc)
        }
        if currentFunc.id.type == TypeBase.voidType() {
            error("returning value from void function", lexer.line)
        }
        let expr = self.expression()
        self.match(.Semi)
        return Return(expr: expr, from: currentFunc)
    }

    func assignment() -> Assignment {
        let id = topScope.identifierForToken(lookahead)
        self.match(.Identifier(nil))
        self.match(.Assign)
        let stmt = Assignment(id: id, expr: self.orExpression())
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
            let id = topScope.identifierForToken(lookahead)
            self.match(.Identifier(nil))
            return id
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
            lhs = Or(expr1: lhs as Logical, expr2: rhs as Logical)
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
            lhs = And(expr1: lhs as Logical, expr2: rhs as Logical)
        }
        return lhs
    }

    func equalityExpression() -> Expression {
        var lhs = self.inequalityExpression()
        while lookahead == .Equal || lookahead == .NEqual {
            let op = lookahead
            self.match(.Equal, .NEqual)
            let rhs = self.inequalityExpression()
            lhs = Relation(op: op, expr1: lhs, expr2: rhs)
        }
        return lhs
    }

    func inequalityExpression() -> Expression {
        var lhs = self.additionExpression()
        while lookahead == .Less || lookahead == .LEqual || lookahead == .Greater || lookahead == .GEqual {
            let op = lookahead
            self.match(.Less, .LEqual, .Greater, .GEqual)
            let rhs = self.additionExpression()
            lhs = Relation(op: op, expr1: lhs, expr2: rhs)
        }
        return lhs
    }

    func additionExpression() -> Expression {
        var lhs = self.multiplicationExpression()
        while lookahead == .Plus || lookahead == .Minus {
            let op = lookahead
            self.match(.Less, .LEqual, .Greater, .GEqual)
            let rhs = self.multiplicationExpression()
            lhs = Arithmetic(op: op, expr1: lhs, expr2: rhs)
        }
        return lhs
    }

    func multiplicationExpression() -> Expression {
        var lhs = self.unaryExpression()
        while lookahead == .Times || lookahead == .Divide {
            let op = lookahead
            self.match(.Times, .Divide)
            let rhs = self.unaryExpression()
            lhs = Arithmetic(op: op, expr1: lhs, expr2: rhs)
        }
        return lhs
    }

    func unaryExpression() -> Expression {
        if lookahead == .Minus {
            self.match(.Minus)
            switch lookahead {
            case .Integer(let val):
                return Constant(intVal: -val!)
            case .Decimal(let val):
                return Constant(floatVal: -val!)
            default:
                let expr = self.unaryExpression()
                if expr is Unary && expr.op == .Minus {
                    return (expr as Unary).expr
                }
                return Unary(op: .Minus, expr: expr)
            }
        }
        else if lookahead == .Not {
            self.match(.Not)
            let expr = self.unaryExpression()
            if expr is Not {
                return (expr as Not).expr
            }
            if !(expr is Logical) {
                error("expected expression with boolean result", lexer.line)
            }
            return Not(op: .Not, expr: expr as Logical)
        }
        else {
            return self.expression()
        }
    }

    func callExpression() -> Expression {
        self.match(.LBrack)
        let idTok = lookahead
        self.match(.Identifier(nil))
        let id = topScope.identifierForToken(idTok)
        var args: [Expression] = []
        if globalScope.prototypeForToken(idTok).args.count > 0 {
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
        return Call(id: id, args: args)
    }

    func constantExpression() -> Expression {
        switch lookahead {
        case .Integer(let val):
            self.match(.Integer(nil))
            return Constant(intVal: val!)
        case .Decimal(let val):
            self.match(.Decimal(nil))
            return Constant(floatVal: val!)
        case .Boolean(let val):
            self.match(.Boolean(nil))
            return BooleanConstant(boolVal: val!)
        default:
            error("expected constant", lexer.line)
        }
    }
}