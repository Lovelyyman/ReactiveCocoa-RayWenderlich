import ReactiveSwift
import ReactiveCocoa
example(of: "ignore all") {
  let s = SignalProducer<Int, NSError>([3,4,5])
  s.filter { _ in return false }.start { _ in
      print("You're out!")
  }
}

example(of: "element at index (take last, take first)") {
  let s = SignalProducer<Int, NSError>([3,4,5])
  s.take(last: 2).take(first: 1).start { event in
    print("value: \(event)")
  }
}

example(of: "filter") {
  let s = SignalProducer<Int, NSError>([3,4,5,6,7,8])
  s.filter { num in return num % 2 == 0 }.start { event in
    print("\(event)")
  }
}

example(of: "skip first") {
  let s = SignalProducer<Int, NSError>([3,4,5,6,7,8])
  s.skip(first: 3).start { event in
    print("\(event)")
  }
}

example(of: "skip while") {
  let s = SignalProducer<Int, NSError>([2,2,2,3,4,4])
  s.skip {num in num % 2 == 0 }.start { event in
    print("\(event)")
  }
}

example(of: "skip while ???") {
  let s = SignalProducer<Int, NSError>([2,2,2,3,4,4])
  let s2 = SignalProducer<Int, NSError>([2,3])
//  s.skip(until: s2).start { event in
//    print("\(event)")
//  }
}

example(of: "skip repeats") {
  let s = SignalProducer<Int, NSError>([2,2,2,3,4,4])
  s.skipRepeats().start { event in
    print("\(event)")
  }
}
