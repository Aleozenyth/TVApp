import TVAppCore
import XCTest

final class HTMLStripperTests: XCTestCase {

    func test_strip_removesTagsAndDecodesCommonEntities() async {
        let html = "<p>Breaking <b>Bad</b> &amp; <i>Better Call Saul</i></p>"
        let result = await HTMLStripper.strip(html)
        XCTAssertEqual(result, "Breaking Bad & Better Call Saul")
    }

    func test_strip_emptyInput_returnsEmptyString() async {
        let result = await HTMLStripper.strip("")
        XCTAssertEqual(result, "")
    }

    func test_strip_plainTextWithoutTags_isUnchanged() async {
        let plain = "No markup here."
        let result = await HTMLStripper.strip(plain)
        XCTAssertEqual(result, plain)
    }
}
