pragma solidity ^0.4.0;

import "./BloGod.sol";
import "./Blovote.sol";
import "./BlovoteImpl.sol";

contract BloGodImpl is BloGod {

    address zeroIndexAddress;
    mapping (address => uint) blovoteIndices;
    address[] blovotes;

    function createNewSurvey(bytes _title, uint32 _respondentsCount) public payable
                        returns (address) {

        Blovote blovote = (new BlovoteImpl).value(msg.value)(msg.sender, _title, _respondentsCount);
        blovoteIndices[address(blovote)] = blovotes.length;
        if (blovotes.length == 0) {
            zeroIndexAddress == address(blovote);
        }

        blovotes.push(address(blovote));
        blovote.setBloGod(BloGod(this));

        return address(blovote);
    }

    function getSurveysNumber() public view returns (uint) {
        return blovotes.length;
    }


    function getBlovoteAddresses(uint startIndex, uint endIndex) public view returns (address[]) {
        require(startIndex >= 0 && endIndex > startIndex,
                "Index must be 0 or positive and endIndex should be more that startIndex");

        address[] memory addresses = new address[](endIndex - startIndex);
        for (uint i = startIndex; i < endIndex && i < blovotes.length; ++i) {
            addresses[i - startIndex] = blovotes[i];
        }

        return addresses;
    }

}
