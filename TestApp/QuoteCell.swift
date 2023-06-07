//
//  QuoteCell.swift
//  TestApp
//
//  Created by Aleksey Kosylo on 07.06.23.
//

import UIKit

class QuoteCell: UITableViewCell {
    @IBOutlet var symbolNameLabel: UILabel!
    @IBOutlet var askLabel: UILabel!
    @IBOutlet var bidLabel: UILabel!

    @IBOutlet var priceContentView: UIView!
    @IBOutlet var backgroundContentView: UIView!


    required init?(coder: NSCoder) {
        super.init(coder: coder)

    }
    let colors = Colors()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundContentView.layer.cornerRadius = 10
        self.backgroundContentView.clipsToBounds = true
        self.contentView.backgroundColor = colors.background
        self.backgroundContentView.backgroundColor = colors.cellBackground
        priceContentView.layer.cornerRadius = 10
        priceContentView.clipsToBounds = true
    }

    func updateAsk(value: Bool?) {
        updateLabelBackground(value: value, label: askLabel)
    }

    func updateBid(value: Bool?) {
        updateLabelBackground(value: value, label: bidLabel)
    }

    private func updateLabelBackground(value: Bool?, label: UILabel) {
        guard let value = value else {
            label.backgroundColor = colors.priceBackground
            return
        }
        label.backgroundColor = value ? colors.green : colors.red
    }

    func update(model: QuoteModel?, symbol: String) {
        symbolNameLabel.text = symbol.components(separatedBy: ":").first ?? ""
        askLabel.text = model?.ask
        updateAsk(value: model?.increaseAsk)
        updateBid(value: model?.increaseBid)
        bidLabel.text = model?.bid
    }
}
