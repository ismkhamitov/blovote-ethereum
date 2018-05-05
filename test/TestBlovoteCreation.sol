pragma solidity ^0.4.17;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Blovote.sol";
import "../contracts/BlovoteImpl.sol";

contract TestBlovoteCreation {

    uint public initialBalance = 1 ether;

    Blovote blovote;
    bytes title;
    bytes qtitle;
    bytes qtitle2;

    function beforeEach() public {
        string memory str = "Hey, its test survey!";
        title = bytes(str);
        str = "Hey, its test question!";
        qtitle = bytes(str);
        str = "Second test question";
        qtitle2 = bytes(str);

        blovote = (new BlovoteImpl).value(100 wei)(address(this), title, 100);
    }

    function testBlovoteSurveyInitialValues() public {
        assertEquals(blovote.title(), title);
        assert(blovote.requiredRespondentsCount() == 100);
        assert(blovote.rewardSize() == 1 wei);
    }

    function testAddQuestion() public {
        blovote.addQuestion(Blovote.QType.Text, qtitle);

        assert(blovote.getQuestionsCount() == 1);

        Blovote.QType qtype;
        bytes memory titleActual;
        (qtype, titleActual) = blovote.getQuestionInfo(0);
        assert(qtype == Blovote.QType.Text);
        assertEquals(qtitle, titleActual);
    }

    function testAddManyQuestions() public {
        for (uint i = 0; i < 50; ++i) {
            blovote.addQuestion(Blovote.QType.OneFromMany, i % 2 == 0 ?  qtitle : qtitle2);
            assert(blovote.getQuestionsCount() == (i + 1));
            Blovote.QType qtype;
            bytes memory titleActual;
            (qtype, titleActual) = blovote.getQuestionInfo(i);
            assert(qtype == Blovote.QType.OneFromMany);
            assertEquals(i % 2 == 0 ? qtitle : qtitle2, titleActual);
        }
    }

    function testAddQuestionWithPoints() public {
        blovote.addQuestion(Blovote.QType.OneFromMany, qtitle);

        string memory str1 = "First point";
        bytes memory point1 = bytes(str1);
        string memory str2 = "Second point";
        bytes memory point2 = bytes(str2);
        string memory str3 = "Third point";
        bytes memory point3 = bytes(str3);

        blovote.addQuestionPoint(0, point1);
        blovote.addQuestionPoint(0, point2);
        blovote.addQuestionPoint(0, point3);

        assert(blovote.getQuestionPointsCount(0) == 3);
        assertEquals(blovote.getQuestionPointInfo(0, 0), point1);
        assertEquals(blovote.getQuestionPointInfo(0, 1), point2);
        assertEquals(blovote.getQuestionPointInfo(0, 2), point3);
    }

    function testAddManyQuestionsWithPoints() public {
        blovote.addQuestion(Blovote.QType.OneFromMany, qtitle);
        blovote.addQuestion(Blovote.QType.ManyFromMany, qtitle2);

        string memory str1 = "First point";
        bytes memory point1 = bytes(str1);
        string memory str2 = "Second point";
        bytes memory point2 = bytes(str2);
        string memory str3 = "Third point";
        bytes memory point3 = bytes(str3);
        string memory str4 = "Fourth point";
        bytes memory point4 = bytes(str4);


        blovote.addQuestionPoint(0, point1);
        blovote.addQuestionPoint(1, point2);
        blovote.addQuestionPoint(0, point3);
        blovote.addQuestionPoint(1, point4);

        assert(blovote.getQuestionPointsCount(0) == 2);
        assert(blovote.getQuestionPointsCount(1) == 2);
        assertEquals(blovote.getQuestionPointInfo(0, 0), point1);
        assertEquals(blovote.getQuestionPointInfo(0, 1), point3);
        assertEquals(blovote.getQuestionPointInfo(1, 0), point2);
        assertEquals(blovote.getQuestionPointInfo(1, 1), point4);

    }

    function assertEquals(bytes a, bytes b) public pure returns (bool) {
        assert(a.length == b.length);
        for (uint i = 0; i < a.length; ++i) {
            assert(a[i] == b[i]);
        }
    }
}
