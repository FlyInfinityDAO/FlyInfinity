// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Smart_DeFi_NetWork.sol";

// ReentrancyGuard Contract (from OpenZeppelin Contracts v4.9.2). Protects functions from reentrant calls. Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.2/contracts/security/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract Smart_DeFi_Gift is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Node {
        uint64 id;
        uint8 winAmount;
        uint256 winTimer;
        address Up1;
        address Up2;
    }
    mapping(address => Node) internal allGiftMembers;
    mapping(uint64 => address) internal allGiftMembersAddress;
    mapping(uint64 => bool) internal isJoinInGift;
    mapping(uint32 => address) internal giftCandidate;
    mapping(uint32 => address) internal giftWinnerAddress;
    mapping(uint32 => address) internal All_giftWinnerAddress;
    address internal Founder;
    IERC20 internal stableCoin;
    uint256 internal time;
    uint64 internal id_;
    uint32 internal giftCandidateCounter;
    uint32 internal giftWinnerCounter;
    uint32 internal All_giftWinnerCounter;
    uint32 internal Max;
    Smart_DeFi_NetWork internal NetWorkContract;

    // 1 _    _Join_Smart_DeFi_Gift
    // 2 _    Free_Smart_DeFi_Gift   &   Wait 90 $
    // 3 _    Pay_Smart_DeFi_Gift
    // Just All Point  =  0
    // Just Big Side   <  90
    // Max Win Amount  <  90 $
    // When You Win 5 $ : Wait 90 hours
    // When You Win 5 $ : Your Two UpLines Who Have 3 ~ 30 Points , Win 2 $
    constructor() {
        Founder = _msgSender();
        stableCoin = IERC20(0x55d398326f99059fF775485246999027B3197955);
        NetWorkContract = Smart_DeFi_NetWork(0xd341197eE1171D30c0B1685b521C140A6299C200);
        Max = 40;
        time = block.timestamp;
    }

    function _Join_Smart_DeFi_Gift() external {
        DC();
    }

    function DC() private {
        require(isContract(_msgSender()) == false, "Just Wallet");
        require(isJoinInGift[NetWorkContract.Owner_Info_Global(_msgSender()).id] == false, " You are joined");
        require(!existInGift(_msgSender()), " You are joined ");
        require(existInNetWork(_msgSender()), " You are not in Smart_DeFi_NetWork  ");
        require(
            NetWorkContract.Owner_Is_My_Line(0x00e21f2B131CD5ba0c2e5594B1a7302A6Aa64152, _msgSender()) == true,
            "UpLines Are Not In Smart DeFi NetWork"
        );
        require(ownerBigSide(_msgSender()) < 90, " Big side < 90");
        require(ownerAllPoint_(_msgSender()) < 1, "Just 0 Point");
        allGiftMembersAddress[id_] = _msgSender();
        id_++;
        Node memory Owner = Node({
            id: uint64(NetWorkContract.Owner_Info_Global(_msgSender()).id),
            winAmount: 0,
            winTimer: 0,
            Up1: address(0),
            Up2: address(0)
        });
        allGiftMembers[_msgSender()] = Owner;
        isJoinInGift[allGiftMembers[_msgSender()].id] = true;
    }

    function Free_Smart_DeFi_Gift() external {
        require(isContract(_msgSender()) == false, "Just Wallet");
        require(existInGift(_msgSender()), " Owner not exist ");
        require(CandidateExist(_msgSender()) == false, " You Candidate Before ");
        require(allGiftMembers[_msgSender()].winAmount < 90, " Max 90 $ ");
        require(ownerBigSide(_msgSender()) < 90, "Big side < 90");
        require(ownerAllPoint_(_msgSender()) < 1, "Just 0 Point");
        require(
            NetWorkContract.Owner_Is_My_Line(0x00e21f2B131CD5ba0c2e5594B1a7302A6Aa64152, _msgSender()) == true,
            "UpLines Are Not In Smart DeFi NetWork"
        );
        require(block.timestamp >= allGiftMembers[_msgSender()].winTimer + 90 hours, "You Did Win in Last 90H");
        giftCandidate[giftCandidateCounter] = _msgSender();
        giftCandidateCounter++;
        ZB(_msgSender());
    }

    function Pay_Smart_DeFi_Gift() external nonReentrant {
        require(isContract(_msgSender()) == false, "Just Wallet");
        require(existInGift(_msgSender()), " Owner not exist ");
        require(ownerAllPoint_(_msgSender()) < 1, "Just 0 Point");
        require(Just_Gift_Balance() >= 90, "Smart DeFi Gift Balance Is Not Enugh ");
        require(Just_Gift_Balance() <= (giftCandidateCounter), "Number Of Candidate Not Enugh");
        giftWinnerCounter = 0;
        stableCoin.safeTransfer(_msgSender(), 3 * 10 ** 18);
        uint32 Number_Win = uint32((stableCoin.balanceOf(address(this)) / 10 ** 18) / (10));
        if (Number_Win > Max) Number_Win = Max;
        uint32 Range = giftCandidateCounter / Number_Win;
        uint32 t1 = uint32(NetWorkContract.All_Owner_Number());
        uint32 temp;
        if (t1 < Range) temp = t1;
        else temp = t1 % Range;
        for (uint64 i = 0; i < Number_Win; i++) {
            stableCoin.safeTransfer(giftCandidate[temp], 5 * 10 ** 18);
            giftWinnerAddress[giftWinnerCounter] = giftCandidate[temp];
            giftWinnerCounter++;
            All_giftWinnerAddress[All_giftWinnerCounter] = giftCandidate[temp];
            All_giftWinnerCounter++;
            allGiftMembers[giftCandidate[temp]].winTimer = block.timestamp;
            allGiftMembers[giftCandidate[temp]].winAmount += 5;
            if (
                (allGiftMembers[giftCandidate[temp]].Up1 != address(0))
                    && (Winner_Exist(allGiftMembers[giftCandidate[temp]].Up1) == false)
            ) {
                stableCoin.safeTransfer(allGiftMembers[giftCandidate[temp]].Up1, 2 * 10 ** 18);
                giftWinnerAddress[giftWinnerCounter] = allGiftMembers[giftCandidate[temp]].Up1;
                giftWinnerCounter++;
                All_giftWinnerAddress[All_giftWinnerCounter] = allGiftMembers[giftCandidate[temp]].Up1;
                All_giftWinnerCounter++;
                allGiftMembers[allGiftMembers[giftCandidate[temp]].Up1].winAmount += 2;
                allGiftMembers[allGiftMembers[giftCandidate[temp]].Up1].winTimer = block.timestamp;
            }
            if (
                (allGiftMembers[giftCandidate[temp]].Up2 != address(0))
                    && (Winner_Exist(allGiftMembers[giftCandidate[temp]].Up2) == false)
            ) {
                stableCoin.safeTransfer(allGiftMembers[giftCandidate[temp]].Up2, 2 * 10 ** 18);
                giftWinnerAddress[giftWinnerCounter] = allGiftMembers[giftCandidate[temp]].Up2;
                giftWinnerCounter++;
                All_giftWinnerAddress[All_giftWinnerCounter] = allGiftMembers[giftCandidate[temp]].Up2;
                All_giftWinnerCounter++;
                allGiftMembers[allGiftMembers[giftCandidate[temp]].Up2].winAmount += 2;
                allGiftMembers[allGiftMembers[giftCandidate[temp]].Up2].winTimer = block.timestamp;
            }
            temp = temp + Range - 2;
        }
        giftCandidateCounter = 0;
        time = block.timestamp;
    }

    function ZB(address R) private {
        address tempUpLine = NetWorkContract.Owner_UpLine(R);
        address temp = R;
        allGiftMembers[temp].Up1 = address(0);
        allGiftMembers[temp].Up2 = address(0);
        uint8 Counter;
        while (Counter < 2) {
            if (tempUpLine == address(0)) break;
            if (
                NetWorkContract.Owner_All_Point(tempUpLine) > 3 && NetWorkContract.Owner_All_Point(tempUpLine) < 30
                    && allGiftMembers[tempUpLine].winAmount < 45
                    && (block.timestamp >= allGiftMembers[tempUpLine].winTimer + 90 hours)
            ) {
                if (existInGift(tempUpLine) == false) {
                    allGiftMembersAddress[id_] = tempUpLine;
                    id_++;
                    Node memory Owner = Node({
                        id: uint64(NetWorkContract.Owner_Info_Global(tempUpLine).id),
                        winAmount: 0,
                        winTimer: 0,
                        Up1: address(0),
                        Up2: address(0)
                    });
                    allGiftMembers[tempUpLine] = Owner;
                    isJoinInGift[allGiftMembers[tempUpLine].id] = true;
                }
                if (Counter == 0) allGiftMembers[R].Up1 = tempUpLine;
                else allGiftMembers[R].Up2 = tempUpLine;
                Counter++;
            }
            temp = tempUpLine;
            tempUpLine = NetWorkContract.Owner_UpLine(tempUpLine);
        }
    }

    function CandidateExist(address A) private view returns (bool) {
        for (uint32 i = 0; i < giftCandidateCounter; i++) {
            if (giftCandidate[i] == A) return true;
        }
        return false;
    }

    function Winner_Exist(address A) private view returns (bool) {
        for (uint32 i = 0; i < giftWinnerCounter; i++) {
            if (giftWinnerAddress[i] == A) return true;
        }
        return false;
    }

    function isContract(address R) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(R) }
        return size > 0;
    }

    function existInGift(address ownerAddress) private view returns (bool) {
        return (allGiftMembers[ownerAddress].id != 0);
    }

    function existInNetWork(address ownerAddress) private view returns (bool) {
        return (NetWorkContract.Owner_Info_Global(ownerAddress).id != 0);
    }

    function ownerBigSide(address ownerAddress) private view returns (uint32) {
        return NetWorkContract.Owner_Info_Global(ownerAddress).AL >= NetWorkContract.Owner_Info_Global(ownerAddress).AR
            ? NetWorkContract.Owner_Info_Global(ownerAddress).AL
            : NetWorkContract.Owner_Info_Global(ownerAddress).AR;
    }

    function ownerAllPoint_(address ownerAddress) private view returns (uint32) {
        return NetWorkContract.Owner_Info_Global(ownerAddress).AL <= NetWorkContract.Owner_Info_Global(ownerAddress).AR
            ? NetWorkContract.Owner_Info_Global(ownerAddress).AL
            : NetWorkContract.Owner_Info_Global(ownerAddress).AR;
    }

    function Owner_Win_Gift_Amount(address ownerAddress) public view returns (uint8) {
        return allGiftMembers[ownerAddress].winAmount;
    }

    function UnLess_Gift() external {
        require(_msgSender() == Founder, "Just Founder");
        require(block.timestamp > time + 9 hours, " UnLess Gift Time Has Not Come ");
        giftCandidateCounter = 0;
        time = block.timestamp;
        stableCoin.safeTransfer(0xdd4d21f89914fB23d169b982fEab23FeA666f3c8, stableCoin.balanceOf(address(this)));
    }

    function Smart_DeFi_NetWork_Contract() external pure returns (address) {
        return 0xd341197eE1171D30c0B1685b521C140A6299C200;
    }

    function Smart_DeFi_Gift_Contract() public view returns (address) {
        return address(this);
    }

    function Just_Gift_Balance() public view returns (uint256) {
        return stableCoin.balanceOf(address(this)) / 10 ** 18;
    }

    function Just_Candidate_Number() public view returns (uint32) {
        return giftCandidateCounter;
    }

    function Owner_Info_Gift_Classic(address ownerAddress)
        external
        view
        returns (
            uint64 ID,
            address Second_UpLine,
            address First_UpLine,
            uint8 Total_Win_$,
            uint256 Last_Win_Timer_Hours
        )
    {
        Node memory node = allGiftMembers[ownerAddress];
        uint256 winPassed = node.winTimer > 0 ? (block.timestamp - node.winTimer) / 3600 : 0;
        return (node.id, node.Up2, node.Up1, node.winAmount, winPassed);
    }

    function Owner_Info_Gift(address ownerAddress) external view returns (Node memory) {
        return allGiftMembers[ownerAddress];
    }

    function Owner_Info_NetWork_Classic(address Owner)
        external
        view
        returns (
            uint64 ID,
            uint32 All_Left,
            uint32 All_Right,
            address UpLine_Address,
            address Left_Address,
            address Right_Address
        )
    {
        Smart_DeFi_NetWork.Node memory info = NetWorkContract.Owner_Info_Global(Owner);
        return (info.id, info.AL, info.AR, info.UP, info.PO, info.QO);
    }

    function Max_Winner() public view returns (uint256) {
        return Max * 3;
    }

    function Set_Max_Winner(uint8 R) external {
        require(_msgSender() == Founder, "Just Founder");
        require(R < 999 && R > 9, "Just 9-999");
        Max = R;
    }

    function Last_Gift_Winner_Number() public view returns (uint256) {
        return giftWinnerCounter;
    }

    function Last_Gift_Winner_Address() public view returns (address[] memory) {
        address[] memory ret = new address[](giftWinnerCounter);
        for (uint32 i = 0; i < giftWinnerCounter; i++) {
            ret[i] = giftWinnerAddress[i];
        }
        return ret;
    }

    function All_Gift_Winner_Address(uint32 start, uint32 end) public view returns (address[] memory) {
        uint32 index;
        address[] memory ret = new address[]((end - start) + 1);
        for (uint32 i = start; i <= end; i++) {
            ret[index] = All_giftWinnerAddress[i];
            index++;
        }
        return ret;
    }

    function All_Gift_Number() public view returns (uint256) {
        return All_giftWinnerCounter;
    }
}
