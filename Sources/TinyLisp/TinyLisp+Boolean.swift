extension Expr: Equatable {
    static func == (lhs: Expr, rhs: Expr) -> Bool {
        switch (lhs, rhs) {
        case (.atom(let lhs), .atom(let rhs)):  return lhs == rhs
        case (.list(let lhs), .list(let rhs)):  return lhs == rhs
        default:                                return false
        }
    }
}

extension Expr: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: BooleanLiteralType) {
        self = .atom(value == false ? "nil" : "T") // only place that defines which Expr represent true and false
    }
}

extension Expr {
    static func `if`(_ arguments: ArraySlice<Expr>, _ context: inout Environment) throws -> Expr {
        guard
            let conditionExpr = arguments.first,
            let thenExpr =      arguments.dropFirst().first
        else {
            throw InterpretationError(message: "'if': argument mismatch")
        }
        let elseExpr = arguments.dropFirst(2).first

        let condition = try conditionExpr.eval(in: &context)
        if condition == false { // possible through ExpressibleByBooleanLiteral conformance
            guard let elseExpr = elseExpr else { return false } // else is optional
            return try elseExpr.eval(in: &context)
        } else {
            return try thenExpr.eval(in: &context)
        }
    }

    static func eq(_ arguments: ArraySlice<Expr>) throws -> Expr {
        let (lhs, rhs) = (arguments.first!, arguments.dropFirst().first!)
        return lhs == rhs ? true : false
    }

    static func atom(_ arguments: ArraySlice<Expr>) throws -> Expr {
        if case .atom = arguments.first! { return true } else { return false }
    }
}

struct LispBoolean: Lisp {
    var environment: Expr<Atom>.Environment = [:]

    static var booleanEnvironment: Expr<AtomType>.Environment = [
        "if": .function(.specialForm(Expr.if(_:_:))),
        "eq": .function(.builtIn(Expr.eq(_:))),
        "atom": .function(.builtIn(Expr.atom(_:))),
    ]

    init() {
        environment = LispMinimal.basicEnvironment()
        environment.merge(Self.booleanEnvironment) { a, b in a }
    }
}
