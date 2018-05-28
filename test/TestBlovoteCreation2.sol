pragma solidity ^0.4.0;

import "../contracts/Blovote.sol";
import "../contracts/BlovoteImpl.sol";

contract TestBlovoteCreation2 {

    uint public initialBalance = 1 ether;

    Blovote blovote;
    bytes title;
    bytes qtitle;
    bytes qtitle2;
    bytes qtitle3;

    function beforeEach() public {
        string memory str = "Hey, its test survey!";
        title = bytes(str);
        str = "Hey, its test question!";
        qtitle = bytes(str);
        str = "Second test question";
        qtitle2 = bytes(str);
        str = "Third test question";
        qtitle3 = bytes(str);

        blovote = (new BlovoteImpl).value(100 wei)(address(this), title, 100);
        assert(address(blovote).balance == 100 wei);
    }

    function testAddManyQuestionsWithPoints() public {
        blovote.addQuestion(Blovote.QType.ManyFromMany, qtitle);
        blovote.addQuestion(Blovote.QType.Text, qtitle2);

        assert(blovote.getQuestionsCount() == 2);

        Blovote.QType qType1;
        bytes memory titleBytes;
        (qType1, titleBytes) = blovote.getQuestionInfo(0);
        assert(qType1 == Blovote.QType.ManyFromMany);
        assertEquals(titleBytes, qtitle);
        (qType1, titleBytes) = blovote.getQuestionInfo(1);
        assert(qType1 == Blovote.QType.Text);
        assertEquals(titleBytes, qtitle2);


        string memory str1 = "First point";
        bytes memory point1 = bytes(str1);
//        string memory str2 = "Second point";
//        bytes memory point2 = bytes(str2);
        string memory str3 = "Third point";
        bytes memory point3 = bytes(str3);
//        string memory str4 = "Fourth point";
//        bytes memory point4 = bytes(str4);


        blovote.addQuestionPoint(0, point1);
//        blovote.addQuestionPoint(1, point2);
        blovote.addQuestionPoint(0, point3);
//        blovote.addQuestionPoint(1, point4);

        assert(blovote.getQuestionPointsCount(0) == 2);
//        assert(blovote.getQuestionPointsCount(1) == 2);
        assertEquals(blovote.getQuestionPointInfo(0, 0), point1);
        assertEquals(blovote.getQuestionPointInfo(0, 1), point3);
//        assertEquals(blovote.getQuestionPointInfo(1, 0), point2);
//        assertEquals(blovote.getQuestionPointInfo(1, 1), point4);




        blovote.updateState(Blovote.State.Active);

        uint8[] memory ans1 = new uint8[](2);
        ans1[1] = 0;
        ans1[0] = 1;

        blovote.respondNumbers(ans1);


        assert(blovote.currentRespondentsCount() == 1);

        address addr;
        bytes memory ans;
        (addr, ans) = blovote.getRespondData(0, 0);

        assert(uint(ans[0]) == 1);


        string memory respStr = "My test respond";
        bytes memory textAns = bytes(respStr);
        blovote.respondText(textAns);

        assert(blovote.currentRespondentsCount() == 1);


        assert(blovote.rewardSize() == 1 wei);

    }

    function assertEquals(bytes a, bytes b) public pure returns (bool) {
        assert(a.length == b.length);
        for (uint i = 0; i < a.length; ++i) {
            assert(a[i] == b[i]);
        }
    }
}
