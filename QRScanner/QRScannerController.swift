//
//  QRScannerController.swift
//  QRScanner
//
//  Created by xxxooo on 2022/4/17.
//  Copyright © 2022 mercari.com. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation

final class RoundButton: UIButton {
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        settings()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        settings()
    }

    // MARK: - Properties
    override var isSelected: Bool {
        didSet {
            let color: UIColor = isSelected ? .gray : .lightGray
            backgroundColor = color.withAlphaComponent(0.7)
        }
    }
    
    private func settings() {
        tintColor = .clear
        layer.cornerRadius = frame.size.width / 2
        isSelected = false
    }
}

public class QRScannerController: UIViewController {
    // MARK: - Outlets
    private var qrScannerView: QRScannerView!
    private var torchButton: RoundButton!
    private var cancelButton: RoundButton!
    private var albumButton: RoundButton!

    public var success: ((String?) -> Void)?
    
    final let btnRadius = 40

    // MARK: - LifeCycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        qrScannerView = QRScannerView(frame: CGRect(x: 0, y: 0, width: 414, height: 896))
        self.view.addSubview(qrScannerView)
        self.view.bringSubviewToFront(qrScannerView)
        qrScannerView.backgroundColor = UIColor(white: 0, alpha: 0)
        
        torchButton = RoundButton(frame: CGRect(x: 0, y: 0, width: btnRadius * 2, height: btnRadius * 2))
        torchButton.addTarget(self, action: #selector(tapTorchButton(_:)), for: .touchUpInside)
        torchButton.setBackgroundImage(UIImage(named: "torch", in: .module, compatibleWith: nil), for: .normal)
        self.view.addSubview(torchButton)
        self.view.bringSubviewToFront(torchButton)

        cancelButton = RoundButton(frame: CGRect(x: 0, y: 0, width: btnRadius * 2, height: btnRadius * 2))
        cancelButton.addTarget(self, action: #selector(tapCancelButton(_:)), for: .touchUpInside)
        cancelButton.setBackgroundImage(UIImage(named: "exit", in: .module, compatibleWith: nil), for: .normal)
        self.view.addSubview(cancelButton)
        self.view.bringSubviewToFront(cancelButton)

        albumButton = RoundButton(frame: CGRect(x: 0, y: 0, width: btnRadius * 2, height: btnRadius * 2))
        albumButton.addTarget(self, action: #selector(tapAlbumButton(_:)), for: .touchUpInside)
        albumButton.setBackgroundImage(UIImage(named: "album", in: .module, compatibleWith: nil), for: .normal)
        self.view.addSubview(albumButton)
        self.view.bringSubviewToFront(albumButton)

        setupQRScanner()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let rc = self.view.frame
        qrScannerView.frame = rc
        torchButton.center = CGPoint(x: rc.width / 2, y: rc.height * 4 / 5)
        cancelButton.center = CGPoint(x: rc.width / 2 + CGFloat(btnRadius * 10 / 4), y: rc.height * 4 / 5)
        albumButton.center = CGPoint(x: rc.width / 2 - CGFloat(btnRadius * 10 / 4), y: rc.height * 4 / 5)
    }

    private func setupQRScanner() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupQRScannerView()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { [weak self] in
                        self?.setupQRScannerView()
                    }
                }
            }
        default:
            showAlert(msg: "Camera is required to use in this application")
        }
    }

    private func setupQRScannerView() {
        qrScannerView.configure(delegate: self, input: .init(isBlurEffectEnabled: true))
        qrScannerView.startRunning()
    }

    private func showAlert(msg:String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .cancel))
            self?.present(alert, animated: true)
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        qrScannerView.stopRunning()
    }

    @objc func tapTorchButton(_ sender: UIButton) {
        qrScannerView.setTorchActive(isOn: !sender.isSelected)
    }

    @objc func tapCancelButton(_ sender: UIButton) {
        success?(nil)
    }

    @objc func tapAlbumButton(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) == false {
            showAlert(msg: "Can NOT open photo library")
            return
        }
        let picker = UIImagePickerController()
        picker.view.backgroundColor = .white
        picker.delegate = self
        
        self.present(picker, animated: true) {
        }
    }
}

// MARK: - QRScannerViewDelegate
extension QRScannerController: QRScannerViewDelegate {
    public func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        print(error.localizedDescription)
    }

    public func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        if self.success == nil {
            showAlert(msg: "Please set a callback to return the qrcode string")
        }
        self.success?(code)
        self.qrScannerView.rescan()
    }

    public func qrScannerView(_ qrScannerView: QRScannerView, didChangeTorchActive isOn: Bool) {
        torchButton.isSelected = isOn
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension QRScannerController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true) {
            self.scan(image: info[UIImagePickerController.InfoKey.originalImage] as! UIImage) { values in
                if ((values?.count)! > 0) {
                    self.success?(values![0])
                } else {
                    self.qrScannerView.startRunning()
                }
            }
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true) {
            self.qrScannerView.startRunning()
        }
    }

    private func scan(image:UIImage, completion: @escaping (([String?]?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let detector = CIDetector.init(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])
            let ciImage = CIImage.init(image: image)
            let features = detector?.features(in: ciImage!)
            let arr = features?.map{ value in
                (value as! CIQRCodeFeature).messageString
            }
            DispatchQueue.main.async {
                completion(arr)
            }
        }
    }
}
