//
//  ViewModel.swift
//  actorAndCombine
//
//  Created by Kazutaka Homma on 2024-10-07.
//
// reference: https://forums.swift.org/t/asyncsequence-stream-version-of-passthroughsubject-or-currentvaluesubject/60395

import Combine

class ViewModel {
    let subject = PassthroughSubject<Int, Never>()
    let dataManager = DataManager()
    var cancellableSet = Set<AnyCancellable>()

    var stream: AsyncStream<Int> {
        AsyncStream { [weak self] continuation in
            guard let self else { return }
            let cancellable = subject
                .sink { continuation.yield($0) }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var streamMinus: AsyncStream<Int> {
        AsyncStream { [weak self] continuation in
            guard let self else { return }
            let cancellable = subject
                .map { $0 * -1 }
                .sink { continuation.yield($0) }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    init() {
//        taskInSink()

//        asyncPublisher()

//        twoForAwait()
        
        separateTasks()

//        twoListenerForOneStream()

    }

    func fetch() {
        for i in 0 ... 100 {
//            print(i)
            subject.send(i)
        }
    }

    // 😭
    // Creating Task inside sink could CHANGE the execution order
    func taskInSink() {
        subject.sink { i in
//            print("subject1 : \(i)")
            // this task is NOT guaranteed to be executed in order
            Task { [weak self] in
                guard let self else { return }
                await dataManager.handle(i)
            }
        }.store(in: &cancellableSet)
    }

    // 😭
    // subject.values drops its values due to backpressure
    // https://stackoverflow.com/questions/75776172/passthroughsubjects-asyncpublisher-values-property-not-producing-all-values
    func asyncPublisher() {
        Task {
            for await i in subject.values {
                print("awaited \(i)")
                await dataManager.handle(i)
            }
        }
    }

    // 😭
    // The first for-await waits indefinitely unless stream is canceled/terminated. Therefore, 2nd for-await never runs
    func twoForAwait() {
        Task {
            print("start")
            for await i in stream {
                await dataManager.handle(i)
            }
            // The line below is NEVER executed because the above await i will be waiting for stream indefinitely
            for await i in streamMinus {
                await dataManager.handle(i)
            }
        }
    }
    
    // 🙂
    func separateTasks() {
        Task {
            for await i in stream {
                await dataManager.handle(i)
            }
        }

        Task {
            for await i in streamMinus {
                await dataManager.handle(i)
            }
        }
    }
    
    // ⚠️ Note that AsyncStream is NOT meant to have multiple consumers ⚠️
    // https://forums.swift.org/t/consuming-an-asyncstream-from-multiple-tasks/54453
    func twoListenerForOneStream() {
        let stream1 = stream
        Task {
            for await i in stream1 {
                print("1st for-await",i)
            }
        }

        Task {
            for await i in stream1 {
                print("2nd for-await",i)
            }
        }
    }
}

actor DataManager {
    var data = [Int]()
    func handle(_ i: Int, isSilent: Bool = false) {
        if !isSilent {
            print("handling: \(i)")
        }
        data.append(i)
    }

    func sayHi() {
        print("hi yo")
        data.append(101)
    }
}
