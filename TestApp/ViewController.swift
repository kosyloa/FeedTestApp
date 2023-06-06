//
//  ViewController.swift
//  TestApp
//
//  Created by Aleksey Kosylo on 05.06.23.
//

import UIKit
import DxFeedSwiftFramework

class TestEventListener: DXEventListener, Hashable {
    func receiveEvents(_ events: [MarketEvent]) {
        print(events)
    }

    static func == (lhs: TestEventListener, rhs: TestEventListener) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    let name: String

    init(name: String) {
        self.name = name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }


}

class ViewController: UIViewController {
    private var testListner: TestEventListener?
    private var endpoint: DXEndpoint?
    private var subscription:DXFeedSubcription?

    @IBOutlet var connectButton: UIButton!
    @IBOutlet var addressTextField: UITextField!
    @IBOutlet var subscribeButton: UIButton!
    @IBOutlet var symbolTextField: UITextField!
    @IBOutlet var eventsTextView: UITextView!

    var isConnected = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func updateConnectButton() {
        DispatchQueue.main.async {
            self.connectButton.setTitle(self.isConnected ? "Disconnect" : "Connect", for: .normal)
        }
    }

    @IBAction func connectTapped(_ sender: Any) {
        if isConnected {
            try? endpoint?.disconnect()
            subscription = nil
            eventsTextView.text = ""
            return
        }
        guard let address = addressTextField.text else {
            let alert = UIAlertController(title: "Error", message: "Please, input address", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        if endpoint == nil {
            endpoint = try? DXEndpoint.builder().withRole(.feed).withProperty("test", "value").build()
            endpoint?.add(self)
        }
        try? endpoint?.connect(address)
    }

    @IBAction func subscribeTapped(_ sender: Any) {
        if !isConnected {
            let alert = UIAlertController(title: "Error", message: "Please, connect before subscribe", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        guard let symbol = symbolTextField.text else {
            return
        }
        symbolTextField.resignFirstResponder()

        subscription = try? endpoint?.getFeed()?.createSubscription(.timeAndSale)
        subscription?.add(self)
        try? subscription?.addSymbols(symbol)
    }
}

extension ViewController: DXEndpointObserver {
    func endpointDidChangeState(old: DxFeedSwiftFramework.DXEndpointState, new: DxFeedSwiftFramework.DXEndpointState) {
        isConnected = new == .connected
        updateConnectButton()
    }
}

extension ViewController: DXEventListener {
    func receiveEvents(_ events: [DxFeedSwiftFramework.MarketEvent]) {
        DispatchQueue.main.async {
            self.eventsTextView.text = events.description
        }
    }
}
