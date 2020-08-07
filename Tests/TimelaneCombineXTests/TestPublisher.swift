import CombineX
import Foundation

extension Publishers {
    class TestPublisherSubscription: Subscription {
        func request(_ demand: Subscribers.Demand) { }
        func cancel() { }
    }

    class TestPublisher: Publisher {
        typealias Output = String
        typealias Failure = Error

        let duration: TimeInterval
        let error: Error?

        init(duration: TimeInterval, error: Error? = nil) {
            self.duration = duration
            self.error = error
        }

        func receive<S>(subscriber: S) where S : Subscriber, Publishers.TestPublisher.Failure == S.Failure, Publishers.TestPublisher.Output == S.Input {
            subscriber.receive(subscription: TestPublisherSubscription())

            _ = subscriber.receive("Hello")
            let error = self.error

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if let error = error {
                    subscriber.receive(completion: .failure(error))
                } else {
                    subscriber.receive(completion: .finished)
                }
            }
        }
    }
}
