//
//  QuoteTableViewController.swift
//  TestApp
//
//  Created by Aleksey Kosylo on 07.06.23.
//

import UIKit
import DxFeedSwiftFramework

struct Colors {
    let background = UIColor(red: 18/255, green: 16/255, blue: 49/255, alpha: 1.0)
    let cellBackground = UIColor(red: 31/255, green: 30/255, blue: 65/255, alpha: 1.0)

    let priceBackground = UIColor(red: 60/255, green: 62/255, blue: 101/255, alpha: 1.0)
    let green = UIColor(red: 0/255, green: 117/255, blue: 91/255, alpha: 1.0)
    let red = UIColor(red: 147/255, green: 0/255, blue: 36/255, alpha: 1.0)
}

class QuoteTableViewController: UIViewController {
    private var endpoint: DXEndpoint?
    private var subscription:DXFeedSubcription?
    private var profileSubscription:DXFeedSubcription?

    var dataSource = [String: QuoteModel]()
    var symbols = ["AAPL", "IBM", "MSFT", "EUR/CAD", "ETH/USD:GDAX", "GOOG", "BAC" , "CSCO", "ABCE", "INTC"]

    @IBOutlet var quoteTableView: UITableView!
    @IBOutlet var connectionStatusLabel: UILabel!

    let colors = Colors()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = colors.background
        self.quoteTableView.backgroundColor = colors.background

        quoteTableView.separatorStyle = .none

        try? SystemProperty.setProperty("com.devexperts.connector.proto.heartbeatTimeout", "10s")

        endpoint = try? DXEndpoint.builder().withRole(.feed)
            .withProperty(DXEndpoint.Property.aggregationPeriod.rawValue, "3")
            .build()
        endpoint?.add(self)
        try? endpoint?.connect("demo.dxfeed.com:7300")
        
        subscription = try? endpoint?.getFeed()?.createSubscription(.quote)
        profileSubscription = try? endpoint?.getFeed()?.createSubscription(.profile)
        subscription?.add(self)
        profileSubscription?.add(self)
        symbols.forEach {
            dataSource[$0] = QuoteModel()
        }
        try? subscription?.addSymbols(symbols)
        try? profileSubscription?.addSymbols(symbols)
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
            status = "Closed ⛔️"
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

        events.forEach { event in
            switch event.type {
            case .quote:
                if let quote = event as? Quote {
                    dataSource[event.eventSymbol]?.update(quote)
                }
            case .profile:
                if let profile = event as? Profile {
                    dataSource[event.eventSymbol]?.update(profile.descriptionStr)
                }
            default:
                print(event)
            }
        }
        DispatchQueue.main.async {
            self.quoteTableView.reloadData()
        }
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
