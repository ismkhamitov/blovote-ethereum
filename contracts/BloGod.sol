pragma solidity ^0.4.0;

contract BloGod {

    struct SurveyInfo {
        address blovote;
        uint creationTimestamp;
    }

    function createNewSurvey(bytes _title, uint32 _respondentsCount) public payable returns (address);

    function getSurveysNumber() public view returns (uint);

    function getBlovoteAddresses(uint startIndex, uint endIndex) public view returns (address[]);
}
