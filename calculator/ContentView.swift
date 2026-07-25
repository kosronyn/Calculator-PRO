import SwiftUI
import Combine
enum SubscriptionTier {
    case free
    case pro
    case ultra
}

class AppState: ObservableObject {
    @Published var currentTier: SubscriptionTier = .free
    @Published var showPaywall: Bool = false
    @Published var isLoading: Bool = true
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        ZStack {
            if appState.isLoading {
                LoadingView()
            } else {
                MainView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.isLoading = false
                }
            }
        }
    }
}

struct LoadingView: View {
    @State private var isSpinning = false
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rays")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: isSpinning)
                .onAppear { isSpinning = true }
            Text("Loading...")
                .font(.system(.headline, design: .default))
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 700, minHeight: 450)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct MainView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        ZStack {
            CalculatorView()
            if appState.showPaywall {
                PaywallView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1)
            }
        }
    }
}

struct CalculatorView: View {
    @EnvironmentObject var appState: AppState
    @State private var display = ""
    @State private var historyText = ""
    @State private var firstOperand: Double? = nil
    @State private var currentOperation: String? = nil
    @State private var waitingForOperand = false
    @State private var isRadians = true
    @State private var isShifted = false
    
    let sciColor = Color.secondary.opacity(0.1)
    let numColor = Color.secondary.opacity(0.2)
    let opColor = Color.blue
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(historyText)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(display.isEmpty ? "" : display)
                    .font(.system(size: 64, weight: .medium, design: .default))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    CalcButton("(", color: sciColor) { executeScientific("(") }
                    CalcButton(")", color: sciColor) { executeScientific(")") }
                    CalcButton("mc", color: sciColor) { executeScientific("mc") }
                    CalcButton("m+", color: sciColor) { executeScientific("m+") }
                    CalcButton("m-", color: sciColor) { executeScientific("m-") }
                    CalcButton("mr", color: sciColor) { executeScientific("mr") }
                    CalcButton("AC", color: numColor) { reset() }
                    CalcButton("+/-", color: numColor) { executeBasicFunction("+/-") }
                    CalcButton("%", color: numColor) { executeBasicFunction("%") }
                    CalcButton("÷", color: opColor) { setOperation("÷") }
                }
                GridRow {
                    CalcButton("2nd", color: isShifted ? Color.blue.opacity(0.4) : sciColor) { toggleShift() }
                    CalcButton(isShifted ? "x⁴" : "x²", color: sciColor) { executeScientific(isShifted ? "x⁴" : "x²") }
                    CalcButton(isShifted ? "∜x" : "x³", color: sciColor) { executeScientific(isShifted ? "∜x" : "x³") }
                    CalcButton("x^y", color: sciColor) { setOperation("x^y") }
                    CalcButton(isShifted ? "ln(x+1)" : "e^x", color: sciColor) { executeScientific(isShifted ? "ln(x+1)" : "e^x") }
                    CalcButton(isShifted ? "2^x" : "10^x", color: sciColor) { executeScientific(isShifted ? "2^x" : "10^x") }
                    CalcButton("7", color: numColor) { appendDigit("7") }
                    CalcButton("8", color: numColor) { appendDigit("8") }
                    CalcButton("9", color: numColor) { appendDigit("9") }
                    CalcButton("×", color: opColor) { setOperation("×") }
                }
                GridRow {
                    CalcButton("1/x", color: sciColor) { executeScientific("1/x") }
                    CalcButton("√x", color: sciColor) { executeScientific("√x") }
                    CalcButton("∛x", color: sciColor) { executeScientific("∛x") }
                    CalcButton("y√x", color: sciColor) { setOperation("y√x") }
                    CalcButton("ln", color: sciColor) { executeScientific("ln") }
                    CalcButton("log10", color: sciColor) { executeScientific("log10") }
                    CalcButton("4", color: numColor) { appendDigit("4") }
                    CalcButton("5", color: numColor) { appendDigit("5") }
                    CalcButton("6", color: numColor) { appendDigit("6") }
                    CalcButton("-", color: opColor) { setOperation("-") }
                }
                GridRow {
                    CalcButton("x!", color: sciColor) { executeScientific("x!") }
                    CalcButton(isShifted ? "asin" : "sin", color: sciColor) { executeScientific(isShifted ? "asin" : "sin") }
                    CalcButton(isShifted ? "acos" : "cos", color: sciColor) { executeScientific(isShifted ? "acos" : "cos") }
                    CalcButton(isShifted ? "atan" : "tan", color: sciColor) { executeScientific(isShifted ? "atan" : "tan") }
                    CalcButton("e", color: sciColor) { executeScientific("e") }
                    CalcButton("EE", color: sciColor) { executeScientific("EE") }
                    CalcButton("1", color: numColor) { appendDigit("1") }
                    CalcButton("2", color: numColor) { appendDigit("2") }
                    CalcButton("3", color: numColor) { appendDigit("3") }
                    CalcButton("+", color: opColor) { setOperation("+") }
                }
                GridRow {
                    CalcButton(isRadians ? "Rad" : "Deg", color: sciColor) { toggleAngleMode() }
                    CalcButton(isShifted ? "asinh" : "sinh", color: sciColor) { executeScientific(isShifted ? "asinh" : "sinh") }
                    CalcButton(isShifted ? "acosh" : "cosh", color: sciColor) { executeScientific(isShifted ? "acosh" : "cosh") }
                    CalcButton(isShifted ? "atanh" : "tanh", color: sciColor) { executeScientific(isShifted ? "atanh" : "tanh") }
                    CalcButton("π", color: sciColor) { executeScientific("π") }
                    CalcButton("Rand", color: sciColor) { executeScientific("Rand") }
                    CalcButton("0", color: numColor, isWide: true) { appendDigit("0") }
                        .gridCellColumns(2)
                    CalcButton(".", color: numColor) { appendDecimal() }
                    CalcButton("=", color: opColor) { pressEqual() }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .frame(minWidth: 700, minHeight: 520)
        .background(.background)
    }
    
    private func toggleShift() {
        if appState.currentTier != .ultra {
            showPaywall()
            return
        }
        isShifted.toggle()
    }
    
    private func toggleAngleMode() {
        if appState.currentTier != .ultra {
            showPaywall()
            return
        }
        isRadians.toggle()
    }
    
    private func appendDigit(_ digit: String) {
        if waitingForOperand {
            display = digit
            waitingForOperand = false
        } else {
            display = display == "0" ? digit : display + digit
        }
    }
    
    private func appendDecimal() {
        if appState.currentTier == .free {
            showPaywall()
            return
        }
        if waitingForOperand {
            display = "0."
            waitingForOperand = false
        } else if display.isEmpty {
            display = "0."
        } else if !display.contains(".") {
            display += "."
        }
    }
    
    private func setOperation(_ op: String) {
        if op == "×" || op == "÷" {
            if appState.currentTier == .free {
                showPaywall()
                return
            }
        } else if op == "x^y" || op == "y√x" {
            if appState.currentTier != .ultra {
                showPaywall()
                return
            }
        }
        
        let currentVal = display.isEmpty ? "0" : display
        if let value = Double(currentVal) {
            firstOperand = value
        }
        currentOperation = op
        historyText = "\(formatResult(Double(currentVal) ?? 0)) \(op)"
        waitingForOperand = true
    }
    
    private func reset() {
        display = ""
        historyText = ""
        firstOperand = nil
        currentOperation = nil
        waitingForOperand = false
    }
    
    private func executeBasicFunction(_ fn: String) {
        if appState.currentTier == .free {
            showPaywall()
            return
        }
        
        guard let current = Double(display.isEmpty ? "0" : display) else { return }
        if fn == "+/-" {
            let result = -current
            display = formatResult(result)
        } else if fn == "%" {
            let result = current / 100.0
            display = formatResult(result)
        }
    }
    
    private func executeScientific(_ fn: String) {
            if appState.currentTier != .ultra {
                showPaywall()
                return
            }
            
            let trigFunctions = ["sin", "asin", "cos", "acos", "tan", "atan", "sinh", "asinh", "cosh", "acosh", "tanh", "atanh", "ln", "log10", "√x", "∛x"]
            if trigFunctions.contains(fn) {
                currentOperation = fn
                historyText = "\(fn)("
                display = ""
                waitingForOperand = false
                return
            }
            
            guard let current = Double(display.isEmpty ? "0" : display) else { return }
            var result: Double = current
            let angleValue = isRadians ? current : current * (.pi / 180.0)
            switch fn {
            case "x²": result = current * current
            case "x⁴": result = pow(current, 4)
            case "x³": result = current * current * current
            case "∜x": result = current >= 0 ? pow(current, 0.25) : 0
            case "e^x": result = exp(current)
            case "ln(x+1)": result = current > -1 ? log(current + 1) : 0
            case "10^x": result = pow(10, current)
            case "2^x": result = pow(2, current)
            case "1/x": result = current != 0 ? 1.0 / current : 0
            case "√x": result = current >= 0 ? sqrt(current) : 0
            case "∛x": result = cbrt(current)
            case "ln": result = current > 0 ? log(current) : 0
            case "log10": result = current > 0 ? log10(current) : 0
            case "x!":
                if current >= 0 && current <= 20 && current.truncatingRemainder(dividingBy: 1) == 0 {
                    var fact: Double = 1
                    for i in 1...Int(current) { fact *= Double(i) }
                    result = fact
                }
            case "sin": result = sin(angleValue)
            case "asin":
                let raw = asin(current)
                result = isRadians ? raw : raw * (180.0 / .pi)
            case "cos": result = cos(angleValue)
            case "acos":
                let raw = acos(current)
                result = isRadians ? raw : raw * (180.0 / .pi)
            case "tan": result = tan(angleValue)
            case "atan":
                let raw = atan(current)
                result = isRadians ? raw : raw * (180.0 / .pi)
            case "sinh": result = sinh(current)
            case "asinh": result = asinh(current)
            case "cosh": result = cosh(current)
            case "acosh": result = current >= 1 ? acosh(current) : 0
            case "tanh": result = tanh(current)
            case "atanh": result = abs(current) < 1 ? atanh(current) : 0
            case "e": result = M_E
            case "π": result = Double.pi
            case "Rand": result = Double.random(in: 0...1)
            default: break
            }
            
            historyText = "\(fn)(\(formatResult(current))) ="
            display = formatResult(result)
            waitingForOperand = true
            
            if isShifted {
                isShifted = false
            }
        }
    
    private func pressEqual() {
        guard let op = currentOperation, let first = firstOperand, let second = Double(display.isEmpty ? "0" : display) else {
            return
        }
        
        var result: Double = 0
        switch op {
        case "+": result = first + second
        case "-": result = first - second
        case "×": result = first * second
        case "÷": result = second != 0 ? first / second : 0
        case "x^y": result = pow(first, second)
        case "y√x": result = second != 0 ? pow(first, 1.0 / second) : 0
        default: break
        }
        
        historyText = "\(formatResult(first)) \(op) \(formatResult(second)) ="
        display = formatResult(result)
        firstOperand = nil
        currentOperation = nil
        waitingForOperand = true
    }
    
    private func formatResult(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 && abs(value) < 1e15 {
            return String(Int(value))
        } else {
            return String(value)
        }
    }
    
    private func showPaywall() {
        withAnimation(.spring()) {
            appState.showPaywall = true
        }
    }
}

