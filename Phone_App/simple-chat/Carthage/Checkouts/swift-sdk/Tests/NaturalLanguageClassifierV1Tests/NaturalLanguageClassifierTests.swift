/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

// swiftlint:disable function_body_length force_try force_unwrapping superfluous_disable_command

import XCTest
import Foundation
import NaturalLanguageClassifierV1

class NaturalLanguageClassifierTests: XCTestCase {

    // Several tests depend upon an already-trained classifier. If the classifier does not exist then use the
    // API Explorer (watson-api-explorer.mybluemix.net) to create a classifier using the `trained_meta.txt`
    // and `weather_data_train.csv` files. Be sure to update the `trainedClassifierId` property below!

    private var naturalLanguageClassifier: NaturalLanguageClassifier!
    private let trainedClassifierId = "33c2fbx273-nlc-11743"
    private let trainedClassifierName = "swift-sdk-test-classifier"
    private let temporaryClassifierName = "swift-sdk-temporary-classifier"

    private var metadataFile: URL!
    private var metadataFileEmpty: URL!
    private var metadataFileMissingName: URL!
    private var trainingFile: URL!

    // MARK: - Test Configuration

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        instantiateNaturalLanguageClassifier()
        loadClassifierFiles()
    }

    static var allTests: [(String, (NaturalLanguageClassifierTests) -> () throws -> Void)] {
        return [
            ("testCreateAndDelete", testCreateAndDelete),
            ("testCreateAndDeleteClassifierWithoutOptionalName", testCreateAndDeleteClassifierWithoutOptionalName),
            ("testGetAllClassifiers", testGetAllClassifiers),
            ("testGetClassifier", testGetClassifier),
            ("testClassify", testClassify),
            ("testCreateClassifierWithMissingMetadata", testCreateClassifierWithMissingMetadata),
            ("testClassifyEmptyString", testClassifyEmptyString),
            ("testClassifyWithInvalidClassifier", testClassifyWithInvalidClassifier),
            ("testDeleteInvalidClassifier", testDeleteInvalidClassifier),
            ("testGetInvalidClassifier", testGetInvalidClassifier),
        ]
    }

    /** Instantiate Natural Langauge Classifier instance. */
    func instantiateNaturalLanguageClassifier() {
        let username = Credentials.NaturalLanguageClassifierUsername
        let password = Credentials.NaturalLanguageClassifierPassword
        naturalLanguageClassifier = NaturalLanguageClassifier(username: username, password: password)
        naturalLanguageClassifier.defaultHeaders["X-Watson-Learning-Opt-Out"] = "true"
        naturalLanguageClassifier.defaultHeaders["X-Watson-Test"] = "true"
    }

    /** Fail false negatives. */
    func failWithError(error: Error) {
        XCTFail("Positive test failed with error: \(error)")
    }

    /** Fail false positives. */
    func failWithResult<T>(result: T) {
        XCTFail("Negative test returned a result.")
    }

    /** Fail false positives. */
    func failWithResult() {
        XCTFail("Negative test returned a result.")
    }

    /** Wait for expectations. */
    func waitForExpectations(timeout: TimeInterval = 20.0) {
        waitForExpectations(timeout: timeout) { error in
            XCTAssertNil(error, "Timeout")
        }
    }

    // MARK: - Helper Functions

    func loadClassifierFiles() {
        metadataFile = loadClassifierFile(name: "training_meta", withExtension: "txt")
        metadataFileEmpty = loadClassifierFile(name: "training_meta_empty", withExtension: "txt")
        metadataFileMissingName = loadClassifierFile(name: "training_meta_missing_name", withExtension: "txt")
        trainingFile = loadClassifierFile(name: "weather_data_train", withExtension: "csv")
        guard metadataFile != nil, metadataFileEmpty != nil, metadataFileMissingName != nil, trainingFile != nil else {
            XCTFail("Failed to load files required to create a classifier.")
            return
        }
    }

    /** Load a file used when creating a classifier. */
    func loadClassifierFile(name: String, withExtension: String) -> URL? {
        #if os(iOS)
            let bundle = Bundle(for: type(of: self))
            guard let url = bundle.url(forResource: name, withExtension: withExtension) else { return nil }
        #else
            let url = URL(fileURLWithPath: "Tests/NaturalLanguageClassifierV1Tests/" + name + "." + withExtension)
        #endif
        return url
    }

    // MARK: - Positive Tests

    func testCreateAndDelete() {
        let expectation = self.expectation(description: "Create and delete a classifier")
        naturalLanguageClassifier.createClassifier(fromMetadataFile: metadataFile, andTrainingFile: trainingFile, failure: failWithError) {
            classifier in
            XCTAssertEqual(classifier.name, self.temporaryClassifierName)
            XCTAssertEqual(classifier.language, "en")
            self.naturalLanguageClassifier.deleteClassifier(withID: classifier.classifierId, failure: self.failWithError) {
                expectation.fulfill()
            }
        }
        waitForExpectations()
    }

    func testCreateAndDeleteClassifierWithoutOptionalName() {
        let expectation = self.expectation(description: "Create and delete a classifier with no name.")
        naturalLanguageClassifier.createClassifier(fromMetadataFile: metadataFileMissingName, andTrainingFile: trainingFile, failure: failWithError) {
            classifier in
            XCTAssertEqual(classifier.name, nil)
            XCTAssertEqual(classifier.language, "en")
            self.naturalLanguageClassifier.deleteClassifier(withID: classifier.classifierId, failure: self.failWithError) {
                expectation.fulfill()
            }
        }
        waitForExpectations()
    }

    func testGetAllClassifiers() {
        let expectation = self.expectation(description: "Get classifiers.")
        naturalLanguageClassifier.getClassifiers(failure: failWithError) { classifiers in
            XCTAssertGreaterThan(classifiers.count, 0)
            expectation.fulfill()
        }
        waitForExpectations()
    }

    func testGetClassifier() {
        let expectation = self.expectation(description: "Get classifier.")
        naturalLanguageClassifier.getClassifier(withID: trainedClassifierId, failure: failWithError) { classifier in
            XCTAssertEqual(classifier.name, self.trainedClassifierName)
            expectation.fulfill()
        }
        waitForExpectations()
    }

    func testClassify() {
        let expectation = self.expectation(description: "Classify text.")
        naturalLanguageClassifier.classify("How hot will it be today?", withClassifierID: trainedClassifierId, failure: failWithError) {
            classification in
            XCTAssertEqual(classification.topClass, "temperature")
            XCTAssertEqual(classification.classes.count, 2)
            expectation.fulfill()
        }
        waitForExpectations()
    }

    // MARK: - Negative Tests

    func testCreateClassifierWithMissingMetadata() {
        let expectation = self.expectation(description: "Create a classifier with missing metadata")
        let failure = { (error: Error) in expectation.fulfill() }
        naturalLanguageClassifier.createClassifier(
            fromMetadataFile: metadataFileEmpty,
            andTrainingFile: trainingFile,
            failure: failure,
            success: failWithResult)
        waitForExpectations()
    }

    func testClassifyEmptyString() {
        let expectation = self.expectation(description: "Classify and empty string.")
        let failure = { (error: Error) in expectation.fulfill() }
        naturalLanguageClassifier.classify("", withClassifierID: trainedClassifierId, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    func testClassifyWithInvalidClassifier() {
        let expectation = self.expectation(description: "Classify using an invalid classifier id.")
        let failure = { (error: Error) in expectation.fulfill() }
        naturalLanguageClassifier.classify(
            "How hot will it be today?",
            withClassifierID: "this-is-an-invalid-classifier-id",
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()
    }

    func testDeleteInvalidClassifier() {
        let expectation = self.expectation(description: "Delete a classifier using an invalid classifier id.")
        let failure = { (error: Error) in expectation.fulfill() }
        naturalLanguageClassifier.deleteClassifier(
            withID: "this-is-an-invalid-classifier-id",
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()
    }

    func testGetInvalidClassifier() {
        let expectation = self.expectation(description: "Get classifier using an invalid classifier id.")
        let failure = { (error: Error) in expectation.fulfill() }
        naturalLanguageClassifier.getClassifier(
            withID: "this-is-an-invalid-classifier-id",
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()
    }
}
