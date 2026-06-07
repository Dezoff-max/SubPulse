import Foundation

struct CurrencyRates: Codable, Equatable {
    var ratesToRub: [String: Double]
    var updatedAt: Date?

    static let fallback = CurrencyRates(
        ratesToRub: [
            "RUB": 1,
            "USD": 90,
            "EUR": 98,
            "GBP": 115,
            "TRY": 2.8
        ],
        updatedAt: nil
    )

    func convert(_ amount: Double, from sourceCurrency: String, to targetCurrency: String) -> Double {
        let source = sourceCurrency.uppercased()
        let target = targetCurrency.uppercased()
        guard source != target else { return amount }
        guard let sourceRubRate = ratesToRub[source], let targetRubRate = ratesToRub[target], targetRubRate > 0 else {
            return amount
        }
        return amount * sourceRubRate / targetRubRate
    }
}

@MainActor
final class CurrencyExchangeService: ObservableObject {
    static let shared = CurrencyExchangeService()

    @Published private(set) var rates: CurrencyRates
    @Published private(set) var isRefreshing = false

    private let cacheKey = "currencyRates.cbr.cached"
    private let endpoint = URL(string: "https://www.cbr.ru/scripts/XML_daily.asp")!

    private init() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(CurrencyRates.self, from: data) {
            rates = cached
        } else {
            rates = .fallback
        }
    }

    func refreshIfNeeded() async {
        if let updatedAt = rates.updatedAt,
           Date().timeIntervalSince(updatedAt) < 60 * 60 * 12 {
            return
        }
        await refresh()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: endpoint)
            let fetched = try CBRXMLParser.parse(data: data)
            var merged = CurrencyRates.fallback.ratesToRub
            fetched.forEach { merged[$0.key] = $0.value }
            merged["RUB"] = 1

            let next = CurrencyRates(ratesToRub: merged, updatedAt: Date())
            rates = next
            if let encoded = try? JSONEncoder().encode(next) {
                UserDefaults.standard.set(encoded, forKey: cacheKey)
            }
        } catch {
            // Keep the last cached rates. The UI still updates correctly when
            // the user changes base currency, even if the online refresh fails.
        }
    }
}

private final class CBRXMLParser: NSObject, XMLParserDelegate {
    private var currentCharCode = ""
    private var currentNominal = ""
    private var currentValue = ""
    private var currentElement = ""
    private var parsedRates: [String: Double] = [:]

    static func parse(data: Data) throws -> [String: Double] {
        let delegate = CBRXMLParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else {
            throw parser.parserError ?? NSError(domain: "SubPulseCurrency", code: 1)
        }
        return delegate.parsedRates
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "Valute" {
            currentCharCode = ""
            currentNominal = ""
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        switch currentElement {
        case "CharCode":
            currentCharCode += value
        case "Nominal":
            currentNominal += value
        case "Value":
            currentValue += value
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Valute" {
            let code = currentCharCode.uppercased()
            guard ["USD", "EUR", "GBP", "TRY"].contains(code),
                  let nominal = Double(currentNominal.replacingOccurrences(of: ",", with: ".")),
                  let value = Double(currentValue.replacingOccurrences(of: ",", with: ".")),
                  nominal > 0
            else {
                return
            }
            parsedRates[code] = value / nominal
        }
        currentElement = ""
    }
}
