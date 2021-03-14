//
//  ViewController.swift
//  Stocks
//
//  Created by Mikhaylova Aleksandra on 2021.01.31.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companyLogo: UIImageView!
    
    // Private
    private lazy var companies = [
        "Apple": "AAPL",
        "Microsoft": "MSFT",
        "Google": "GOOG",
        "Amazon": "AMZN",
        "Facebook": "FB"
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
        companyNameLabel.text = "Tinkoff"
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        requestQuoteUpdate()
    }
    
    // MARK: - Private
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        companyLogo.image = nil
        priceChangeLabel.textColor = UIColor.darkText
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
        requestImageUrl(for: selectedSymbol)
    }
    
    private func requestQuote(for symbol: String) {
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
               (response as? HTTPURLResponse)?.statusCode == 200,
               error == nil {
                self?.parseQuote(from: data)
            } else {
                self?.displayError()
            }
        }
        
        dataTask.resume()
    }
    
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else {return self.displayError() }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName, companySymbol: companySymbol, price: price, priceChange: priceChange)
            }
        } catch {
            self.displayError()
        }
    }
    
    private func requestImageUrl(for symbol: String) {
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
                return
            }
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data,
                   (response as? HTTPURLResponse)?.statusCode == 200,
                   error == nil {
                    do {
                        let jsonObject = try JSONSerialization.jsonObject(with: data)

                        guard
                            let json = jsonObject as? [String: Any],
                            let logoUrlString = json["url"] as? String,
                            let logoUrl = URL(string: logoUrlString)
                        else { return self.displayError() }
                        
                        URLSession.shared.dataTask(with: logoUrl) { (data, response, error) in
                            if let data = data,
                               (response as? HTTPURLResponse)?.statusCode == 200,
                               error == nil {
                                DispatchQueue.main.async { [weak self] in
                                    self?.displayCompanyLogo(data: data)
                                }
                            }
                            else {}
                        }.resume()
                    } catch {
                        self.displayError()
                    }
                } else {
                    self.displayError()
                }
            }.resume()
        }
    
    private func displayStockInfo(companyName: String, companySymbol: String, price: Double, priceChange: Double) {
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        if priceChange > 0 {
            priceChangeLabel.textColor = UIColor.systemGreen
        } else if priceChange < 0 {
            priceChangeLabel.textColor = UIColor.systemRed
        }
    }
    
    private func displayCompanyLogo(data: Data) {
       activityIndicator.stopAnimating()
       companyLogo.image = UIImage(data: data)
   }
    
    private func displayError() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "Error", message: "Could not load the stock.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
                self?.requestQuoteUpdate()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: UIPickerViewDataSource {

extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
}
