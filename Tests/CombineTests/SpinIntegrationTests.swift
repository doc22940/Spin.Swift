//
//  SpinIntegrationTests.swift
//  
//
//  Created by Thibault Wittemberg on 2019-12-31.
//

import Combine
import SpinCombine
import SpinCommon
import XCTest

fileprivate enum StringAction {
    case append(String)
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class SpinIntegrationTests: XCTestCase {

    func test_multiple_feedbacks_produces_incremental_states_while_executed_on_default_executer() throws {

        // Given: an initial state, effects and a reducer
        var counterA = 0
        let effectA = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterA += 1
            let counter = counterA
            return Just<StringAction>(.append("_a\(counter)")).eraseToAnyPublisher()
        }

        var counterB = 0
        let effectB = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterB += 1
            let counter = counterB
            return Just<StringAction>(.append("_b\(counter)")).eraseToAnyPublisher()
        }

        var counterC = 0
        let effectC = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterC += 1
            let counter = counterC
            return Just<StringAction>(.append("_c\(counter)")).eraseToAnyPublisher()
        }

        let reducerFunction = { (state: String, action: StringAction) -> String in
            switch action {
            case .append(let suffix):
                return state+suffix
            }
        }

        // When: spinning the feedbacks and the reducer on the default executer
        let spin = Spinner
            .initialState("initialState")
            .feedback(Feedback(effect: effectA))
            .feedback(Feedback(effect: effectB))
            .feedback(Feedback(effect: effectC))
            .reducer(Reducer(reducerFunction))

        let recorder = AnyPublisher<String, Never>.stream(from: spin)
            .output(in: (0...6))
            .record()

        let receivedElements = try wait(for: recorder.elements, timeout: 5)

        // Then: the states is constructed incrementally
        XCTAssertEqual(receivedElements, ["initialState",
                                          "initialState_a1",
                                          "initialState_a1_b1",
                                          "initialState_a1_b1_c1",
                                          "initialState_a1_b1_c1_a2",
                                          "initialState_a1_b1_c1_a2_b2",
                                          "initialState_a1_b1_c1_a2_b2_c2"])
    }

    func test_multiple_feedbacks_produces_incremental_states_while_executed_on_default_executer_using_declarative_syntax() throws {

        // Given: an initial state, effect and a reducer
        var counterA = 0
        let effectA = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterA += 1
            let counter = counterA
            return Just<StringAction>(.append("_a\(counter)")).eraseToAnyPublisher()
        }

        var counterB = 0
        let effectB = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterB += 1
            let counter = counterB
            return Just<StringAction>(.append("_b\(counter)")).eraseToAnyPublisher()
        }

        var counterC = 0
        let effectC = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterC += 1
            let counter = counterC
            return Just<StringAction>(.append("_c\(counter)")).eraseToAnyPublisher()
        }

        let reducerFunction = { (state: String, action: StringAction) -> String in
            switch action {
            case .append(let suffix):
                return state+suffix
            }
        }

        let spin = Spin<String, StringAction>(initialState: "initialState", reducer: Reducer(reducerFunction)) {
            Feedback(effect: effectA).execute(on: DispatchQueue.main.eraseToAnyScheduler())
            Feedback(effect: effectB).execute(on: DispatchQueue.main.eraseToAnyScheduler())
            Feedback(effect: effectC).execute(on: DispatchQueue.main.eraseToAnyScheduler())
        }

        // When: spinning the feedbacks and the reducer on the default executer
        let recorder = AnyPublisher<String, Never>.stream(from: spin)
            .output(in: (0...6))
            .record()

        let receivedElements = try wait(for: recorder.elements, timeout: 5)

        // Then: the states is constructed incrementally
        XCTAssertEqual(receivedElements, ["initialState",
                                          "initialState_a1",
                                          "initialState_a1_b1",
                                          "initialState_a1_b1_c1",
                                          "initialState_a1_b1_c1_a2",
                                          "initialState_a1_b1_c1_a2_b2",
                                          "initialState_a1_b1_c1_a2_b2_c2"])
    }
}
