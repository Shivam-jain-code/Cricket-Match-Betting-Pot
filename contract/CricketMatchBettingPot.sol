// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract CricketBettingPot {
    enum Team { None, TeamA, TeamB }

    address public owner;
    Team public winner;

    mapping(address => uint256) public betsOnA;
    mapping(address => uint256) public betsOnB;

    uint256 public totalBetA;
    uint256 public totalBetB;

    bool public bettingClosed;
    bool public winningsWithdrawn;

    event BetPlaced(address indexed bettor, Team team, uint256 amount);
    event BettingClosed();
    event WinnerDeclared(Team winner);
    event Withdrawal(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sirf malik kar sakta hai");
        _;
    }

    modifier bettingOpen() {
        require(!bettingClosed, "Betting band hai");
        _;
    }

    constructor() {
        owner = msg.sender;
        winner = Team.None;
    }

    // Place bet on Team A or Team B
    function placeBet(Team team) external payable bettingOpen {
        require(team == Team.TeamA || team == Team.TeamB, "Galat team chuni");
        require(msg.value > 0, "Zero nahi bet kar sakte");

        if (team == Team.TeamA) {
            betsOnA[msg.sender] += msg.value;
            totalBetA += msg.value;
        } else {
            betsOnB[msg.sender] += msg.value;
            totalBetB += msg.value;
        }

        emit BetPlaced(msg.sender, team, msg.value);
    }

    // Owner closes betting (no more bets)
    function closeBetting() external onlyOwner bettingOpen {
        bettingClosed = true;
        emit BettingClosed();
    }

    // Owner declares winner after match
    function declareWinner(Team _winner) external onlyOwner {
        require(bettingClosed, "Pehle betting band karo");
        require(_winner == Team.TeamA || _winner == Team.TeamB, "Sahi winner do");
        require(winner == Team.None, "Winner already declared");

        winner = _winner;
        emit WinnerDeclared(winner);
    }

    // Users withdraw their winnings
    function withdrawWinnings() external {
        require(winner != Team.None, "Winner abhi tak declare nahi hua");

        uint256 payout;

        if (winner == Team.TeamA) {
            uint256 userBet = betsOnA[msg.sender];
            require(userBet > 0, "Aap ne Team A par bet nahi lagayi");
            payout = (userBet * (totalBetA + totalBetB)) / totalBetA;
            betsOnA[msg.sender] = 0;
        } else {
            uint256 userBet = betsOnB[msg.sender];
            require(userBet > 0, "Aap ne Team B par bet nahi lagayi");
            payout = (userBet * (totalBetA + totalBetB)) / totalBetB;
            betsOnB[msg.sender] = 0;
        }

        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Payment fail ho gaya");

        emit Withdrawal(msg.sender, payout);
    }

    // In case no one withdraws, owner can withdraw leftover after some time (optional)

    receive() external payable {
        revert("Use placeBet to send ETH");
    }
}
