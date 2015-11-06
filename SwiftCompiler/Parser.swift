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

    func program() -> Program {
        var funcs: [Function] = []
        while (lookahead == .LBrack) {
            self.match(.LBrack)
            if (lookahead == .Struct) {
                self.structure()
            }
            else {
                if let aFunc = self.function() {
                    funcs.append(aFunc)
                }
            }
        }
        let ret = Program(funcs: funcs, globalScope: globalScope)
        return ret
    }

    func structure() {
        self.match(.Struct)
        let name = lookahead
        self.match(.Identifier(nil))
        let members = self.argList()
        self.match(.RBrack)
        let type = AggregateType(members: members, name: name, line: lexer.line)
        globalScope.setType(type, forToken: name)
    }

    func function() -> Function? {
        let savedScope = topScope
        topScope = Scope(previousScope: savedScope, globalScope: globalScope)
        var proto = self.prototype()
        if let exists = globalScope.prototypeForToken(proto.id.op) {
            if exists.implemented {
                error("attempt to redefine function \(proto) declared on line \(proto.id.line)", line: lexer.line)
            }
            else {
                proto = exists
            }
        }
        else {
            globalScope.setPrototype(proto, forToken: proto.id.op)
        }

        if lookahead == .LBrace {
            self.match(.LBrace)
            currentFunc = proto
            if let stmt = self.sequence() {
                self.match(.RBrace)
                topScope = savedScope
                proto.implemented = true
                return Function(signature: proto, body: stmt, line: lexer.line)
            }
            else {
                error("expected statement", line: lexer.line)
            }
        }
        return nil
    }

    func prototype() -> Prototype {
        //get the return type of the function
        let funcType = self.type()

        //get the identifier
        let funcIdTok = lookahead
        self.match(.Identifier(nil))

        var args: [Identifier] = []
        //if there are arguments, get them
        if lookahead == .Colon {
            args = self.argList()
        }
        self.match(.RBrack)

        //create the identifier for the function and return the prototype
        let funcId = Identifier(op: funcIdTok, type: funcType, line: lexer.line)
        funcId.isGlobal = true
        return Prototype(id: funcId, args: args, line: lexer.line)
    }

    func argList() -> [Identifier] {
        var args: [Identifier] = []
        self.match(.Colon)
        repeat {
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
        return args
    }

    func type() -> TypeBase {
        //match a type token and return the corresponding type
        switch lookahead {
        case .Type(let type):
            var ret = type!
            self.match(.Type(nil))
            while lookahead == .LBrack {
                self.match(.LBrack)
                switch lookahead {
                case .Integer(let val):
                    self.match(.Integer(nil))
                    ret = ArrayType(numElements: UInt(val!), to: ret)
                    self.match(.RBrack)
                case .RBrack:
                    self.match(.RBrack)
                    ret = ArrayType(numElements: 0, to: ret)
                default:
                    error("expected array type declaration", line: lexer.line)
                }
            }
            return ret
        case .Identifier(_):
            if let type = globalScope.typeForToken(lookahead) {
                self.match(.Identifier(nil))
                return type
            }
            fallthrough
        default:
            error("expected type name", line: lexer.line)
        }
    }

    func match(token: Token) {
        //match a specific token
        if token == lookahead || token == .Any {
            lookahead = lexer.nextToken()
        }
        else {
            error("expected '\(token)' but found '\(lookahead)'", line: lexer.line)
        }
    }

    func matchOneOf(tokens: Token ...) {
        //match any one of multiple tokens
        if (tokens.contains(lookahead) || tokens.contains(.Any)) {
            lookahead = lexer.nextToken()
        }
        else {
            error("expected \(tokens) but found \(lookahead)", line: lexer.line)
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
        case .Type(_), .Identifier(_) where globalScope.typeForToken(lookahead) != nil:
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
            error("expected variable declaration", line: lexer.line)
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
            //let numElements = (expr.type as? ArrayType)?.numElements ?? error("array literal must have array type", line: lexer.line);
            if !validateArrayType(type, againstQualified: expr.type as! ArrayType) {
                error("array literal and declaration must agree in number of elements", line: lexer.line)
            }
            else {
                self.match(.Semi)
                return Assignment(id: id, expr: expr, line: lexer.line)
            }
        }
        //TODO: check that array type is fully qualified (if there is no literal)
        else {
            self.match(.Semi)
            return Assignment(id: id, expr: type.defaultConstant(), line: lexer.line)
        }
    }

    func validateArrayType(declared: ArrayType, againstQualified actual: ArrayType) -> Bool {
        if declared.numElements == 0 {
            declared.numElements = actual.numElements
        }
        if declared.numElements != actual.numElements {
            return false
        }
        else {
            if let declared = declared.to as? ArrayType, actual = actual.to as? ArrayType {
                return validateArrayType(declared, againstQualified: actual)
            }
            if actual.to.canConvertTo(declared.to) { //TODO: fix bug for converting sizes e.g. int to char
                return true
            }
            return false
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
        error("expected statement", line: lexer.line)
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
            error("expected expression with boolean result", line: lexer.line)
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
            error("expected expression with boolean result", line: lexer.line)
        }
        return While(expr: expr as! Logical, stmt: self.statement(), line: lexer.line)
    }

    func doWhileStatement() -> DoWhile {
        self.match(.Do)
        let stmt = self.statement()
        self.match(.While)
        let expr = self.expression()
        if !(expr is Logical) {
            error("expected expression with boolean result", line: lexer.line)
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
            error("returning value from void function", line: lexer.line)
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
            error("expected expression", line: lexer.line)
        }
    }

    func orExpression() -> Expression {
        var lhs = self.andExpression()
        while lookahead == .Or {
            self.match(.Or)
            let rhs = self.andExpression()
            if !(lhs is Logical && rhs is Logical) {
                error("expected expression with boolean result", line: lexer.line)
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
                error("expected expression with boolean result", line: lexer.line)
            }
            lhs = And(expr1: lhs as! Logical, expr2: rhs as! Logical, line: lexer.line)
        }
        return lhs
    }

    func equalityExpression() -> Expression {
        var lhs = self.inequalityExpression()
        while lookahead == .Equal || lookahead == .NEqual {
            let op = lookahead
            self.matchOneOf(.Equal, .NEqual)
            let rhs = self.inequalityExpression()
            lhs = Relation(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func inequalityExpression() -> Expression {
        var lhs = self.additionExpression()
        while lookahead == .Less || lookahead == .LEqual || lookahead == .Greater || lookahead == .GEqual {
            let op = lookahead
            self.matchOneOf(.Less, .LEqual, .Greater, .GEqual)
            let rhs = self.additionExpression()
            lhs = Relation(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func additionExpression() -> Expression {
        var lhs = self.multiplicationExpression()
        while lookahead == .Plus || lookahead == .Minus {
            let op = lookahead
            self.matchOneOf(.Plus, .Minus)
            let rhs = self.multiplicationExpression()
            lhs = Arithmetic(op: op, expr1: lhs, expr2: rhs, line: lexer.line)
        }
        return lhs
    }

    func multiplicationExpression() -> Expression {
        var lhs = self.unaryExpression()
        while lookahead == .Times || lookahead == .Divide {
            let op = lookahead
            self.matchOneOf(.Times, .Divide)
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
                error("expected expression with boolean result", line: lexer.line)
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
        if let signature = globalScope.prototypeForToken(idTok) {
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
        else {
            error("use of undecalred identifier \(idTok)", line: lexer.line)
        }
    }

    func identifier() -> Identifier {
        let idTok = lookahead
        if var id = topScope.identifierForToken(idTok) {
            self.match(.Identifier(nil))
            var exprStack: [Expression] = []
            while lookahead == .LBrack {
                self.match(.LBrack)
                let expr = self.orExpression()
                exprStack.append(expr)
                self.match(.RBrack)
            }
            while exprStack.count > 0 {
                if id.type is ArrayType {
                    id = ArrayAccess(indexExpr: exprStack.removeLast(), arrayId: id, line: lexer.line)
                }
                else {
                    id = MemberAccess(member: exprStack.removeFirst(), parent: id, line: lexer.line)
                }
            }
            return id
        }
        else {
            error("use of undecalred identifier \(idTok)", line: lexer.line)
        }
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
            error("expected constant", line: lexer.line)
        }
    }

    func arrayLiteral() -> ArrayLiteral {
        switch lookahead {
        case .LBrack:
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
        case .StringLiteral(let str):
            let charArray = str?.nulTerminatedUTF8 ?? []
            var values: [Constant] = []
            for c in charArray {
                values.append(Constant(intVal: Int(c), line: lexer.line))
            }
            self.match(.StringLiteral(nil))
            return ArrayLiteral(values: values, line: lexer.line)
        default:
            error("expected array or string literal", line: lexer.line)
        }
    }
}

@noreturn func error(err: String, line: UInt) {
    fatalError("near line \(line): \(err)")
}