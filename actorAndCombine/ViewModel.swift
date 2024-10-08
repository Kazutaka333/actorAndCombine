//
//  ViewModel.swift
//  actorAndCombine
//
//  Created by Kazutaka Homma on 2024-10-07.
//
// reference: https://forums.swift.org/t/asyncsequence-stream-version-of-passthroughsubject-or-currentvaluesubject/60395

import Combine

class ViewModel {
    let subject = CurrentValueSubject<Int, Never>(0)
    let dataManager = DataManager()

    var stream: AsyncStream<Int> {
        AsyncStream { [weak self] continuation in
            guard let self else { return }
            let cancellable = subject.sink { continuation.yield($0) }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    init() {
        // 😭
//        _ = subject.sink { i in
//            print("subject1 : \(i)")
//            // this task is not guaranteed to be executed in order
//            Task { [weak self] in
//                guard let self else { return }
//                await dataManager.handle(i)
//            }
//        }

        // 😢
//        Task {
//            for await i in subject.values {
        ////                print("awaited \(i)")
//                await dataManager.handle(i)
//            }
//            let result = await dataManager.data
//            print("result: \(result)")
//        }

        // 😊
        Task {
            for await i in stream {
                await dataManager.handle(i)
            }
        }
        
    }

    func fetch() {
        for i in 0 ... 100 {
//            print(i)
            subject.send(i)
        }
    }
}

actor DataManager {
    var data = [Int]()
    func handle(_ i: Int) {
        print("handling: \(i)")
        data.append(i)
    }
}
