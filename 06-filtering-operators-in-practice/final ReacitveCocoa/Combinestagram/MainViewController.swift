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

extension UIViewController {
  func showAlert(_ title: String, description: String?) -> SignalProducer<Void, NSError> {
    return SignalProducer {[weak self] observer, lifeTime in
      let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in observer.sendCompleted() }))
      self?.present(alert, animated: true, completion: nil)
      lifeTime.observeEnded {
        alert.dismiss(animated: true, completion: nil)
      }
    }
  }
}

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!
  let images = MutableProperty<[UIImage]>([])
  private var imageCache = [Int]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    images.signal
      .throttle(0.5, on: QueueScheduler.main)
      .observeValues { [weak self] images in
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
    imageCache = []
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
    photosViewController.selectedPhoto.signal
      .take(while: {[weak self] _ in return (self?.images.value.count ?? 0) < 6 })
      .filter { image in
        guard let image = image else { return false }
        return image.size.height < image.size.width
      }
      .filter { [weak self] image in
        guard let image = image else { return false }
        let len = UIImagePNGRepresentation(image)?.count ?? 0
        guard self?.imageCache.contains(len) == false else { return false }
        self?.imageCache.append(len)
        return true
      }
      .observeValues { [weak self] image in
      guard let images = self?.images, let image = image else { return }
      images.value.append(image)
    }
    
    photosViewController.selectedPhoto.signal.observeCompleted { [weak self] in
      self?.updateNavigationIcon()
      print("completed")
    }
  }

  func showMessage(_ title: String, description: String? = nil) {
    showAlert(title, description: description).start()
  }
  
  private func updateNavigationIcon() {
    let icon = imagePreview.image?
      .scaled(CGSize(width: 22, height: 22))
      .withRenderingMode(.alwaysOriginal)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon,
                                                       style: .done, target: nil, action: nil)
  }
}
