pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Blovote.sol";
import "../contracts/BlovoteImpl.sol";

contract TestBlovoteResponds {

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

    function testRespondWithText() public {
        blovote.addQuestion(Blovote.QType.Text, qtitle);

        assert(blovote.currentRespondentsCount() == 0);

        blovote.updateState(Blovote.State.Active);

        string memory str = "Answer first";
        bytes memory respondText = bytes(str);
        blovote.respondText(respondText);

        assert(blovote.currentRespondentsCount() == 1);

        bytes memory actualData;
        ( , actualData) = blovote.getRespondData(0, 0);

        assertEquals(actualData, respondText);
    }

    function testRespondWitsNumbers() public {
        blovote.addQuestion(Blovote.QType.ManyFromMany, qtitle);

        assert(blovote.currentRespondentsCount() == 0);

        blovote.updateState(Blovote.State.Active);

        uint8[] memory data = new uint8[](1);
        data[0] = 42;
        blovote.respondNumbers(data);

        assert(blovote.currentRespondentsCount() == 1);

        bytes memory actualData;
        ( , actualData) = blovote.getRespondData(0, 0);

        assert(actualData.length == 1);
        assert(uint8(actualData[0]) == 42);
    }

    function assertEquals(bytes a, bytes b) public pure returns (bool) {
        assert(a.length == b.length);
        for (uint i = 0; i < a.length; ++i) {
            assert(a[i] == b[i]);
        }
    }
}
