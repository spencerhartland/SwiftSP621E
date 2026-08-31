//
//  AsyncThrottleSequence.swift
//  SwiftSP621E
//
//  Created by Spencer Hartland on 8/29/26.
//

extension AsyncSequence {
    public func throttle<C: Clock, Reduced>(
        for interval: C.Instant.Duration,
        clock: C,
        reducing: @Sendable @escaping (Reduced?, Element) async -> Reduced
    ) -> AsyncThrottleSequence<Self, C, Reduced> {
        AsyncThrottleSequence(self, interval: interval, clock: clock, reducing: reducing)
    }
    
    public func throttle<C: Clock>(
        for interval: C.Instant.Duration,
        clock: C,
        latest: Bool = true
    ) -> AsyncThrottleSequence<Self, C, Element> {
        throttle(for: interval, clock: clock) { previous, element in
            guard latest else {
                return previous ?? element
            }
            return element
        }
    }
    
    public func throttle(
        for interval: Duration,
        latest: Bool = true
    ) -> AsyncThrottleSequence<Self, ContinuousClock, Element> {
        throttle(for: interval, clock: .continuous, latest: latest)
    }
}

public struct AsyncThrottleSequence<Base: AsyncSequence, C: Clock, Reduced> {
    let base: Base
    let interval: C.Instant.Duration
    let clock: C
    let reducing: @Sendable (Reduced?, Base.Element) async -> Reduced
    
    init(
        _ base: Base,
        interval: C.Instant.Duration,
        clock: C,
        reducing: @Sendable @escaping (Reduced?, Base.Element) async -> Reduced
    ) {
        self.base = base
        self.interval = interval
        self.clock = clock
        self.reducing = reducing
    }
}

extension AsyncThrottleSequence: AsyncSequence {
    public typealias Element = Reduced
    
    public struct Iterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        var last: C.Instant?
        let interval: C.Instant.Duration
        let clock: C
        let reducing: @Sendable (Reduced?, Base.Element) async -> Reduced
        
        init(
            _ base: Base.AsyncIterator,
            interval: C.Instant.Duration,
            clock: C,
            reducing: @Sendable @escaping (Reduced?, Base.Element) async -> Reduced
        ) {
            self.base = base
            self.interval = interval
            self.clock = clock
            self.reducing = reducing
        }
        
        @concurrent
        public mutating func next() async rethrows -> Reduced? {
            var reduced: Reduced?
            let start = last ?? clock.now
            
            repeat {
                guard let element = try await base.next() else {
                    if reduced != nil, let last {
                        let amount = interval - last.duration(to: clock.now)
                        if amount > .zero {
                            try? await clock.sleep(
                                until: clock.now.advanced(by: amount),
                                tolerance: nil
                            )
                        }
                    }
                    
                    return reduced
                }
                
                let reduction = await reducing(reduced, element)
                let now = clock.now
                if start.duration(to: now) >= interval || last == nil {
                    last = now
                    return reduction
                } else {
                    reduced = reduction
                }
            } while true
        }
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base.makeAsyncIterator(), interval: interval, clock: clock, reducing: reducing)
    }
}

extension AsyncThrottleSequence: Sendable where Base: Sendable, Element: Sendable {}
