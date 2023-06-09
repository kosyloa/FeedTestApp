//
//  QuoteTableViewController.swift
//  TestApp
//
//  Created by Aleksey Kosylo on 07.06.23.
//

import UIKit
import DxFeedSwiftFramework

class Counter {
    private (set) var value : Int64 = 0
    func add (_ amount: Int64) {
        OSAtomicAdd64(amount, &value)
    }
}

struct Colors {
    let background = UIColor(red: 18/255, green: 16/255, blue: 49/255, alpha: 1.0)
    let cellBackground = UIColor(red: 31/255, green: 30/255, blue: 65/255, alpha: 1.0)

    let priceBackground = UIColor(red: 60/255, green: 62/255, blue: 101/255, alpha: 1.0)
    let green = UIColor(red: 0/255, green: 117/255, blue: 91/255, alpha: 1.0)
    let red = UIColor(red: 147/255, green: 0/255, blue: 36/255, alpha: 1.0)
}

class QuoteTableViewController: UIViewController {
    var counter = Counter()
    let numberFormatter = NumberFormatter()
    var startTime = Date.now
    var lastValue: Int64 = 0
    private var endpoint: DXEndpoint?
    private var subscription:DXFeedSubcription?
    private var profileSubscription:DXFeedSubcription?

    var dataSource = [String: QuoteModel]()
    var symbols = ["ETH/USD:GDAX"]

    @IBOutlet var quoteTableView: UITableView!
    @IBOutlet var connectionStatusLabel: UILabel!

    let colors = Colors()

    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter.numberStyle = .decimal

        self.view.backgroundColor = colors.background
        self.quoteTableView.backgroundColor = colors.background

        quoteTableView.separatorStyle = .none

        try? SystemProperty.setProperty("com.devexperts.connector.proto.heartbeatTimeout", "10s")

        endpoint = try? DXEndpoint.builder().withRole(.feed)
//            .withProperty(DXEndpoint.Property.aggregationPeriod.rawValue, "3")
            .build()
        endpoint?.add(self)
        try? endpoint?.connect("Alekseys-MacBook-Pro.local:6666")
        
        subscription = try? endpoint?.getFeed()?.createSubscription(.timeAndSale)
        profileSubscription = try? endpoint?.getFeed()?.createSubscription(.profile)
        subscription?.add(self)
        profileSubscription?.add(self)
        symbols.forEach {
            dataSource[$0] = QuoteModel()
        }
        try? subscription?.addSymbols(symbols)
        try? profileSubscription?.addSymbols(symbols)
        DispatchQueue.global(qos: .background).async {
                Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                    let lastStart = self.startTime
                    let currentValue = self.counter.value

                    self.startTime = Date.now
                    let seconds = Date.now.timeIntervalSince(lastStart)
                    let speed = seconds == 0 ? nil : NSNumber(value: Double(currentValue - self.lastValue) / seconds)

                    self.lastValue = currentValue
                    if let speed = speed {
                        print("---------------------------------------------------")
                        print("Event speed                \(self.numberFormatter.string(from: speed)!) per/sec")
                        DispatchQueue.main.async {
                            self.connectionStatusLabel.text = self.numberFormatter.string(from: speed)!
                        }
                        print("---------------------------------------------------")
                    }
                }
                RunLoop.current.run()
        }

    }

}

extension QuoteTableViewController: DXEndpointObserver {
    func endpointDidChangeState(old: DxFeedSwiftFramework.DXEndpointState, new: DxFeedSwiftFramework.DXEndpointState) {
        var status = "Not connected"
        switch new {
        case .notConnected:
            status = "Not connected ❌"
        case .connecting:
            status = "Connecting 🔄"
        case .connected:
            status = "Connected ✅"
        case .closed:
            status = "Closed ⛔️gi"
        @unknown default:
            status = "Not connected"
        }
        DispatchQueue.main.async {
            self.connectionStatusLabel.text = "Connection status: \(status)" 
        }
    }
}

extension QuoteTableViewController: DXEventListener {
    func receiveEvents(_ events: [DxFeedSwiftFramework.MarketEvent]) {
        let count = events.count
        counter.add(Int64(count))

//        events.forEach { event in
//            switch event.type {
//            case .quote:
//                if let quote = event as? Quote {
//                    dataSource[event.eventSymbol]?.update(quote)
//                }
//            case .profile:
//                if let profile = event as? Profile {
//                    dataSource[event.eventSymbol]?.update(profile.descriptionStr)
//                }
//            default: break
////                print(event)
//            }
//        }
//        DispatchQueue.main.async {
//            self.quoteTableView.reloadData()
//        }
    }
}

extension QuoteTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuoteCellId", for: indexPath) as! QuoteCell
        let symbol = symbols[indexPath.row]
        let quote = dataSource[symbol]
        cell.update(model: quote, symbol: symbol, description: quote?.descriptionString)
        return cell
    }
}

extension QuoteTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
