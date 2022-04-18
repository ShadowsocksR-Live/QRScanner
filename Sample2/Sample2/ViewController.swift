//
//  ViewController.swift
//  QRScannerSample
//
//  Created by wbi on 2019/10/16.
//  Copyright © 2019 mercari.com. All rights reserved.
//

import UIKit
import QRScanner

final class ViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!
    
    @IBAction func readQrCode(_ sender: Any) {
        let ctrl = QRScannerController()
        ctrl.success = { code in
            self.resultLabel.text = code
            self.dismiss(animated: true, completion: nil)
        }
        self.present(ctrl, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        resultLabel.preferredMaxLayoutWidth = 300
    }
}
