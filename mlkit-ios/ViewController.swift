//
//  ViewController.swift
//  mlkit-ios
//
//  Created by Максим Скрябин on 21/04/2019.
//  Copyright © 2019 MSKR. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {

  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var instructionsLabel: UILabel!
  @IBOutlet private weak var resultLabel: UILabel!
  @IBOutlet private weak var photoImageView: UIImageView!
  @IBOutlet private weak var openCamerButton: UIButton!
  @IBOutlet private weak var openPhotoLibraryButton: UIButton!
  
  private let imagePicker = UIImagePickerController()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    imagePicker.delegate = self
    imagePicker.allowsEditing = false
    
    updateLabel(fruit: nil)
  }
  
  @IBAction private func openCameraButtonTapped() {
    imagePicker.sourceType = .camera
    present(imagePicker, animated: true, completion: nil)
  }
  
  @IBAction private func openPhotoLibraryButtonTapped() {
    imagePicker.sourceType =  .photoLibrary
    present(imagePicker, animated: true, completion: nil)
  }
  
  private func analyzeImage(image: UIImage) {
    resultLabel.text = "Analyzing..."
    
    guard let ciImage = CIImage(image: image) else {
      updateLabel(fruit: .unknown)
      return
    }
    
    do {
      let model = try VNCoreMLModel(for: ImageClassifier().model)
      let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
      let request = VNCoreMLRequest(model: model) { [weak self] (request, error) in
        if let results = request.results as? [VNClassificationObservation], !results.isEmpty, error == nil {
          let sortedClassifications = results.sorted(by: { $0.confidence > $1.confidence })
          if let classification = sortedClassifications.first, classification.confidence > 0.99 {
            self?.updateLabel(fruit: FruitType(rawValue: classification.identifier), confidence: classification.confidence)
          } else {
            self?.updateLabel(fruit: .unknown)
          }
        } else {
          self?.updateLabel(fruit: .unknown)
        }
      }
      try handler.perform([request])
    } catch let error {
      print("🔥 Error: \(error.localizedDescription)")
      updateLabel(fruit: .unknown)
    }
  }
  
  private func updateLabel(fruit: FruitType?, confidence: Float? = nil) {
    if let fruit = fruit {
      if fruit == .unknown {
        resultLabel.text = "App wasn't able to guess the fruit :("
      } else {
        var text = "App thinks it's a \(fruit.rawValue)"
        if let confidence = confidence {
          text.append(" (\(confidence * 100.0)%)")
        }
        resultLabel.text = text
      }
    } else {
      resultLabel.text = nil
    }
  }
}

extension ViewController {
  enum FruitType: String {
    case apple
    case banana
    case orange
    case unknown
  }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let image = info[.originalImage] as? UIImage {
      photoImageView.image = image
      analyzeImage(image: image)
    }
    imagePicker.dismiss(animated: true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    imagePicker.dismiss(animated: true, completion: nil)
  }
}
