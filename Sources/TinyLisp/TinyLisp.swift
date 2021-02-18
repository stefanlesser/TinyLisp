enum Expr {
    case atom(String)
    indirect case list([Expr])
    case function(Function)
}

typealias Environment = [String: Expr]
typealias Function = ([Expr], Environment) -> Expr

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
    private func apply(function name: String, with arguments: [Expr], in context: Environment) -> Expr {
        switch context[name] {
        case .function(let function): // it's a built-in function
            return function(arguments, context)
        case .list(let list): // it's a lambda to be evaluated
            switch (list.first, list.dropFirst().first, list.dropFirst().dropFirst().first) {
            case (.atom("lambda"), .list(let argumentExpressions), let functionBody?):
                var newContext: Environment = context
                for (symbol, value) in zip(argumentExpressions, arguments) {
                    guard case .atom(let name) = symbol
                    else { fatalError("Argument is not a symbol") }
                    newContext[name] = value
                }
                return functionBody.eval(in: &newContext)
            default:
                fatalError("Called apply with unexpected value")
            }
        case .atom(_):
            fatalError("'\(name)' is not executable")
        case .none:
            fatalError("Undefined symbol: \(name)")
        }
    }
    
    func eval(in context: inout Environment) -> Expr {
        switch self {
        case .atom(let symbol):
            return context[symbol] ?? self // lookup value or pass expression back unchanged
        case .list(let list):
            switch (list.first, list.dropFirst()) {
            case (.none, _): // empty list (aka nil)
                return self
            case (.atom(let name), let rest): // function call
                switch name {
                case "quote":
                    return rest.first!
                case "if":
                    guard
                        let conditionExpr = rest.first,
                        let thenExpr = rest.dropFirst().first
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
                case "label":
                    guard
                        case .atom(let name) = rest.first,
                        let valueExpression = rest.dropFirst().first
                    else {
                        fatalError("'label': argument mismatch")
                    }
                    
                    let value = valueExpression.eval(in: &context)
                    context[name] = value
                    return value
                default:
                    let argumentValues = rest.map { $0.eval(in: &context) }
                    return apply(function: name, with: argumentValues, in: context)
                }
            case (.function, _), (.list, _):
                fatalError("First item in list is not a symbol")
            }
        case .function:
            fatalError("Didn't expect a function here")
        }
    }
}

class Lisp {
    var environment: Environment = [
        "car": .function { args, context in
            guard case .list(let list) = args.first else { fatalError() }
            return list.first!
        },
        "cdr": .function { args, context in
            guard case .list(let list) = args.first else { fatalError() }
            return .list(Array(list.dropFirst()))
        },
        "cons": .function { args, context in
            let (element, listExpr) = (args.first!, args.dropFirst().first!)
            guard case .list(let list) = listExpr else { fatalError() }
            return .list([element] + list)
        },
        "eq": .function { args, context in
            let (lhs, rhs) = (args.first!, args.dropFirst().first!)
            return lhs == rhs ? .atom("T") : .list([])
        },
        "atom": .function { args, context in
            if case .atom = args.first! { return .atom("T") } else { return .list([]) }
        },
    ]
    
    func eval(_ expression: Expr) -> Expr {
        return expression.eval(in: &environment)
    }
}
