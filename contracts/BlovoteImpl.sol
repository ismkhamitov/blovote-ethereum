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

    struct FilterQuestion {
        Blovote.QType qtype;
        bytes title;
        bytes[] points;
        uint[] correctPoints;
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
    FilterQuestion[] public filterQuestions;
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
            i >= 0 && i < quests.length,
            "Question should exist"
        );
        _;
    }

    modifier RequireQuestionPointExist(uint qIndex, uint pIndex) {
        require(pIndex >= 0 && pIndex < quests[qIndex].points.length,
                "Question point should exist");
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

    modifier RequireFilterQuestionType(Blovote.QType qType) {
        require(qType == Blovote.QType.OneFromMany || qType == Blovote.QType.ManyFromMany,
                "Only One-from-many and Many-from-many questions can be filter questions");
        _;
    }

    modifier RequireFilterQuestionExists(uint qIndex) {
        require(
            qIndex >= 0 && qIndex <= filterQuestions.length,
            "Question with dat index does not exists"
        );
        _;
    }

    modifier RequireFilterQuestionPointExist(uint qIndex, uint pIndex) {
        require(pIndex >= 0 && pIndex < filterQuestions[qIndex].points.length,
                "Question point does not exist");
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


    function addFilterQuestion(Blovote.QType qType, bytes qTitle) external
                                                            RequireFilterQuestionType(qType)
                                                            RequireState(Blovote.State.New) {

        require(qTitle.length != 0, "Question cannot be empty");
        filterQuestions.push(FilterQuestion(qType, qTitle, new bytes[](0), new uint[](0)));
    }

    function addQuestion(Blovote.QType qtype, bytes qtitle) external RequireState(Blovote.State.New) {
        require(qtitle.length != 0, "Question's title cannot be empty!");
        quests.push(Question(qtype, qtitle, new bytes[](0)));
    }

    function getFilterQuestionsCount() external view returns (uint) {
        return filterQuestions.length;
    }

    function getQuestionsCount() external view returns (uint) {
        return quests.length;
    }

    function getFilterQuestionInfo(uint index) external view RequireFilterQuestionExists(index) returns (QType, bytes, uint[])  {
        return (filterQuestions[index].qtype, filterQuestions[index].title, filterQuestions[index].correctPoints);
    }

    function getQuestionInfo(uint index) external view RequireQuestionExist(index) returns (QType, bytes) {
        return (quests[index].qtype, quests[index].title);
    }




    function addFilterQuestionPoint(uint qIndex, bytes qText, bool isRight) external
                                                          RequireFilterQuestionExists(qIndex)
                                                          RequireState(Blovote.State.New) {
        filterQuestions[qIndex].points.push(qText);
        if (isRight) {
            filterQuestions[qIndex].correctPoints.push(qIndex);
        }
    }

    function addQuestionPoint(uint qIndex, bytes qText) external
                                                          RequireQuestionExist(qIndex)
                                                          RequireState(Blovote.State.New) {

        require(canHavePoints(quests[qIndex].qtype), "Unable to add points for answer of this type");
        quests[qIndex].points.push(qText);
    }

    function getFilterQuestionPointsCount(uint qIndex) external view RequireFilterQuestionExists(qIndex)
                                                       returns (uint) {
        return filterQuestions[qIndex].points.length;
    }

    function getQuestionPointsCount(uint qIndex) external view RequireQuestionExist(qIndex) returns (uint) {
        return quests[qIndex].points.length;
    }

    function getFilterQuestionPointInfo(uint qIndex, uint pIndex) external view
            RequireFilterQuestionExists(qIndex)
            RequireFilterQuestionPointExist(qIndex, pIndex) returns (bytes) {

        return filterQuestions[qIndex].points[pIndex];
    }

    function getQuestionPointInfo(uint qIndex, uint pointIndex) external view
                                                                RequireQuestionExist(qIndex)
                                                                RequireQuestionPointExist(qIndex, pointIndex)
                                                                returns (bytes) {
        return quests[qIndex].points[pointIndex];
    }



    function respondText(bytes answerText) external
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
        if (zeroIndexRespondent == address(0)  || zeroIndexRespondent == respondentAddress) {
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
        return responds[requestRespondentIndex(msg.sender)].paid;
    }

    function payRewardIfNeeded() internal RequireParticipant {
        uint respondIndex = requestRespondentIndex(msg.sender);
        if (!isPaid() && responds[respondIndex].respondsData.length == quests.length) {
            msg.sender.send(rewardSize);
            responds[respondIndex].paid = true;
        }
    }
}
