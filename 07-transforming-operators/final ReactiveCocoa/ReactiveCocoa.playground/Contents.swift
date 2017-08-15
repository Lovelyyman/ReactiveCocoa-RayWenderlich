import ReactiveSwift
import ReactiveCocoa

public func example(of description: String, action: () -> Void) {
  print("\n--- Example of:", description, "---")
  action()
}
example(of: "collect (toArray)") {
  let s = SignalProducer<Int, NSError>([1,2,3])
  s.collect().startWithResult { res in
    print(res.value)
  }
}

example(of: "map") {
  let s = SignalProducer<Int, NSError>([1,2,3])
  s.map { $0 * 2 }.startWithResult { res in
    print(res.value)
  }
}

struct Student {
  var score: MutableProperty<Int>
}

example(of: "concurent flatMap") {
  let r = Student(score: MutableProperty(5))
  let j = Student(score: MutableProperty(10))
  let (signal, observer) = Signal<Student, NSError>.pipe()
  
  signal.flatMap(FlattenStrategy.concurrent(limit: 10)) { $0.score.producer }
    .observeResult { print($0) }
  
  observer.send(value: r)
  r.score.value = 20
  observer.send(value: j)
  r.score.value = 25
}

example(of: "last flatMap") {
  let r = Student(score: MutableProperty(5))
  let j = Student(score: MutableProperty(10))
  let (signal, observer) = Signal<Student, NSError>.pipe()
  
  signal.flatMap(FlattenStrategy.latest) { $0.score.producer }
    .observeResult { print($0) }
  
  observer.send(value: r)
  r.score.value = 20
  observer.send(value: j)
  r.score.value = 25
  j.score.value = 50
  
}