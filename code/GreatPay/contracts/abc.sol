pragma solidity ^0.4.2;

contract owned {

address public owner;

function owned(){

owner = msg.sender;

}

modifier onlyOwner {

if (msg.sender != owner) throw;

_;

}

function transferOwnership (address newOwner) onlyOwner {

owner = newOwner;

}

}

contract tokenRecipient {

event receivedEther (address sender, uint amount) ;

event receivedTokens (address _from, uint256 _value, address

_token, bytes _extraData) ;

function receiveApproval (address _from, uint256 _value,

address _token, bytes _extraData) {

Token t = Token (_token) ;

if (!t.transferFrom (_from, this, _value) ) throw;

receivedTokens (_from, _value, _token, _extraData) ;

}

function()payable {

receivedEther (msg.sender, msg.value) ;

}

}

contract Token {

function transferFrom (address _from, address _to, uint256 _value) returns (bool success) ;

}

contract Congress is owned, tokenRecipient {

/* 合约变量和事件*/

uint public minimumQuorum;

uint public debatingPeriodInMinutes;

int public majorityMargin;

Proposal[] public proposals;

uint public numProposals;

mapping (address => uint) public memberId;

Member[] public members;

event ProposalAdded (uint proposalID, address recipient, uint

amount, string description) ;

event Voted (uint proposalID, bool position, address voter, string justifi cation) ;

event ProposalTallied (uint proposalID, int result, uint quorum, bool active) ;

event MembershipChanged (address member, bool isMember) ;

event ChangeOfRules (uint minimumQuorum, uint debatingPeriodInMinutes, int majorityMargin) ;

struct Proposal {

address recipient;

uint amount;

string description;

uint votingDeadline;

bool executed;

bool proposalPassed;

uint numberOfVotes;

int currentResult;

bytes32 proposalHash;

Vote[] votes;

mapping (address => bool) voted;

}

struct Member {

address member;

string name;

uint memberSince;

}

struct Vote {

bool inSupport;

address voter;

string justifi cation;

}

/* 修饰函数：只允许「持股成员」参与投票和提交提案*/

modifi er onlyMembers {

if (memberId[msg.sender] == 0)

throw;

_;

}

/* 构造函数*/

function Congress (

uint minimumQuorumForProposals,

uint minutesForDebate,

int marginOfVotesForMajority, address congressLeader

) payable {

changeVotingRules (minimumQuorumForProposals,

minutesForDebate, marginOfVotesForMajority) ;

if (congressLeader != 0) owner = congressLeader;

// 添加一个空的成员

addMember (0, '') ;

// 把创建者加在后面

addMember (owner, 'founder') ;

}

/*加入成员*/

function addMember (address targetMember, string memberName)

onlyOwner {

uint id;

if (memberId[targetMember] == 0) {

memberId[targetMember] = members.length;

id = members.length++;

members[id] = Member ({member: targetMember,

memberSince: now, name: memberName}) ;

} else {

id = memberId[targetMember];

Member m = members[id];

}

MembershipChanged (targetMember, true) ;

}

function removeMember (address targetMember) onlyOwner {

if (memberId[targetMember] == 0) throw;

for (uint i = memberId[targetMember]; i<members.length-1; i++) {

members[i] = members[i+1];

}

delete members[members.length-1];

members.length--;

}

/*修改规则*/

function changeVotingRules (

uint minimumQuorumForProposals,

uint minutesForDebate,

int marginOfVotesForMajority

) onlyOwner {

minimumQuorum = minimumQuorumForProposals;

debatingPeriodInMinutes = minutesForDebate;

majorityMargin = marginOfVotesForMajority;

ChangeOfRules (minimumQuorum, debatingPeriodInMinutes,

majorityMargin) ;

}

/* 提交新提案函数*/

function newProposal (

address benefi ciary,

uint etherAmount,

string JobDescription,

bytes transactionBytecode

)

onlyMembers

returns (uint proposalID)

{

proposalID = proposals.length++;

Proposal p = proposals[proposalID];

p.recipient = benefi ciary;

p.amount = etherAmount;

p.description = JobDescription;

p.proposalHash = sha3 (beneficiary, etherAmount,

transactionBytecode) ;

p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;

p.executed = false;

p.proposalPassed = false;

p.numberOfVotes = 0;

ProposalAdded (proposalID, benefi ciary, etherAmount,

JobDescription) ;

numProposals = proposalID+1;

return proposalID;

}

/* 检查提案的字节码是否匹配函数*/

function checkProposalCode (

uint proposalNumber,

address benefi ciary,

uint etherAmount,

bytes transactionBytecode

)

constant

returns (bool codeChecksOut)

{

Proposal p = proposals[proposalNumber];

return p.proposalHash == sha3 (benefi ciary, etherAmount,

transactionBytecode) ;

}

function vote (

uint proposalNumber,

bool supportsProposal,

string justifi cationText

)

onlyMembers

returns (uint voteID)

{

Proposal p = proposals[proposalNumber];

//读取提案

if (p.voted[msg.sender] == true) throw;

//如果已经投票， 则终止

p.voted[msg.sender] = true;

// 设置该投票者已完成投票

p.numberOfVotes++;

// 增加已投票成员数量

if (supportsProposal) {

// 如果支持提案

p.currentResult++;

// 增加计数

} else {

//如果不支持

p.currentResult--;

// 减少计数

}

// 创建事件日志

Voted (proposalNumber, supportsProposal, msg.sender,

justifi cationText) ;

return p.numberOfVotes;

}

function executeProposal (uint proposalNumber, bytes

transactionBytecode) {

Proposal p = proposals[proposalNumber];

/* 检查提案是否能够执行：

投票截止时间是否已到？

是否已经执行或正在执行？

交易字节符验证是否匹配？

是否达到最低赞成票？

*/

if (now < p.votingDeadline

|| p.executed

|| p.proposalHash != sha3 (p.recipient, p.amount,

transactionBytecode)

|| p.numberOfVotes < minimumQuorum)

throw;

/* 执行结果*/

/* 支持和反对之间的差额是否大于设定值*/

if (p.currentResult > majorityMargin) {

// 避免循环调用

p.executed = true;

if (!p.recipient.call.value (p.amount * 1 ether)

(transactionBytecode) ) {

throw;

}

p.proposalPassed = true;

} else {

p.proposalPassed = false;

}

//启动事件

ProposalTallied (proposalNumber, p.currentResult, p.

numberOfVotes, p.proposalPassed) ;

}

}