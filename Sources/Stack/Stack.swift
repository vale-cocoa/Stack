//
//  Stack.swift
//  Stack
//
//  Created by Valeriano Della Longa on 2020/11/01.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Queue
import CircularBuffer

/// A Collection —with value semantics— implementing queue *LIFO* (last in, first out) functionalities.
///
/// `Stack` implements `push(_:)`, `push(contentsOf:)` and `pop()` matching `Queue` protocol methods
///  `enqueue(_:)`, `enqueue(contentsOf:)`, `dequeue()` for semantics reasons.
public struct Stack<Element> {
    private(set) var storage: CircularBuffer<Element>? = nil
    
    public init() { }
    
    public init<S: Sequence>(_ elements: S) where S.Iterator.Element == Element {
        self.storage = CircularBuffer(elements: elements)
        _checkForEmptyAtEndOfMutation()
    }
    
    public init(repeating repeatedValue: Element, count: Int) {
        self.storage = CircularBuffer(repeating: repeatedValue, count: count)
        _checkForEmptyAtEndOfMutation()
    }
    
}

// MARK: - Public Interface
// MARK: - Collection and MutableCollection conformance
extension Stack: Collection, MutableCollection {
    public typealias Index = Int
    
    public typealias Indices = CountableRange<Int>
    
    public typealias Iterator = IndexingIterator<Stack<Element>>
    
    public typealias SubSequence = StackSlice<Element>
    
    public var startIndex: Int { 0 }
    
    public var endIndex: Int { storage?.count ?? 0 }
    
    public var underestimatedCount: Int { storage?.count ?? 0 }
    
    public var count: Int { storage?.count ?? 0 }
    
    public var isEmpty: Bool { storage?.isEmpty ?? true }
    
    public var first: Element? { storage?.first }
    
    public func index(after i: Int) -> Int {
        i + 1
    }
    
    public func formIndex(after i: inout Int) {
        i += 1
    }
    
    public subscript(position: Int) -> Element {
        get {
            storage![position]
        }
        
        set {
            _makeUnique()
            storage![position] = newValue
        }
    }
    
    public subscript(bounds: Range<Int>) -> SubSequence {
            get {
                
                return SubSequence(base: self, bounds: bounds)
            }
        
            set {
                self.replaceSubrange(bounds, with: newValue)
            }
    }
    
    public mutating func withContiguousMutableStorageIfAvailable<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) rethrows -> R? {
        _makeUnique()
        
        // Ensure that body can't invalidate the storage or its
        // bounds by moving self into a temporary working Stack.
        // NOTE: The stack promotion optimization that keys of the
        // "stack.withContiguousMutableStorageIfAvailable"
        // semantics annotation relies on the Stack buffer not
        // being able to escape in the closure.
        // It can do this because we swap the stack buffer in self
        // with an empty buffer here.
        // Any escape via the address of self in the closure will
        // therefore escape the empty Stack.
        var work = Stack()
        (work, self) = (self, work)
        
        // Put back in place the Stack
        defer {
            (work, self) = (self, work)
            _checkForEmptyAtEndOfMutation()
        }
        
        // Invoke body taking advantage of CircularBuffer's
        // withUnsafeMutableBufferPointer(_:) method.
        // Here it's safe to force-unwrap storage on work since
        // it must not be nil having invoked _makeUnique() in the
        // beginning.
        return try work.storage!
            .withUnsafeMutableBufferPointer(body)
    }
    
    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
        guard storage != nil else {
            
            return try body(UnsafeBufferPointer<Element>(start: nil, count: 0))
        }
        
        return try storage!.withUnsafeBufferPointer(body)
    }
    
    // MARK: - Functional methods
    public func allSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        for i in startIndex..<endIndex where try predicate(storage![i]) == false {
            
            return false
        }
        
        return true
    }
    
    public func forEach(_ body: (Element) throws -> ()) rethrows {
        try storage?.forEach(body)
    }
    
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        try compactMap { try isIncluded($0) ? $0 : nil }
    }
    
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        var result = [T]()
        try storage?.forEach { element in
            let transformed = try transform(element)
            result.append(transformed)
        }
        
        return result
    }
    
    public func flatMap<SegmentOfResult>(_ transform: (Element) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult: Sequence {
        var result = [SegmentOfResult.Element]()
        try storage?.forEach {
            result.append(contentsOf: try transform($0))
        }
        
        return result
    }
    
    @available(swift, deprecated: 4.1, renamed: "compactMap(_:)", message: "Please use compactMap(_:) for the case where closure returns an optional value")
    public func flatMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        
        return try compactMap(transform)
    }
    
    public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> [T] {
        var result = [T]()
        try storage?.forEach { element in
            try transform(element).map { result.append($0) }
        }
        
        return result
    }
    
    public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Element) throws -> ()) rethrows -> Result {
        var finalResult = initialResult
        try storage?.forEach {
            try updateAccumulatingResult(&finalResult, $0)
        }
        
        return finalResult
    }
    
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Element) throws -> Result) rethrows -> Result {
        try reduce(into: initialResult) { accumulator, element in
            accumulator = try nextPartialResult(accumulator, element)
        }
    }
    
}

