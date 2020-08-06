import CombineX
import CXFoundation
import Foundation
import TimelaneCore

extension Publishers {
    public class TimelanePublisher<Upstream: Publisher, S>: Publisher where S: Scheduler {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure

        private let upstream: Upstream

        private let name: String?
        private let filter: Timelane.LaneTypeOptions
        private let source: String
        private let scheduler: S
        private let transformValue: (Upstream.Output) -> String
        private let logger: Timelane.Logger

        public init(upstream: Upstream,
                    name: String?,
                    filter: Timelane.LaneTypeOptions,
                    source: String,
                    scheduler: S,
                    transformValue: @escaping (Upstream.Output) -> String,
                    logger: @escaping Timelane.Logger) {
            self.upstream = upstream
            self.name = name
            self.filter = filter
            self.source = source
            self.scheduler = scheduler
            self.transformValue = transformValue
            self.logger = logger
        }

        public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            let filter = self.filter
            let source = self.source
            let scheduler = self.scheduler
            let subscription = Timelane.Subscription(name: name, logger: logger)
            let transform = self.transformValue

            let sink = AnySubscriber<Upstream.Output, Upstream.Failure>(
                receiveSubscription: { sub in
                    if filter.contains(.subscription) {
                        subscription.begin(source: source)
                    }

                    subscriber.receive(subscription: sub)
                },
                receiveValue: { value -> Subscribers.Demand in
                    if filter.contains(.event) {
                        subscription.event(value: .value(transform(value)), source: source)
                    }

                    return subscriber.receive(value)
                },
                receiveCompletion: { completion in
                    if filter.contains(.subscription) {
                        switch completion {
                        case .finished:
                            subscription.end(state: .completed)
                        case .failure(let error):
                            subscription.end(state: .error(error.localizedDescription))
                        }
                    }

                    if filter.contains(.event) {
                        switch completion {
                        case .finished:
                            subscription.event(value: .completion, source: source)
                        case .failure(let error):
                            subscription.event(value: .error(error.localizedDescription), source: source)
                        }
                    }

                    subscriber.receive(completion: completion)
                }
            )

            upstream
                .handleEvents(receiveCancel: {
                    // Sometimes a "cancel" event preceeds "finished" so we seem to
                    // need this hack below to make sure "finished" goes out first.
                    scheduler.schedule {
                        // Cancelling the subscription
                        if filter.contains(.subscription) {
                            subscription.end(state: .cancelled)
                        }
                        if filter.contains(.event) {
                            subscription.event(value: .cancelled, source: source)
                        }
                    }
                })
                .subscribe(sink)
        }
    }
}

extension Publisher {

    /// The `lane` operator logs the subscription and its events to the Timelane Instrument.
    ///
    ///  - Note: You can download the Timelane Instrument from http://timelane.tools
    /// - Parameters:
    ///   - name: A name for the lane when visualized in Instruments
    ///   - filter: Which events to log subscriptions or data events.
    ///             For example for a subscription on a subject you might be interested only in data events.
    ///   - transformValue: An optional closure to format the subscription values for displaying in Instruments.
    ///                     You can not only prettify the values but also change them completely, e.g. for arrays you can
    ///                     it might be more useful to report the count of elements if there are a lot of them.
    ///   - value: The value emitted by the subscription
    public func lane(_ name: String,
                     filter: Timelane.LaneTypeOptions = .all,
                     file: StaticString = #file,
                     function: StaticString  = #function,
                     line: UInt = #line,
                     scheduler: CXWrappers.DispatchQueue = DispatchQueue.main.cx,
                     transformValue: @escaping (_ value: Output) -> String = { String(describing: $0) },
                     logger: @escaping Timelane.Logger = Timelane.defaultLogger)
        -> Publishers.TimelanePublisher<Self, CXWrappers.DispatchQueue> {

        let fileName = file.description.components(separatedBy: "/").last!
        let source = "\(fileName):\(line) - \(function)"

        return Publishers.TimelanePublisher(upstream: self,
                                            name: name,
                                            filter: filter,
                                            source: source,
                                            scheduler: scheduler,
                                            transformValue: transformValue,
                                            logger: logger)
    }

    /// The `lane` operator logs the subscription and its events to the Timelane Instrument.
    ///
    ///  - Note: You can download the Timelane Instrument from http://timelane.tools
    /// - Parameters:
    ///   - name: A name for the lane when visualized in Instruments
    ///   - filter: Which events to log subscriptions or data events.
    ///             For example for a subscription on a subject you might be interested only in data events.
    ///   - transformValue: An optional closure to format the subscription values for displaying in Instruments.
    ///                     You can not only prettify the values but also change them completely, e.g. for arrays you can
    ///                     it might be more useful to report the count of elements if there are a lot of them.
    ///   - value: The value emitted by the subscription
    public func lane<S>(_ name: String,
                     filter: Timelane.LaneTypeOptions = .all,
                     file: StaticString = #file,
                     function: StaticString  = #function,
                     line: UInt = #line,
                     scheduler: S,
                     transformValue: @escaping (_ value: Output) -> String = { String(describing: $0) },
                     logger: @escaping Timelane.Logger = Timelane.defaultLogger)
        -> Publishers.TimelanePublisher<Self, S> where S: Scheduler {

        let fileName = file.description.components(separatedBy: "/").last!
        let source = "\(fileName):\(line) - \(function)"

        return Publishers.TimelanePublisher(upstream: self,
                                            name: name,
                                            filter: filter,
                                            source: source,
                                            scheduler: scheduler,
                                            transformValue: transformValue,
                                            logger: logger)
    }
}
