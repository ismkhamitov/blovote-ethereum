pragma solidity ^0.4.0;
import "./BloGod.sol";

contract Blovote {

    enum QType { Text, OneFromMany, ManyFromMany, Sort }

    enum State { New, Active, Finished }

    function setBloGod(BloGod blogod) public;

    function title() external view returns (bytes);

    function creationTimestamp() external view returns (uint);

    function requiredRespondentsCount() external view returns (uint);

    function currentRespondentsCount() external view returns (uint);

    function rewardSize() external view returns (uint);

    function updateState(State state) external;

    function getState() external view returns (Blovote.State);


    function addFilterQuestion(Blovote.QType qType, bytes qTitle) external;

    function addQuestion(QType qtype, bytes qtitle) external;

    function getFilterQuestionsCount() external view returns (uint);

    function getQuestionsCount() external view returns (uint);

    function getQuestionInfo(uint index) external view returns (QType, bytes);

    function getFilterQuestionInfo(uint index) external view returns (QType, bytes, uint[]);


    function addFilterQuestionPoint(uint qIndex, bytes qText, bool isRight) external;

    function addQuestionPoint(uint qIndex, bytes ansText) external;

    function getFilterQuestionPointsCount(uint index) external view returns (uint);

    function getQuestionPointsCount(uint qIndex) external view returns (uint);

    function getFilterQuestionPointInfo(uint qIndex, uint pIndex) external view returns (bytes);

    function getQuestionPointInfo(uint qIndex, uint pointIndex) external view returns (bytes);



    function respondText(bytes answerText) external;

    function respondNumbers(uint8[] numbers) external;

    function getRespondData(uint qIndex, uint respondIndex) external view returns (bytes);



    function isAvailableToNewRespondents() public view returns (bool);
}
