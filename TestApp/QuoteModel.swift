//
//  QuoteModel.swift
//  TestApp
//
//  Created by Aleksey Kosylo on 07.06.23.
//

import Foundation
import DxFeedSwiftFramework

class QuoteModel {

    let formatter = NumberFormatter()

    private var current: Quote?
    private var previous: Quote?
    init() {
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
    }

    var ask: String {
        let number = NSNumber(value: current?.askPrice ?? 0)
        return formatter.string(from: number) ?? ""
    }

    var bid: String {
        let number = NSNumber(value: current?.bidPrice ?? 0)
        return formatter.string(from: number)  ?? ""
    }

    var increaseAsk: Bool? {
        guard let current = current?.askPrice, let previous = previous?.askPrice else {
            return nil
        }
        return current > previous
    }

    var increaseBid: Bool? {
        guard let current = current?.bidPrice, let previous = previous?.bidPrice else {
            return nil
        }
        return current > previous
    }

    func update(_ value: Quote) {
        previous = current
        current = value
    }
    
}
