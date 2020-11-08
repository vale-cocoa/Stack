//
//  StackSliceTests.swift
//  StackTests
//
//  Created by Valeriano Della Longa on 01/11/2020.
//

import XCTest
@testable import Stack

final class StackSliceTests: XCTestCase {
    var sut: StackSlice<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = StackSlice<Int>()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - init test
    func testInit() {
        sut = StackSlice<Int>()
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.count, 0)
        XCTAssertNil(sut.first)
        XCTAssertNil(sut.last)
        XCTAssertTrue(sut._slice.isEmpty)
        XCTAssertTrue(sut.base.isEmpty)
        XCTAssertNil(sut.base.storage)
        XCTAssertTrue(sut.bounds.isEmpty)
        XCTAssertEqual(sut.bounds.lowerBound, 0)
        XCTAssertEqual(sut.bounds.lowerBound, sut.bounds.upperBound)
    }
    
    func testInitBaseBounds() {
        let base: Stack<Int> = [1, 2, 3, 4, 5]
        for i in base.startIndex..<base.endIndex {
            for j in (i + 1)..<base.endIndex where j < (base.endIndex - 1) {
                let bounds = i..<j
                sut = StackSlice(base: base, bounds: bounds)
                XCTAssertNotNil(sut)
                XCTAssertEqual(sut.bounds, bounds)
                XCTAssertEqual(sut.base, base)
                XCTAssertEqual(sut.count, bounds.count)
                XCTAssertEqual(Array(sut._slice), Array(Slice(base: base, bounds: bounds)))
            }
        }
    }
    
    func testInitRepeatingCount() {
        sut = StackSlice(repeating: 10, count: 0)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        
        sut = StackSlice(repeating: 10, count: 10)
        XCTAssertNotNil(sut)
        XCTAssertEqual(Array(sut), Array(repeating: 10, count: 10))
        XCTAssertEqual(sut.bounds, 0..<10)
    }
    
    func testInitFromSequence() {
        sut = StackSlice([])
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        
        sut = StackSlice([1, 2, 3, 4, 5])
        XCTAssertNotNil(sut)
        XCTAssertEqual(Array(sut), [1, 2, 3, 4, 5])
        XCTAssertEqual(sut.bounds, 0..<5)
    }
    
    // MARK: - Test indexes
    func testStartAndEndIndices() {
        let base: Stack<Int> = [1, 2, 3, 4, 5]
        for i in base.startIndex..<base.endIndex {
            for j in (i + 1)..<base.endIndex where j < (base.endIndex - 1) {
                let bounds = i..<j
                sut = base[bounds]
                XCTAssertNotNil(sut)
                XCTAssertEqual(sut.bounds, bounds)
                XCTAssertEqual(sut.base, base)
                XCTAssertEqual(sut.count, bounds.count)
                XCTAssertEqual(Array(sut._slice), Array(Slice(base: base, bounds: bounds)))
                XCTAssertEqual(sut.startIndex, sut._slice.startIndex)
                XCTAssertEqual(sut.endIndex, sut._slice.endIndex)
                XCTAssertLessThanOrEqual(sut.startIndex, sut.endIndex)
                XCTAssertEqual(sut.indices, sut._slice.indices)
                XCTAssertEqual(sut.indices, sut.bounds)
            }
        }
    }
    
    // MARK: - subscripting tests
    func testSubscriptPosition() {
        let base: Stack<Int> = [1, 2, 3, 4, 5]
        sut = base[1..<4]
        for idx in sut.startIndex..<sut.endIndex {
            XCTAssertEqual(sut[idx], base[idx])
        }
        
        for idx in sut.startIndex..<sut.endIndex {
            sut[idx] *= 10
        }
        for idx in sut.startIndex..<sut.endIndex {
            XCTAssertEqual(sut[idx], base[idx] * 10)
        }
        
        // value semantics for mutation via subscript:
        assertAreDifferentValuesAndHaveDifferentStorage(lhs: sut, rhs: base)
    }
    
    func testSubscriptBounds() {
        let base: Stack<Int> = [1, 2, 3, 4, 5]
        sut = base[1..<4]
        
        var resliced = sut[2...3]
        XCTAssertEqual(resliced.base, base)
        for idx in resliced.startIndex..<resliced.endIndex {
            XCTAssertEqual(resliced[idx], base[idx])
        }
        
        for idx in resliced.startIndex..<resliced.endIndex {
            resliced[idx] *= 10
        }
        for idx in resliced.startIndex..<resliced.endIndex {
            XCTAssertEqual(resliced[idx], base[idx] * 10)
        }
        // value semantics for mutation of slice:
        assertAreDifferentValuesAndHaveDifferentStorage(lhs: sut, rhs: resliced)
        assertAreDifferentValuesAndHaveDifferentStorage(lhs: resliced, rhs: base)
        
        // value semantics for mutation via subscript:
        sut[1..<4] = resliced
        assertAreDifferentValuesAndHaveDifferentStorage(lhs: sut, rhs: base)
    }
    
    // MARK: - Additional tests
    // There is no need to further test other methods since
    // they just wrap Slice<Stack<Element>>.
    
    // MARK: - withContiguousStorageIfAvailable and withContiguousMutableStorageIfAvailable tests
    func testWithContiguousMutableStorageIfAvailable() {
        let original: Stack<Int> = [1, 2, 3, 4, 5]
        sut = original[1..<5]
        
        XCTAssertNotNil(sut
            .withContiguousMutableStorageIfAvailable { buff in
                // In here subscripting the buffer is 0 based!
                buff[0] = 10
            }
        )
        XCTAssertEqual(sut[1], 10)
        XCTAssertEqual(original[1], 2)
    }
    
    func testWithContiguousStorageIfAvailable() {
        let original: Stack<Int> = [1, 2, 3, 4, 5]
        sut = original[1..<4]
        let result: Array<Int>? = sut
            .withContiguousStorageIfAvailable { Array($0) }
        XCTAssertNotNil(result)
        XCTAssertEqual(result, Array(sut))
    }
    
}