// MARK: - BidirectionalCollection conformance
extension Stack: BidirectionalCollection {
    public var last: Element? { storage?.last }
    
    public func index(before i: Int) -> Int {
        i - 1
    }
    
    public func formIndex(before i: inout Int) {
        i -= 1
    }
    
}

// MARK: - RandomAccessCollection conformance
extension Stack: RandomAccessCollection {
    public func index(_ i: Int, offsetBy distance: Int) -> Int {
        i + distance
    }
    
    public func index(_ i: Int, offsetBy distance: Int, limitedBy limit: Int) -> Int? {
        let l = limit - i
        
        if distance > 0 ? (l >= 0 && l < distance) : (l <= 0 && distance < l) {
            
            return nil
        }
        
        return i + distance
    }
    
    public func distance(from start: Int, to end: Int) -> Int {
        end - start
    }
    
}

// MARK: - RangeReplaceableCollection conformance
extension Stack: RangeReplaceableCollection {
    public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, Self.Element == C.Element {
        let difference = (count - subrange.count + newElements.count) - count
        let additionalCapacity = difference < 0 ? 0 : difference
        _makeUnique(additionalCapacity: additionalCapacity)
        storage!.replace(subRange: subrange, with: newElements)
        _checkForEmptyAtEndOfMutation()
    }
    
    public mutating func reserveCapacity(_ n: Int) {
        let additionalCapacity = n - count > 0 ? n - count : 0
        _makeUnique(additionalCapacity: additionalCapacity)
    }
    
    public mutating func append(_ newElement: Self.Element) {
        _makeUnique()
        storage!.append(newElement)
    }
    
    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, Self.Element == S.Iterator.Element {
        _makeUnique(additionalCapacity: newElements.underestimatedCount)
        storage!.append(contentsOf: newElements)
        _checkForEmptyAtEndOfMutation()
    }
    
    public mutating func insert(_ newElement: Self.Element, at i: Self.Index) {
        _makeUnique()
        storage!.insertAt(index: i, contentsOf: CollectionOfOne(newElement))
    }
    
    public mutating func insert<C: Collection>(contentsOf newElements: C, at i: Self.Index) where  Self.Element == C.Element {
        _makeUnique(additionalCapacity: newElements.count)
        storage!.insertAt(index: i, contentsOf: newElements)
        _checkForEmptyAtEndOfMutation()
    }
    
    public mutating func remove(at i: Self.Index) -> Self.Element {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.removeAt(index: i, count: 1, keepCapacity: false).first!
    }
    
    public mutating func removeSubrange(_ bounds: Range<Self.Index>) {
        let subrange = bounds.relative(to: indices)
        guard subrange.count > 0 else { return }
        
        _makeUnique()
        storage!.removeAt(index: subrange.lowerBound, count: subrange.count)
        _checkForEmptyAtEndOfMutation()
    }
    
    public mutating func removeFirst() -> Self.Element {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.removeFirst(1, keepCapacity: false).first!
    }
    
    public mutating func removeFirst(_ k: Int) {
        _makeUnique()
        storage!.removeFirst(k, keepCapacity: false)
        _checkForEmptyAtEndOfMutation()
    }
    
    @available(*, deprecated, renamed: "removeAll(keepingCapacity:)")
    public mutating func removeAll(keepCapacity: Bool) {
        self.removeAll(keepingCapacity: keepCapacity)
    }
    
    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        guard storage != nil else { return }
        
        _makeUnique()
        guard keepCapacity else {
            storage = nil
            
            return
        }
        
        storage!.removeAll(keepCapacity: keepCapacity)
    }
    
    @discardableResult
    public mutating func popLast() -> Element? {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.popLast()
    }
    
    @discardableResult
    public mutating func popFirst() -> Element? {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.popFirst()
    }
    
    public mutating func removeLast() -> Self.Element {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.removeLast(1).first!
    }
    
    public mutating func removeLast(_ k: Int) {
        _makeUnique()
        
        storage!.removeLast(k)
        _checkForEmptyAtEndOfMutation()
    }
    
}

