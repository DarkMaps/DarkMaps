//
//  SignalMapsTests.swift
//  SignalMapsTests
//
//  Created by Matthew Roche on 17/12/2020.
//

import XCTest

@testable import DarkMaps

import Mockingjay

class SimpleSignalSwiftAuthAPITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLogin() throws {
        let expectation = XCTestExpectation(description: "Successfully logs in")
        let uriValue = "https://api.dark-maps.com/v1/auth/login/"
        let data: NSDictionary = [
            "auth_token": "testToken"
        ]
        self.stub(uri(uriValue), json(data, status: 200))
        let authController = AuthorisationController()
        authController.login(
            username: "testUser",
            password: "testPassword",
            serverAddress: "https://api.dark-maps.com") { result in
            switch result {
            case .success(let newUser):
                XCTAssertEqual(newUser.authCode, "testToken")
                XCTAssertEqual(newUser.is2FAUser, false)
                XCTAssertEqual(newUser.serverAddress, "https://api.dark-maps.com")
                XCTAssertEqual(newUser.userName, "testUser")
                XCTAssertEqual(newUser.deviceId, 1)
                expectation.fulfill()
            default:
                print(result)
                return
            }
            
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSubmit2FA() throws {
        let expectation = XCTestExpectation(description: "Successfully logs in")
        let uriValue = "https://api.dark-maps.com/v1/auth/login/code/"
        let data: NSDictionary = [
            "auth_token": "testToken"
        ]
        self.stub(uri(uriValue), json(data, status: 200))
        let authController = AuthorisationController()
        authController.submitTwoFactor(
            username: "testUser",
            code: "1234",
            ephemeralToken: "testEphemeralToken",
            serverAddress: "https://api.dark-maps.com") { result in
            switch result {
            case .success(let newUser):
                XCTAssertEqual(newUser.authCode, "testToken")
                XCTAssertEqual(newUser.is2FAUser, true)
                XCTAssertEqual(newUser.serverAddress, "https://api.dark-maps.com")
                XCTAssertEqual(newUser.userName, "testUser")
                XCTAssertEqual(newUser.deviceId, 1)
                expectation.fulfill()
            default:
                print(result)
                return
            }
            
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testActivate2FA() throws {
        let expectation = XCTestExpectation(description: "Successfully activates 2FA")
        let uriValue = "https://api.dark-maps.com/v1/auth/app/activate/"
        let data: NSDictionary = [
            "qr_link": "otpauth://totp/myApplication:test%40test.co.uk?secret=AVYSQYWDUNGQBTP2&issuer=test"
        ]
        self.stub(uri(uriValue), json(data, status: 200))
        let authController = AuthorisationController()
        authController.request2FAQRCode(
            authToken: "testAuthToken",
            serverAddress: "https://api.dark-maps.com") {result in
            switch result {
            case .success(let qrcode):
                XCTAssertEqual(qrcode, "otpauth://totp/myApplication:test%40test.co.uk?secret=AVYSQYWDUNGQBTP2&issuer=test")
                expectation.fulfill()
            default:
                print(result)
                return
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testConfirm2FA() throws {
        let expectation = XCTestExpectation(description: "Successfully confirms 2FA")
        let uriValue = "https://api.dark-maps.com/v1/auth/app/activate/confirm/"
        let data: NSDictionary = [
            "backup_codes": [
                "test_backup_code"
            ]
        ]
        self.stub(uri(uriValue), json(data, status: 200))
        let authController = AuthorisationController()
        authController.confirm2FA(
            code: "1234",
            authToken: "testAuthToken",
            serverAddress: "https://api.dark-maps.com") {result in
            switch result {
            case .success(let backupCodes):
                XCTAssertEqual(backupCodes.first, "test_backup_code")
                expectation.fulfill()
            default:
                print(result)
                return
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDeactivate2FA() throws {
        let expectation = XCTestExpectation(description: "Successfully deactivates 2FA")
        let uriValue = "https://api.dark-maps.com/v1/auth/app/deactivate/"
        self.stub(uri(uriValue), http(204))
        let authController = AuthorisationController()
        authController.deactivate2FA(
            code: "1234",
            authToken: "testAuthToken",
            serverAddress: "https://api.dark-maps.com") {result in
            switch result {
            case .success():
                expectation.fulfill()
            default:
                print(result)
                return
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLogOut() throws {
        let expectation = XCTestExpectation(description: "Successfully logs user out")
        let uriValue = "https://api.dark-maps.com/v1/auth/logout/"
        self.stub(uri(uriValue), http(204))
        let authController = AuthorisationController()
        authController.logUserOut(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com") {result in
            switch result {
            case .success():
                expectation.fulfill()
            default:
                print(result)
                return
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDeleteUserAccount() throws {
        let expectation = XCTestExpectation(description: "Successfully deletes account")
        let uriValue = "https://api.dark-maps.com/v1/auth/users/me/"
        self.stub(uri(uriValue), http(204))
        let authController = AuthorisationController()
        authController.deleteUserAccount(
            currentPassword: "testPassword",
            authToken: "testAuthToken",
            serverAddress: "https://api.dark-maps.com") {result in
            switch result {
            case .success():
                expectation.fulfill()
            default:
                print(result)
                return
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }

}
