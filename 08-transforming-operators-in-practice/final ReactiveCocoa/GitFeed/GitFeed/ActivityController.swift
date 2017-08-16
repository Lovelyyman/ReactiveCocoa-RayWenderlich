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
import Kingfisher
import ReactiveCocoa
import ReactiveSwift
import Result

class ActivityController: UITableViewController {

  let repo = "ReactiveX/RxSwift"

  fileprivate let events = MutableProperty<[Event]>([])
  fileprivate let lastModified = MutableProperty<NSString?>(nil)
  
  private let eventsFileURL = ActivityController.cachedFileURL("events.plist")
  private let modifiedFileURL = ActivityController.cachedFileURL("modified.txt")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = repo

    self.refreshControl = UIRefreshControl()
    let refreshControl = self.refreshControl!

    refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
    refreshControl.tintColor = UIColor.darkGray
    refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
    refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

    let eventsArray = (NSArray(contentsOf: eventsFileURL)
      as? [[String: Any]]) ?? []
    events.value = eventsArray.flatMap(Event.init)
    
    lastModified.value = try? NSString(contentsOf: modifiedFileURL, usedEncoding: nil)
    
    refresh()
  }

  func refresh() {
    fetchEvents(repo: repo)
  }
  
  static func cachedFileURL(_ fileName: String) -> URL {
    return FileManager.default
      .urls(for: .cachesDirectory, in: .allDomainsMask)
      .first!
      .appendingPathComponent(fileName)
  }

  func fetchEvents(repo: String) {
    let response = SignalProducer<String, AnyError>([repo])
      .map { text -> URL in
        return URL(string: "https://api.github.com/repos/\(text)/events")!
      }
      .map {[weak self] url -> URLRequest in
        var request = URLRequest(url: url)
        if let modifiedHeader = self?.lastModified.value {
          request.addValue(modifiedHeader as String,
                           forHTTPHeaderField: "Last-Modified")
        }
        return request
      }
      .flatMap(FlattenStrategy.latest) { urlRequest in
        return URLSession.shared.reactive.data(with: urlRequest)
      }
      .replayLazily(upTo: 1)
    
    response.map { data, _ -> [[String: Any]] in
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
          let result = jsonObject as? [[String: Any]] else { return [] }
        return result
      }
      .filter { !$0.isEmpty }
      .map { $0.flatMap(Event.init) }
      .startWithResult { [weak self] result in
        guard let events = result.value else { return }
        self?.processEvents(events)
      }
   
    response.flatMap(.latest) { (data, response) -> SignalProducer<NSString, AnyError> in
      let httpRes = response as? HTTPURLResponse
      guard let value = httpRes?.allHeaderFields["Last-Modified"] as? NSString else { return SignalProducer.never }
      return SignalProducer(value: value)
    }.startWithResult { [weak self] result in
      guard let `self` = self, let modifiedHeader = result.value else { return }
      self.lastModified.value = modifiedHeader
      try? modifiedHeader.write(to: self.modifiedFileURL, atomically: true, encoding: String.Encoding.utf8.rawValue)
    }
    
  }
  
  func processEvents(_ newEvents: [Event]) {
    var updatedEvents = newEvents + events.value
    if updatedEvents.count > 50 {
      updatedEvents = Array<Event>(updatedEvents.prefix(upTo: 50))
    }
    events.value = updatedEvents
    tableView.reloadData()
    refreshControl?.endRefreshing()
    let eventsArray = updatedEvents.map { $0.dictionary } as NSArray
    eventsArray.write(to: eventsFileURL, atomically: true)
  }
  
  // MARK: - Table Data Source
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return events.value.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let event = events.value[indexPath.row]

    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
    cell.textLabel?.text = event.name
    cell.detailTextLabel?.text = event.repo + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
    cell.imageView?.kf.setImage(with: event.imageUrl, placeholder: UIImage(named: "blank-avatar"))
    return cell
  }
}
