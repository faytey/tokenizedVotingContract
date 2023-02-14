//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract tokenizedVotingDao is ERC20 {
    
    uint256 tokenCost = 1000 gwei;
    address public owner;
    address[] contestantsPool;
    uint256[] public votingPools;
    uint256[] results;
    uint256 public votingCost = 50;
    uint256 public contestCreationCost = 200;
    uint256 voteId = 10010;
    mapping(address => Result) voteCount;
    mapping(uint256 => address[]) contendersList;
    mapping(uint256 => mapping(address => uint256)) pointCount;
    mapping(uint256 => bool) voteStatus;
    mapping(uint256 => address) votingAdmin;
    mapping(address => mapping(uint256 => bool)) voteCheck;

    struct Result {
        address _address;
        uint256 _totalPoints;
    }

    event LogBoughtTokens(
        address _address,
        uint256 tokensPurchased,
        string message
    );
    event LogWithdrawal(address _address, uint256 amount, string message);
    event Contest(uint256 voteId, string message);
    event Success(address _address, string message);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _tokenQuantity
    ) ERC20(_name, _symbol) {
        _mint(address(this), _tokenQuantity * (10**decimals()));
    }

    function buyTokens() public payable {
        uint256 tokensPurchased = msg.value / tokenCost;
        _transfer(address(this), msg.sender, tokensPurchased);
        emit LogBoughtTokens(
            msg.sender,
            tokensPurchased,
            "Your purchase is successful"
        );
    }

    modifier onlyOwner(address _address) {
        require(owner == _address, "Not owner");
        _;
    }

    function withdrawFunds(uint256 amount)
        public
        payable
        onlyOwner(msg.sender)
    {
        require(msg.sender != address(0), "Can't send to address(0)");
        payable(msg.sender).transfer(amount * (10**decimals()));
        emit LogWithdrawal(
            msg.sender,
            amount,
            "You have successfully withdrawn"
        );
    }

    function contestCreation(
        address _contender1,
        address _contender2,
        address _contender3
    )
        public
        noRepeat(_contender1, _contender2, _contender3)
        returns (uint256 yourVoteId)
    {
        require(
            balanceOf(msg.sender) >= contestCreationCost,
            "INSUFFICIENT FUND, GET MORE TOKEN"
        );
        transfer(address(this), contestCreationCost);
        votingPools.push(voteId);
        voteStatus[voteId] = true;
        contestantsPool.push(_contender1);
        contestantsPool.push(_contender2);
        contestantsPool.push(_contender3);
        contendersList[voteId] = contestantsPool;
        contestantsPool.pop();
        contestantsPool.pop();
        contestantsPool.pop();
        votingAdmin[voteId] = msg.sender;
        yourVoteId = voteId;
        emit Contest(voteId, "Vote contest created successfully");
        voteId++;
    }

    function displayContenders(uint256 _voteId)
        public
        view
        returns (address[] memory contenders)
    {
        contenders = contendersList[_voteId];
    }

    function displayOwner(uint256 _voteId)
        public
        view
        returns (address _owner)
    {
        _owner = votingAdmin[_voteId];
    }

    function displayTotalVotes(uint256 _voteId)
        public
        view
        returns (uint256 TotalPoints)
    {
        address[] memory _contendersList = contendersList[_voteId];
        address contender1 = _contendersList[0];
        address contender2 = _contendersList[1];
        address contender3 = _contendersList[2];
        TotalPoints =
            pointCount[_voteId][contender1] +
            pointCount[_voteId][contender2] +
            pointCount[_voteId][contender3];
    }

    function vote(
        uint256 _voteId,
        address _contender1,
        address _contender2,
        address _contender3
    ) public noRepeat(_contender1, _contender2, _contender3) {
        //norepeat
        require(
            balanceOf(msg.sender) >= votingCost,
            "INSUFFICIENT FUND, GET MORE TOKEN"
        );
        transfer(address(this), votingCost);

        require(voteStatus[_voteId], "This contest is over, voting closed");
        bool status = voteCheck[msg.sender][_voteId];
        require(!status, "You Have Already Voted");
        pointAssigner(_voteId, _contender1, _contender2, _contender3);
        uint256 voteIdN = _voteId;
        voteCheck[msg.sender][voteIdN] = true;
        emit Success(msg.sender, "Voted Successfully");
    }

    function pointAssigner(
        uint256 _voteId,
        address _contender1,
        address _contender2,
        address _contender3
    ) private {
        pointCount[_voteId][_contender1] += 3;
        pointCount[_voteId][_contender2] += 2;
        pointCount[_voteId][_contender3] += 1;
    }

    function closeVotingPool(uint256 _voteId) public {
        voteStatus[_voteId] = false;
        emit Contest(_voteId, "Contest Closed");
    }

    function displayWinner(uint256 _voteId)
        public
        view
        returns (address winner)
    {
        bool status = voteStatus[_voteId];
        require(!status, "VOTING NOT OVER YET");
        address[] memory _contendersList = contendersList[_voteId];
        uint256 contender1 = pointCount[_voteId][_contendersList[0]];
        uint256 contender2 = pointCount[_voteId][_contendersList[1]];
        uint256 contender3 = pointCount[_voteId][_contendersList[2]];

        if (contender1 > contender2 && contender1 > contender3) {
            winner = _contendersList[0];
        } else if (contender2 > contender3) {
            winner = _contendersList[1];
        } else {
            winner = _contendersList[2];
        }
    }

    receive() external payable {}

    fallback() external payable {}

    modifier noRepeat(
        address _contenders1,
        address _contenders2,
        address _contenders3
    ) {
        require(_contenders1 != _contenders2, "ADDRESS 1 AND 2 ARE THE SAME");
        require(_contenders1 != _contenders3, "ADDRESS 1 AND 3 ARE THE SAME");
        require(_contenders2 != _contenders3, "ADDRESS 2 AND 3 ARE THE SAME");
        _;
    }
}