// MARK: - Queue conformance
extension Stack: Queue {
    public var capacity: Int {
        storage?.capacity ?? 0
    }
    
    public var isFull: Bool {
        storage?.isFull ?? true
    }
    
    public func peek() -> Element? {
        first
    }
    
    public mutating func enqueue(_ newElement: Element) {
        push(newElement)
    }
    
    public mutating func enqueue<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
        push(contentsOf: newElements)
    }
    
    @discardableResult
    public mutating func dequeue() -> Element? {
        pop()
    }
    
}

// MARK: - Stack specific functionalities
extension Stack {
    /// Stores given element in this stack.
    ///
    /// - Parameter _: the element to store in this stack.
    /// - Complexity: amortized O(1)
    public mutating func push(_ newElement: Element) {
        _makeUnique()
        storage!.push(newElement)
    }
    
    /// Stores contents of given sequence in this stack.
    ///
    /// Equivalent to calling push(_:) repeatedly while iteratating over the elements of the given sequence.
    /// - Parameter contentsOf: a sequence conteining the eleemnts to store in this stack.
    /// - Complexity: O(*k*) where *k* is the count of elements stored in the given sequence.
    public mutating func push<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        storage!.push(contentsOf: newElements)
    }
    
    /// Removes and returns the element stored at topmost position when not empty, otherwise returns `nil`.
    ///
    /// - Returns: the element stored in the topmost position of this stack when not empty, otherwise `nil`.
    /// - Complexity: amortized O(1)
    @discardableResult
    public mutating func pop() -> Element? {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.popFirst()
    }
    
}

// MARK: - ExpressibleByArrayLiteral conformance
extension Stack: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        guard !elements.isEmpty else { return }
        
        self.storage = CircularBuffer(elements: elements)
    }
    
}

// MARK: - Equatable Conformance
extension Stack: Equatable where Element: Equatable {
    public static func == (lhs: Stack<Element>, rhs: Stack<Element>) -> Bool {
        guard lhs.storage !== rhs.storage else { return true }
        
        guard lhs.count == rhs.count else { return false }
        
        for idx in 0..<lhs.count where lhs[idx] != rhs[idx] {
            
            return false
        }
        
        return true
    }
    
}

// MARK: - Hashable Conformance
extension Stack: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        self.storage?.forEach { hasher.combine($0) }
    }
    
}

// MARK: - Codable conformance
extension Stack: Codable where Element: Codable {
    private enum CodingKeys: String, CodingKey {
        case storage
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let elements = self.map { $0 }
        
        try container.encode(elements, forKey: .storage)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let elements = try container.decode(Array<Element>.self, forKey: .storage)
        guard !elements.isEmpty else { return }
        
        self.storage = CircularBuffer(elements: elements)
    }
    
}

// MARK: CustomStringConvertible and CustomDebugStringConvertible conformances
extension Stack: CustomStringConvertible, CustomDebugStringConvertible {
    private func makeDescription(debug: Bool) -> String {
            var result = debug ? "\(String(reflecting: Stack.self))([" : "Stack["
            var first = true
            for item in self {
                if first {
                    first = false
                } else {
                    result += ", "
                }
                if debug {
                    debugPrint(item, terminator: "", to: &result)
                }
                else {
                    print(item, terminator: "", to: &result)
                }
            }
            result += debug ? "])" : "]"
            return result
        }

    public var description: String {
        return makeDescription(debug: false)
    }
    
    public var debugDescription: String {
        return makeDescription(debug: true)
    }
    
}

// MARK: - Private Interface
// MARK: - Copy on write helpers
extension Stack {
    private var _isUnique: Bool {
        mutating get {
            isKnownUniquelyReferenced(&storage)
        }
    }
    
    private mutating func _makeUnique(additionalCapacity: Int = 0) {
        if self.storage == nil {
            self.storage = CircularBuffer(capacity: additionalCapacity)
        } else if !_isUnique {
            storage = storage!.copy(additionalCapacity: additionalCapacity)
        } else if additionalCapacity > 0 {
            storage!.allocateAdditionalCapacity(additionalCapacity)
        }
    }
    
    private mutating func _checkForEmptyAtEndOfMutation() {
        if self.storage?.count == 0 {
            self.storage = nil
        }
    }
    
}
