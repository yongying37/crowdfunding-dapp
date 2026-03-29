// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CrowdFund {
    uint256 public campaignCount;
    bool private locked;

    struct Campaign {
        address payable creator;
        string title;
        uint256 goal;
        uint256 deadline;
        uint256 totalRaised;
        uint256 releasedAmount;
        uint256 backerCount;
        uint256 milestoneCount;
        bool exists;
    }

    struct Milestone {
        uint256 amount;
        uint256 approvalCount;
        bool released;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    mapping(uint256 => mapping(address => bool)) public isBacker;
    mapping(uint256 => mapping(uint256 => Milestone)) public milestones;
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public milestoneVoted;

    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string title,
        uint256 goal,
        uint256 deadline
    );

    event ContributionMade(
        uint256 indexed campaignId,
        address indexed backer,
        uint256 amount
    );

    event GoalReached(uint256 indexed campaignId, uint256 totalRaised);

    event MilestoneVoted(
        uint256 indexed campaignId,
        uint256 indexed milestoneIndex,
        address indexed backer,
        bool approved
    );

    event MilestoneReleased(
        uint256 indexed campaignId,
        uint256 indexed milestoneIndex,
        uint256 amount
    );

    event RefundIssued(
        uint256 indexed campaignId,
        address indexed backer,
        uint256 amount
    );

    modifier noReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier campaignExists(uint256 _campaignId) {
        require(campaigns[_campaignId].exists, "Campaign does not exist");
        _;
    }

    modifier onlyCreator(uint256 _campaignId) {
        require(
            msg.sender == campaigns[_campaignId].creator,
            "Not campaign creator"
        );
        _;
    }

    function createCampaign(
        string memory _title,
        uint256 _goal,
        uint256 _durationSeconds,
        uint256[] memory _milestoneAmounts
    ) external returns (uint256) {
        require(_goal > 0, "Goal must be > 0");
        require(_durationSeconds > 0, "Duration must be > 0");
        require(_milestoneAmounts.length > 0, "Need at least 1 milestone");

        uint256 totalMilestones;
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            require(_milestoneAmounts[i] > 0, "Milestone amount must be > 0");
            totalMilestones += _milestoneAmounts[i];
        }
        require(totalMilestones == _goal, "Milestones must sum to goal");

        uint256 campaignId = campaignCount;

        Campaign storage c = campaigns[campaignId];
        c.creator = payable(msg.sender);
        c.title = _title;
        c.goal = _goal;
        c.deadline = block.timestamp + _durationSeconds;
        c.exists = true;
        c.milestoneCount = _milestoneAmounts.length;

        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            milestones[campaignId][i] = Milestone({
                amount: _milestoneAmounts[i],
                approvalCount: 0,
                released: false
            });
        }

        emit CampaignCreated(campaignId, msg.sender, _title, _goal, c.deadline);

        campaignCount++;
        return campaignId;
    }

    function contribute(
        uint256 _campaignId
    ) external payable campaignExists(_campaignId) {
        Campaign storage c = campaigns[_campaignId];

        require(block.timestamp < c.deadline, "Campaign deadline passed");
        require(c.totalRaised < c.goal, "Campaign already fully funded");
        require(msg.value > 0, "Contribution must be > 0");
        require(
            c.totalRaised + msg.value <= c.goal,
            "Contribution exceeds goal"
        );

        if (!isBacker[_campaignId][msg.sender]) {
            isBacker[_campaignId][msg.sender] = true;
            c.backerCount++;
        }

        contributions[_campaignId][msg.sender] += msg.value;
        c.totalRaised += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);

        if (c.totalRaised == c.goal) {
            emit GoalReached(_campaignId, c.totalRaised);
        }
    }

    function voteOnMilestone(
        uint256 _campaignId,
        uint256 _milestoneIndex,
        bool _approve
    ) external campaignExists(_campaignId) {
        Campaign storage c = campaigns[_campaignId];
        require(c.totalRaised >= c.goal, "Goal not reached yet");
        require(isBacker[_campaignId][msg.sender], "Only backers can vote");
        require(_milestoneIndex < c.milestoneCount, "Invalid milestone");
        require(
            !milestoneVoted[_campaignId][_milestoneIndex][msg.sender],
            "Already voted"
        );

        milestoneVoted[_campaignId][_milestoneIndex][msg.sender] = true;

        if (_approve) {
            milestones[_campaignId][_milestoneIndex].approvalCount++;
        }

        emit MilestoneVoted(_campaignId, _milestoneIndex, msg.sender, _approve);
    }

    function releaseMilestoneFunds(
        uint256 _campaignId,
        uint256 _milestoneIndex
    )
        external
        noReentrant
        campaignExists(_campaignId)
        onlyCreator(_campaignId)
    {
        Campaign storage c = campaigns[_campaignId];
        require(c.totalRaised >= c.goal, "Goal not reached yet");
        require(_milestoneIndex < c.milestoneCount, "Invalid milestone");

        Milestone storage m = milestones[_campaignId][_milestoneIndex];
        require(!m.released, "Milestone already released");

        if (_milestoneIndex > 0) {
            require(
                milestones[_campaignId][_milestoneIndex - 1].released,
                "Release previous milestone first"
            );
        }

        require(c.backerCount > 0, "No backers");
        require(
            m.approvalCount * 2 > c.backerCount,
            "Majority approval not reached"
        );

        m.released = true;
        c.releasedAmount += m.amount;

        (bool sent, ) = c.creator.call{value: m.amount}("");
        require(sent, "Transfer failed");

        emit MilestoneReleased(_campaignId, _milestoneIndex, m.amount);
    }

    function claimRefund(
        uint256 _campaignId
    ) external noReentrant campaignExists(_campaignId) {
        Campaign storage c = campaigns[_campaignId];
        require(block.timestamp > c.deadline, "Campaign still active");
        require(c.totalRaised < c.goal, "Goal was reached, no refunds");

        uint256 amount = contributions[_campaignId][msg.sender];
        require(amount > 0, "No contribution to refund");

        contributions[_campaignId][msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Refund transfer failed");

        emit RefundIssued(_campaignId, msg.sender, amount);
    }

    function getCampaignDetails(
        uint256 _campaignId
    )
        external
        view
        campaignExists(_campaignId)
        returns (
            address creator,
            string memory title,
            uint256 goal,
            uint256 deadline,
            uint256 totalRaised,
            uint256 releasedAmount,
            uint256 backerCount,
            uint256 milestoneCount
        )
    {
        Campaign storage c = campaigns[_campaignId];
        return (
            c.creator,
            c.title,
            c.goal,
            c.deadline,
            c.totalRaised,
            c.releasedAmount,
            c.backerCount,
            c.milestoneCount
        );
    }

    function getMilestoneDetails(
        uint256 _campaignId,
        uint256 _milestoneIndex
    )
        external
        view
        campaignExists(_campaignId)
        returns (uint256 amount, uint256 approvalCount, bool released)
    {
        require(
            _milestoneIndex < campaigns[_campaignId].milestoneCount,
            "Invalid milestone"
        );
        Milestone storage m = milestones[_campaignId][_milestoneIndex];
        return (m.amount, m.approvalCount, m.released);
    }

    function getContribution(
        uint256 _campaignId,
        address _backer
    ) external view returns (uint256) {
        return contributions[_campaignId][_backer];
    }

    function getCampaignStatus(
        uint256 _campaignId
    ) public view campaignExists(_campaignId) returns (string memory) {
        Campaign storage c = campaigns[_campaignId];

        if (c.totalRaised >= c.goal) {
            if (c.releasedAmount == c.goal) {
                return "Completed";
            }
            return "Successful";
        }

        if (block.timestamp > c.deadline) {
            return "Failed";
        }

        return "Active";
    }
}
