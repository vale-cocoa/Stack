//
//  Helpers.swift
//  StackTests
//
//  Created by Valeriano Della Longa on 2020/11/03.
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

import XCTest
import CircularBuffer
@testable import Stack

struct SequenceImplementingWithContiguousStorage: Sequence {
    let base: Array<Int>
    
    typealias Element = Int
    
     typealias Iterator = AnyIterator<Int>
    
    func makeIterator() -> Iterator {
        var idx = 0
        
        return AnyIterator<Int> {
            guard idx < base.count else { return nil }
            
            defer { idx += 1 }
            
            return base[idx]
        }
    }
    
    func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Int>) throws -> R) rethrows -> R? {
        
        return try base.withContiguousStorageIfAvailable(body)
    }
    
}

protocol EquatableCollectionUsingCircularBuffer: Collection where Element: Equatable {
    var storage: CircularBuffer<Element>? { get }
}

extension Stack: EquatableCollectionUsingCircularBuffer where Element: Comparable { }

func assertAreDifferentValuesAndHaveDifferentStorage<C: EquatableCollectionUsingCircularBuffer, D: EquatableCollectionUsingCircularBuffer>(lhs: C, rhs: D, file: StaticString = #file, line: UInt = #line) where C.Element == D.Element {
    XCTAssertNotEqual(Array(lhs), Array(rhs), "copy contains same elements of original after mutation", file: file, line: line)
    XCTAssertFalse(lhs.storage === rhs.storage, "copy has same storage instance of original", file: file, line: line)
}