struct CalcButton: View {
    let title: String
    let color: Color
    let isWide: Bool
    let action: () -> Void
    init(_ title: String, color: Color = .gray.opacity(0.15), isWide: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.isWide = isWide
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .default))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 58)
                .background(color)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSuccessMessage = false
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation { appState.showPaywall = false }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 20)
            
            Text("Unlock Calculator+")
                .font(.system(size: 32, weight: .bold, design: .default))
            
            Text("Upgrade to Pro for more functionality, or Ultra for full scientific tools.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            VStack(spacing: 16) {
                SubscriptionTierRow(
                    tier: .free,
                    title: "Basic",
                    description: "Addition and subtraction only",
                    price: "$0.00/mo"
                ) {
                    appState.currentTier = .free
                    appState.showPaywall = false
                }
                
                SubscriptionTierRow(
                    tier: .pro,
                    title: "Pro",
                    description: "Multiplication, division, and decimals",
                    price: "$7.99/mo"
                ) {
                    triggerPurchase(for: .pro)
                }
                
                SubscriptionTierRow(
                    tier: .ultra,
                    title: "Ultra",
                    description: "Full scientific toolkit",
                    price: "$12.99/mo"
                ) {
                    triggerPurchase(for: .ultra)
                }
            }
            .padding(.horizontal, 80)
            
            if showSuccessMessage {
                Text("Payment processed!")
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
    
    private func triggerPurchase(for tier: SubscriptionTier) {
        withAnimation {
            showSuccessMessage = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            appState.currentTier = tier
            appState.showPaywall = false
            showSuccessMessage = false
        }
    }
}

struct SubscriptionTierRow: View {
    @EnvironmentObject var appState: AppState
    let tier: SubscriptionTier
    let title: String
    let description: String
    let price: String
    let onSelect: () -> Void
    var isSelected: Bool {
        appState.currentTier == tier
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(isSelected ? .blue : .primary)
                    Text(description)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                HStack(spacing: 12) {
                    Text(price)
                        .font(.system(size: 15, weight: .bold, design: .default))
                    
                    if tier != .free {
                        Text("Subscribe")
                            .font(.system(size: 13, weight: .semibold, design: .default))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
