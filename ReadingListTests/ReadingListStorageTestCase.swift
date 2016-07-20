/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import ReadingList
import Foundation
import Shared

import XCTest


class ReadingListStorageTestCase: XCTestCase {
    var storage: ReadingListStorage!

    override func setUp() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        if FileManager.default().fileExists(atPath: "\(path)/ReadingList.db") {
            do {
                try FileManager.default().removeItem(atPath: "\(path)/ReadingList.db")
            } catch _ {
                XCTFail("Cannot remove old \(path)/ReadingList.db")
            }
        }
        storage = ReadingListSQLStorage(path: "\(path)/ReadingList.db")
    }

    func testCreateRecord() {
        let result = storage.createRecord(withURL: "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance", title: "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma", addedBy: "Stefan's iPhone")
        switch result {
        case .failure(let error):
            XCTFail(error.description)
        case .success(let result):
            XCTAssertEqual(result.value.url, "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance")
            XCTAssertEqual(result.value.title, "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma")
            XCTAssertEqual(result.value.addedBy, "Stefan's iPhone")
            XCTAssertEqual(result.value.unread, true)
            XCTAssertEqual(result.value.archived, false)
            XCTAssertEqual(result.value.favorite, false)
        }
    }

    func testGetRecordWithURL() {
        let result1 = storage.createRecord(withURL: "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance", title: "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma", addedBy: "Stefan's iPhone")
        switch result1 {
        case .failure(let error):
            XCTFail(error.description)
        case .success( _):
            break
        }

        let result2 = storage.getRecord(withURL: "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance")
        switch result2 {
        case .failure(let error):
            XCTFail(error.description)
        case .success( _):
            XCTAssert(result1.successValue == result2.successValue!)
        }
    }

    func testGetUnreadRecords() {
        // Create 3 records, mark the 2nd as read.
        createRecord(withURL: "http://localhost/article1", title: "Test 1", addedBy: "Stefan's iPhone")
        let createResult2 = createRecord(withURL: "http://localhost/article2", title: "Test 2", addedBy: "Stefan's iPhone")
        createRecord(withURL: "http://localhost/article3", title: "Test 3", addedBy: "Stefan's iPhone")
        if let record = createResult2.successValue {
            updateRecord(record, unread: false)
        }

        // Get all unread records, make sure we only get the first and last
        let getUnreadResult = storage.getUnreadRecords()
        if let records = getUnreadResult.successValue {
            XCTAssertEqual(2, records.count)
            for record in records {
                XCTAssert(record.title == "Test 1" || record.title == "Test 3")
                XCTAssertEqual(record.unread, true)
            }
        }
    }

    func testGetAllRecords() {
        createRecord(withURL: "http://localhost/article1", title: "Test 1", addedBy: "Stefan's iPhone")
        let createResult2 = createRecord(withURL: "http://localhost/article2", title: "Test 2", addedBy: "Stefan's iPhone")
        createRecord(withURL: "http://localhost/article3", title: "Test 3", addedBy: "Stefan's iPhone")
        if let record = createResult2.successValue {
            updateRecord(record, unread: false)
        }

        let getAllResult = storage.getAllRecords()
        if let records = getAllResult.successValue {
            XCTAssertEqual(3, records.count)
        }
    }

    func testGetNewRecords() {
        createRecord(withURL: "http://localhost/article1", title: "Test 1", addedBy: "Stefan's iPhone")
        createRecord(withURL: "http://localhost/article2", title: "Test 2", addedBy: "Stefan's iPhone")
        createRecord(withURL: "http://localhost/article3", title: "Test 3", addedBy: "Stefan's iPhone")
        let getAllResult = getAllRecords()
        if let records = getAllResult.successValue {
            XCTAssertEqual(3, records.count)
        }
        // TODO When we are able to create records coming from the server, we can extend this test to see if we query correctly
    }

    func testDeleteRecord() {
        let result1 = storage.createRecord(withURL: "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance", title: "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma", addedBy: "Stefan's iPhone")
        switch result1 {
        case .failure(let error):
            XCTFail(error.description)
        case .success(_):
            break
        }

        let result2 = storage.deleteRecord(result1.successValue!)
        switch result2 {
        case .failure(let error):
            XCTFail(error.description)
        case .success:
            break
        }

        let result3 = storage.getRecord(withURL: "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance")
        switch result3 {
        case .failure(let error):
            XCTFail(error.description)
        case .success(let result):
            XCTAssert(result.value == nil)
        }
    }

    func testDeleteAllRecords() {
        createRecord(withURL: "http://localhost/article1", title: "Test 1", addedBy: "Stefan's iPhone")
        createRecord(withURL: "http://localhost/article2", title: "Test 2", addedBy: "Stefan's iPhone")
        createRecord(withURL: "http://localhost/article3", title: "Test 3", addedBy: "Stefan's iPhone")

        let getAllResult1 = storage.getAllRecords()
        if let records = getAllResult1.successValue {
            XCTAssertEqual(3, records.count)
        }

        deleteAllRecords()

        let getAllResult2 = getAllRecords()
        if let records = getAllResult2.successValue {
            XCTAssertEqual(0, records.count)
        }
    }

    func testUpdateRecord() {
        let result = createRecord(withURL: "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance", title: "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma", addedBy: "Stefan's iPhone")
        if let record = result.successValue {
            XCTAssertEqual(record.url, "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance")
            XCTAssertEqual(record.title, "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma")
            XCTAssertEqual(record.addedBy, "Stefan's iPhone")
            XCTAssertEqual(record.unread, true)
            XCTAssertEqual(record.archived, false)
            XCTAssertEqual(record.favorite, false)

            let result = updateRecord(record, unread: false)
            if let record = result.successValue! {
                XCTAssertEqual(record.url, "http://www.anandtech.com/show/9117/analyzing-intel-core-m-performance")
                XCTAssertEqual(record.title, "Analyzing Intel Core M Performance: How 5Y10 can beat 5Y71 & the OEMs' Dilemma")
                XCTAssertEqual(record.addedBy, "Stefan's iPhone")
                XCTAssertEqual(record.unread, false)
                XCTAssertEqual(record.archived, false)
                XCTAssertEqual(record.favorite, false)
            }
        }
    }

    // Helpers that croak if the storage call was not succesful

    func createRecord(withURL url: String, title: String, addedBy: String) -> Maybe<ReadingListClientRecord> {
        let result = storage.createRecord(withURL: url, title: title, addedBy: addedBy)
        XCTAssertTrue(result.isSuccess)
        return result
    }

    func deleteAllRecords() -> Maybe<Void> {
        let result = storage.deleteAllRecords()
        XCTAssertTrue(result.isSuccess)
        return result
    }

    func getAllRecords() -> Maybe<[ReadingListClientRecord]> {
        let result = storage.getAllRecords()
        XCTAssertTrue(result.isSuccess)
        return result
    }

    func updateRecord(_ record: ReadingListClientRecord, unread: Bool) -> Maybe<ReadingListClientRecord?> {
        let result = storage.updateRecord(record, unread: unread)
        XCTAssertTrue(result.isSuccess)
        return result
    }
}
