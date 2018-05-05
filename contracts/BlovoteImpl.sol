pragma solidity ^0.4.17;
import "./Blovote.sol";
import "./BloGod.sol";

contract BlovoteImpl is Blovote {

    // INNER TYPES

    struct Question {
        Blovote.QType qtype;
        bytes title;
        bytes[] points;
    }

    struct Respond {
        address respondentAddress;
        bool paid;
        bytes[] respondsData;
    }

    // FIELDS

    BloGod blogod;

    uint32 public requiredRespondentsCount;

    Blovote.State state;
    address creator;
    bytes public title;
    uint creationTime;
    uint public rewardSize;
    Question[] public quests;

    address zeroIndexRespondent;
    mapping (address => uint) respondentsIndices;

    Respond[] public responds;

    // CONSTRUCTOR

    constructor(address _creator, bytes _title, uint32 _respondentsCount) public payable {
        creator = _creator;
        creationTime = now;
        state = Blovote.State.New;
        title = _title;
        requiredRespondentsCount = _respondentsCount;
        rewardSize = uint(msg.value / requiredRespondentsCount);
    }

    function setBloGod(BloGod _blogod) public {
        blogod = _blogod;
    }

    // MODIFIERS

    modifier RequireState(Blovote.State rState) {
        require(rState == state,
                "Invalid survey state!");
        _;
    }

    modifier RequireQuestionExist(uint i) {
        require(
            i >= 0 && i < quests.length && quests[i].title.length != 0,
            "Question should exist"
        );
        _;
    }

    modifier RequireNotAnswered(uint i) {
        require(
            quests[i].points.length == 0,
            "Question is already answered!"
        );
        _;
    }

    modifier RequireAvailable() {
        require(
            isAvailableToNewRespondents(),
            "Required number of respondents is already reached!"
        );
        _;
    }


    modifier RequireParticipant() {
        require(
            isParticipant(),
            "Sender is not a participant of survey!"
        );
        _;
    }

    modifier RequireRespondentExists(uint index) {
        require(
            index >= 0 && index <= responds.length,
            "Respondent does not exists!"
        );
        _;
    }

    // EXTERNAL FUNCTIONS

    function title() external view returns (bytes) {
        return title;
    }

    function creationTimestamp() external view returns (uint) {
        return creationTime;
    }

    function requiredRespondentsCount() external view returns (uint) {
        return requiredRespondentsCount;
    }

    function currentRespondentsCount() external view returns (uint) {
        return responds.length;
    }

    function rewardSize() external view returns (uint) {
        return rewardSize;
    }

    function updateState(State _state) external {
        require(msg.sender == creator,
                "Only creator of survey can update its state!");

        state = _state;
    }

    function getState() external view returns (Blovote.State) {
        return state;
    }



    function addQuestion(Blovote.QType qtype, bytes qtitle) external RequireState(Blovote.State.New) {
        require(qtitle.length != 0, "Question's title cannot be empty!");
        quests.push(Question(qtype, qtitle, new bytes[](0)));
    }

    function getQuestionsCount() external view returns (uint) {
        return quests.length;
    }

    function getQuestionInfo(uint index) external view RequireQuestionExist(index) returns (QType, bytes) {
        return (quests[index].qtype, quests[index].title);
    }



    function addQuestionPoint(uint qIndex, bytes ansText) external
                                                          RequireQuestionExist(qIndex)
                                                          RequireState(Blovote.State.New) {

        require(canHavePoints(quests[qIndex].qtype), "Unable to add points for answer of this type");
        quests[qIndex].points.push(ansText);
    }

    function getQuestionPointsCount(uint qIndex) external view returns (uint) {
        return quests[qIndex].points.length;
    }

    function getQuestionPointInfo(uint qIndex, uint pointIndex) external view returns (bytes) {
        uint len = quests[qIndex].points.length;
        require(
            pointIndex >= 0 && pointIndex < len,
            "Point does not exist"
        );

        return quests[qIndex].points[pointIndex];
    }


    function respondText(bytes answerText) external
                                           RequireQuestionExist(qIndex)
                                           RequireNotAnswered(qIndex)
                                           RequireState(Blovote.State.Active) {

        uint respondsIndex = requestRespondentIndex(msg.sender);
        require(
            responds[respondsIndex].respondsData.length < quests.length,
            "All answers from this sender are already received!"
        );

        uint qIndex = responds[respondsIndex].respondsData.length;
        require(quests[qIndex].qtype == Blovote.QType.Text, "Target question has incorrect type!");

        responds[respondsIndex].respondsData.push(answerText);

        handleRespondAdded();
    }

    function getRespondData(uint qIndex, uint respondentIndex) external
                                                RequireQuestionExist(qIndex)
                                                RequireRespondentExists(respondentIndex)
                                                RequireState(Blovote.State.Active) returns (address, bytes) {
        require(
            responds[respondentIndex].respondsData.length > qIndex,
            "Respondent did not answered to that question!"
        );

        return (responds[respondentIndex].respondentAddress, responds[respondentIndex].respondsData[qIndex]);
    }

    function respondNumbers(uint8[] numbers) external
                                             RequireQuestionExist(qIndex)
                                             RequireNotAnswered(qIndex)
                                             RequireState(Blovote.State.Active) {

        uint respondsIndex = requestRespondentIndex(msg.sender);
        require(
            responds[respondsIndex].respondsData.length < quests.length,
            "All answers from this sender are already received!"
        );


        uint qIndex = responds[respondsIndex].respondsData.length;
        require(quests[qIndex].qtype != Blovote.QType.Text,
                "Target question cannot have text type");
        require(quests[qIndex].qtype != Blovote.QType.OneFromMany || numbers.length == 1,
                "Only one number should be sent as answer!");
        require(quests[qIndex].qtype != Blovote.QType.Sort
                || numbers.length == quests[responds[respondsIndex].respondsData.length].points.length,
                "Sort-type question must receive array of all variants!");

        responds[respondsIndex].respondsData.push(new bytes(numbers.length));
        for (uint i = 0; i < numbers.length; ++i) {
            responds[respondsIndex].respondsData[qIndex][i] = byte(numbers[i]);
        }

        handleRespondAdded();
    }


    // PUBLIC FUNCTIONS

    function isAvailableToNewRespondents() public view returns (bool) {
        return requiredRespondentsCount > responds.length;
    }


    // INTERNAL FUNCTIONS

    function canHavePoints(Blovote.QType qtype) internal pure returns (bool) {
        return qtype == Blovote.QType.OneFromMany
                || qtype == Blovote.QType.ManyFromMany
                || qtype == Blovote.QType.Sort;
    }

    function requestRespondentIndex(address respondentAddress) internal RequireAvailable returns (uint index) {
        if (zeroIndexRespondent == address(0)) {
            zeroIndexRespondent = respondentAddress;
            if (responds.length == 0) {
                responds.push(Respond(respondentAddress, false, new bytes[](0)));
            }
            index = 0;
        } else {
            index = respondentsIndices[respondentAddress];
            if (index == 0) {
                index = responds.length;
                respondentsIndices[respondentAddress] = index;
                responds.push(Respond(respondentAddress, false, new bytes[](0)));
            }
        }
    }

    function isParticipant() internal view returns (bool) {
        return msg.sender == zeroIndexRespondent || respondentsIndices[msg.sender] != 0;
    }

    function handleRespondAdded() internal {
        payRewardIfNeeded();
        if (requiredRespondentsCount <= responds.length || address(this).balance < rewardSize) {
            state = Blovote.State.Finished;
            // TODO: Notify BloGod
        }
    }

    function isPaid() internal view RequireParticipant returns (bool) {
        return !responds[respondentsIndices[msg.sender]].paid;
    }

    function payRewardIfNeeded() internal RequireParticipant {
        if (!isPaid() && responds[respondentsIndices[msg.sender]].respondsData.length == quests.length) {
            msg.sender.transfer(rewardSize);
            responds[respondentsIndices[msg.sender]].paid = true;
        }
    }
}
