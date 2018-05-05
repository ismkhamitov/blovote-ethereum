pragma solidity ^0.4.0;
import "../contracts/BloGod.sol";
import "../contracts/BloGodImpl.sol";

contract TestBloGod {

    uint public initialBalance = 0.01 ether;

    BloGod blogod;

    function beforeEach() public {
        blogod = new BloGodImpl();
        assert(blogod.getSurveysNumber() == 0);
    }

    function testBloGodFirst() public {
        string memory str = "Hey, its test survey!";
        bytes memory title = bytes(str);

        address created = blogod.createNewSurvey(title, 100);

        assert(blogod.getSurveysNumber() == 1);

        Blovote blovote = Blovote(created);
        assertEquals(title, blovote.title());
    }


    function testBloGodMany() public {
        uint initialNumber = blogod.getSurveysNumber();

        string memory str2 = "Second survey";
        bytes memory title2 = bytes(str2);
        string memory str3 = "Third survey";
        bytes memory title3 = bytes(str3);

        address second = blogod.createNewSurvey(title2, 42);
        address third = blogod.createNewSurvey(title3, 667);

        assert(blogod.getSurveysNumber() - initialNumber == 2);

        address[] memory actualAddresses = blogod.getBlovoteAddresses(initialNumber, initialNumber + 2);
        assert(actualAddresses.length == 2);
        assert(second == actualAddresses[0]);
        assert(third == actualAddresses[1]);

        assertEquals(Blovote(actualAddresses[0]).title(), title2);
        assertEquals(Blovote(actualAddresses[1]).title(), title3);
    }


    function assertEquals(bytes a, bytes b) public pure returns (bool) {
        assert(a.length == b.length);
        for (uint i = 0; i < a.length; ++i) {
            assert(a[i] == b[i]);
        }
    }

}
