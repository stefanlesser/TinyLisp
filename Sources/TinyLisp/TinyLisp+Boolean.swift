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

extension Lisp {
    mutating func installIfSpecialForm() {
        let specialFormsIf: [String: Expr<AtomType>.Function] =
            [
                "if": .specialForm { arguments, context in
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
                },
            ]
        environment.merge(specialFormsIf.mapValues { Expr<AtomType>.function($0) }) { a, b in a }
    }

    mutating func installIfBuiltIns() {
        let builtIns: [String: Expr<AtomType>.Function] = [
            "eq": .builtIn { args in
                let (lhs, rhs) = (args.first!, args.dropFirst().first!)
                return lhs == rhs ? true : false
            },
            "atom": .builtIn { args in
                if case .atom = args.first! { return true } else { return false }
            },
        ]
        environment.merge(builtIns.mapValues { Expr<AtomType>.function($0) }) { a, b in a }
    }
}

struct LispBoolean: Lisp {
    var environment: Expr<Atom>.Environment = [:]

    init() {
        installSpecialForms()
        installIfSpecialForm()
        installBuiltIns()
        installIfBuiltIns()
    }
}
