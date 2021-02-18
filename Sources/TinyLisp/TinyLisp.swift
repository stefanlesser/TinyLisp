enum Expr {
    case atom(String)
    indirect case list([Expr])
    case function(Function)
}

typealias Environment = [String: Expr]
typealias Function = ([Expr]) -> Expr

extension Expr: Equatable {
    static func == (lhs: Expr, rhs: Expr) -> Bool {
        switch (lhs, rhs) {
        case (.atom(let lhs), .atom(let rhs)):  return lhs == rhs
        case (.list(let lhs), .list(let rhs)):  return lhs == rhs
        default:                                return false
        }
    }
}

extension Expr: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .atom(value)
    }
}

extension Expr: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Expr...) {
        self = .list(elements)
    }
}

extension Expr {
    private func apply(_ name: String, _ argumentExpressions: [Expr], _ context: inout Environment) -> Expr {
        let argumentValues = argumentExpressions.map { $0.eval(in: &context) }
        switch context[name] {
        case .function(let function):   return function(argumentValues) // it's a built-in function
        case .list(let list):           return lambda(list, argumentValues, context) // it's a lambda to be evaluated
        case .atom:                     fatalError("'\(name)' is not executable")
        case .none:                     fatalError("Undefined symbol: \(name)")
        }
    }

    func eval(in context: inout Environment) -> Expr {
        switch self {
        case .atom(let symbol):
            return context[symbol] ?? self // lookup value or pass expression back unchanged
        case .list(let list):
            switch (list.first, list.dropFirst()) {
            case (.none, _):                        return self // empty list (aka nil)
            case (.atom("quote"), let arguments):   return arguments.first! // quote must not eval rest
            case (.atom("if"), let arguments):      return `if`(Array(arguments), &context)
            case (.atom("label"), let arguments):   return label(Array(arguments), &context)
            case (.atom(let name), let arguments):  return apply(name, Array(arguments), &context) // function call
            case (.list, _),
                 (.function, _):                    fatalError("First item in list is not a symbol")
            }
        case .function:
            fatalError("Didn't expect a function here")
        }
    }
}

extension Expr { // Special forms
    private func lambda(_ list: [Expr], _ arguments: [Expr], _ context: Environment) -> Expr {
        guard
            case .atom("lambda")                = list.first,
            case .list(let argumentExpressions) = list.dropFirst().first,
            let functionBody                    = list.dropFirst(2).first
        else {
            fatalError("Called apply with unexpected value")
        }

        var newContext: Environment = context
        for (symbol, value) in zip(argumentExpressions, arguments) {
            guard case .atom(let name) = symbol else { fatalError("Argument is not a symbol") }
            newContext[name] = value
        }
        return functionBody.eval(in: &newContext)
    }

    private func `if`(_ rest: [Expr], _ context: inout Environment) -> Expr {
        guard
            let conditionExpr = rest.first,
            let thenExpr =      rest.dropFirst().first
        else {
            fatalError("'if': argument mismatch")
        }
        let elseExpr = rest.dropFirst(2).first

        let condition = conditionExpr.eval(in: &context)
        if case .list([]) = condition { // condition is false (empty list represents nil)
            guard let elseExpr = elseExpr else { return .list([]) } // else is optional
            return elseExpr.eval(in: &context)
        } else {
            return thenExpr.eval(in: &context)
        }
    }

    private func label(_ rest: [Expr], _ context: inout Environment) -> Expr {
        guard
            case .atom(let name) =  rest.first,
            let valueExpression =   rest.dropFirst().first
        else {
            fatalError("'label': argument mismatch")
        }

        let value = valueExpression.eval(in: &context)
        context[name] = value
        return value
    }
}

struct Lisp {
    var environment: Environment = [
        "car": .function { args in
            guard case .list(let list) = args.first else { fatalError() }
            return list.first!
        },
        "cdr": .function { args in
            guard case .list(let list) = args.first else { fatalError() }
            return .list(Array(list.dropFirst()))
        },
        "cons": .function { args in
            let (element, listExpr) = (args.first!, args.dropFirst().first!)
            guard case .list(let list) = listExpr else { fatalError() }
            return .list([element] + list)
        },
        "eq": .function { args in
            let (lhs, rhs) = (args.first!, args.dropFirst().first!)
            return lhs == rhs ? .atom("T") : .list([])
        },
        "atom": .function { args in
            if case .atom = args.first! { return .atom("T") } else { return .list([]) }
        }
    ]

    mutating func eval(_ expression: Expr) -> Expr {
        return expression.eval(in: &environment)
    }
}
