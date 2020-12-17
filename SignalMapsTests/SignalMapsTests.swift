//
//  SignalMapsTests.swift
//  SignalMapsTests
//
//  Created by Matthew Roche on 17/12/2020.
//

import XCTest

@testable import SignalMaps

import Mockingjay

class SignalMapsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLogin() throws {
        let expectation = XCTestExpectation(description: "Successfully logs in")
        let uriValue = "https://www.simplesignal.co.uk/v1/auth/login/"
        let data: NSDictionary = [
            "auth_token": "testToken"
        ]
        self.stub(uri(uriValue), json(data, status: 200))
        let authController = AuthorisationController()
        authController.login(
            username: "testUser",
            password: "testPassword",
            serverAddress: "https://www.simplesignal.co.uk") { result in
            switch result {
            case .success(let newUser):
                XCTAssertEqual(newUser.authCode, "testToken")
                XCTAssertEqual(newUser.is2FAUser, false)
                XCTAssertEqual(newUser.serverAddress, "https://www.simplesignal.co.uk")
                XCTAssertEqual(newUser.userName, "testUser")
                XCTAssertEqual(newUser.deviceName, nil)
                expectation.fulfill()
            default:
                print(result)
                return
            }
            
        }
        
        wait(for: [expectation], timeout: 2.0)
    }

}
