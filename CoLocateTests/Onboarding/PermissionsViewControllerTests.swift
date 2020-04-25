//
//  PermissionsViewControllerTests.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import CoreBluetooth
import XCTest
@testable import CoLocate

class PermissionsViewControllerTests: TestCase {
    
    func testBluetoothNotDetermined_callsContinueHandlerWhenBothGranted() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let nursery = BluetoothNurseryDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble, remoteNotificationManager: remoteNotificationManagerDouble, bluetoothNursery: nursery, uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()

        #if targetEnvironment(simulator)
        // We skip Bluetooth on the simulator.
        #else
        authManagerDouble.bluetooth = .allowed
        nursery.stateObserver?.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)
        #endif
        
        XCTAssertFalse(continued)
        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion?(.allowed)
        XCTAssertTrue(continued)
    }

    func testBluetoothNotDetermined_callsContinueHandlerOnChangeToDenied() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This test can't run in the simulator.")
        #else
        
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .notDetermined)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let nursery = BluetoothNurseryDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble, remoteNotificationManager: remoteNotificationManagerDouble, bluetoothNursery: nursery, uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()
        
        authManagerDouble.bluetooth = .denied
        nursery.stateObserver?.btleListener(BTLEListenerDouble(), didUpdateState: .poweredOn)

        XCTAssert(continued)
        
        #endif
    }
    
    func testBluetoothAllowed_promptsForNotificationWhenShown() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble, remoteNotificationManager: remoteNotificationManagerDouble, bluetoothNursery: BluetoothNurseryDouble(), uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        XCTAssertFalse(continued)
        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion?(.allowed)
        XCTAssertTrue(continued)
    }

    func testPreventsDoubleSubmit() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let vc = PermissionsViewController.instantiate()
        vc.inject(authManager: authManagerDouble, remoteNotificationManager: remoteNotificationManagerDouble, bluetoothNursery: BluetoothNurseryDouble(), uiQueue: QueueDouble()) {}

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)
        XCTAssertTrue(vc.activityIndicator.isHidden)
        XCTAssertFalse(vc.continueButton.isHidden)

        vc.didTapContinue()
        
        XCTAssertFalse(vc.activityIndicator.isHidden)
        XCTAssertTrue(vc.activityIndicator.isAnimating)
        XCTAssertTrue(vc.continueButton.isHidden)
    }
    
    func testBluetoothAlreadyDetermined() {
        let authManagerDouble = AuthorizationManagerDouble(bluetooth: .allowed)
        let remoteNotificationManagerDouble = RemoteNotificationManagerDouble()
        let vc = PermissionsViewController.instantiate()
        var continued = false
        vc.inject(authManager: authManagerDouble, remoteNotificationManager: remoteNotificationManagerDouble, bluetoothNursery: BluetoothNurseryDouble(), uiQueue: QueueDouble()) {
            continued = true
        }

        parentViewControllerForTests.viewControllers = [vc]
        XCTAssertNotNil(vc.view)

        vc.didTapContinue()

        XCTAssertNotNil(authManagerDouble.notificationsCompletion)
        authManagerDouble.notificationsCompletion!(.notDetermined)

        XCTAssertNotNil(remoteNotificationManagerDouble.requestAuthorizationCompletion)
        remoteNotificationManagerDouble.requestAuthorizationCompletion?(.success(true))

        XCTAssert(continued)
    }

}

fileprivate struct DummyBTLEListener: BTLEListener {
    func start(stateDelegate: BTLEListenerStateDelegate?, delegate: BTLEListenerDelegate?) { }
    func connect(_ peripheral: BTLEPeripheral) { }
}
