/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift
import ReactiveSwift

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!
  let images = MutableProperty<[UIImage]>([])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    images.signal.observeValues { [weak self] images in
      guard let preview = self?.imagePreview else { return }
      preview.image = UIImage.collage(images: images, size: preview.frame.size)
    }
    
    images.producer.startWithValues { [weak self] images in
      self?.updateUI(with: images)
    }
  }

  func updateUI(with images: [UIImage]) {
    buttonSave.isEnabled = images.count > 0 && images.count % 2 == 0
    buttonClear.isEnabled = images.count > 0
    itemAdd.isEnabled = images.count < 6
    title = images.count > 0 ? "\(images.count) photos" : "Collage"
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  @IBAction func actionClear() {
    images.value = []
  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    let saveSignal = PhotoWriter.saveSignal(image)
    saveSignal.observeCompleted {
      self.showMessage("Saved")
      self.actionClear()
    }
    
    saveSignal.observeFailed { [weak self] error in
      self?.showMessage("Error", description: error.localizedDescription)
    }
  }

  @IBAction func actionAdd() {
    let photosViewController = storyboard!.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
    navigationController?.pushViewController(photosViewController, animated: true)
    photosViewController.selectedPhoto.signal.observeValues { [weak self] image in
      guard let images = self?.images, let image = image else { return }
      images.value.append(image)
    }
    photosViewController.selectedPhoto.signal.observeCompleted {
      print("completed")
    }
  }

  func showMessage(_ title: String, description: String? = nil) {
    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
    present(alert, animated: true, completion: nil)
  }
}
