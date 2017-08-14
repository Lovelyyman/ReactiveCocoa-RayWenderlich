//
//  PHPhotoLibrary+RAC.swift
//  Combinestagram
//
//  Created by Mikhail Lyapich on 8/14/17.
//  Copyright © 2017 Underplot ltd. All rights reserved.
//

import Foundation
import Photos
import ReactiveCocoa
import ReactiveSwift

extension PHPhotoLibrary {
  static var authorized: Signal<Bool, NSError> {
    return Signal() { observer in
      DispatchQueue.main.async {
        if authorizationStatus() == .authorized {
          observer.send(value: true)
          observer.sendCompleted()
        } else {
          observer.send(value: false)
          requestAuthorization { status in
            observer.send(value: status == .authorized)
            observer.sendCompleted()
          }
        }
      }
      return nil
    }
  }
}
