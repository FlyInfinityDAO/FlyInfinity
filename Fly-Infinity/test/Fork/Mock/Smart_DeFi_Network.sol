// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import {Fly_Infinity_Gift} from "../../../src/Fly_Infinity_Gift.sol";
import {Fly_Infinity_Token} from "../../../src/Fly_Infinity_Token.sol";
import {console} from "forge-std/console.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage)
        private
        returns (bytes memory)
    {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + (value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - (value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IOldContract {
    struct Node {
        uint64 id;
        uint32 All_Left;
        uint32 All_Right;
        uint32 Left;
        uint32 Right;
        uint8 Direct_Number;
        bool Left_Or_Right;
        address UpLine_Address;
        address Left_Address;
        address Right_Address;
    }

    function Owner_Info_Global(address owner) external view returns (Node memory);
    function All_Owner_Number() external view returns (uint64);
    function All_Owner_Address(uint32 start, uint32 end) external view returns (address[] memory);
    function Owner_Max_Point_Status(address owner) external view returns (bool);
}

contract Fly_Infinity_Network is Context {
    using SafeERC20 for IERC20;

    Fly_Infinity_Gift smart_Gift;
    Fly_Infinity_Token smart_Bank;

    struct Node {
        uint64 id;
        uint32 AL;
        uint32 AR;
        uint32 LT;
        uint32 RT;
        uint8 XI;
        bool YY;
        address UP;
        address PO;
        address QO;
    }

    mapping(address => Node) internal KW;
    mapping(address => uint8) internal EE;
    mapping(uint64 => address) internal VV;
    mapping(uint64 => uint32) internal ChCr;
    mapping(uint256 => address) internal JJ;
    mapping(uint256 => uint256) internal VPL;
    mapping(uint32 => address) internal JL;
    mapping(address => bool) internal MaxPoint;
    mapping(address => bool) internal Agreement_;
    mapping(address => address) internal changeFounders;
    mapping(address => bool) internal supportAddresses;

    address internal Founder;
    address internal JY;
    address internal Agent;

    IERC20 internal stableCoin;
    IOldContract internal oldContract;

    uint64 internal JK;
    uint24 internal DJ;
    uint32 internal ZL;
    uint256 internal time;
    uint256 internal RCr;
    uint256 internal ZM;
    uint256 internal DZ;
    uint256 internal LZ;
    uint256 internal rewardFee;
    uint256 internal newMember;
    uint64 internal lastBatch;

    bool internal Waiting;
    bool internal changeSwitch;
    bool internal importCompleted;

    string internal Road_Map;
    string public Founder_Message;

    address internal daoContract;

    modifier onlyDAO() {
        require(_msgSender() == daoContract, "Only DAO can call this");
        _;
    }

    constructor(
        address _Founder,
        address _Agent,
        address _stableCoin,
        address _oldContract,
        address[2] memory old_Founders,
        address[2] memory new_Founders,
        address[4] memory _supportAddresses
    ) {
        Founder = _Founder;
        stableCoin = IERC20(_stableCoin);
        Agent = _Agent;
        oldContract = IOldContract(_oldContract);
        time = block.timestamp;
        importCompleted = false;
        smart_Gift = new Fly_Infinity_Gift(_Founder, _stableCoin, address(this));
        smart_Bank = new Fly_Infinity_Token(_stableCoin, address(this));
        stableCoin.approve(address(smart_Bank), type(uint256).max);

        for (uint256 i = 0; i < old_Founders.length; i++) {
            changeFounders[old_Founders[i]] = new_Founders[i];
        }
        for (uint256 i = 0; i < _supportAddresses.length; i++) {
            supportAddresses[_supportAddresses[i]] = true;
        }
    }

    function Set_DAO_Contract(address _daoContract) external {
        require(_msgSender() == Founder, "Just Founder");
        require(daoContract == address(0), "DAO already set");
        require(_daoContract != address(0), "Invalid address");
        require(I_C(_daoContract), "DAO address can not be wallet");
        daoContract = _daoContract;
    }

    function Change_Gift_Address(address _newGiftAddress) external onlyDAO {
        require(_newGiftAddress != address(0), "Invalid address");
        require(_newGiftAddress != address(smart_Gift), "Same as current address");
        require(I_C(_newGiftAddress), "New gift address can not be wallet");
        smart_Gift = Fly_Infinity_Gift(_newGiftAddress);
    }

    function Import_Batch(uint64 batchSize) external {
        require(importCompleted == false, "Import already completed");
        require(Waiting == false, "Processing");
        uint64 start = lastBatch;
        uint64 end = lastBatch + batchSize;
        lastBatch += batchSize;
        if (lastBatch >= oldContract.All_Owner_Number()) {
            end = oldContract.All_Owner_Number();
            importCompleted = true;
        }

        Waiting = true;

        address[] memory importAddresses = oldContract.All_Owner_Address(uint32(start), uint32(end - 1));

        for (uint32 i = 0; i < importAddresses.length; i++) {
            address user = importAddresses[i];
            IOldContract.Node memory oldNode = oldContract.Owner_Info_Global(user);
            if (Owner_Exists(user)) continue;
            bool maxPoints = oldContract.Owner_Max_Point_Status(user);

            _importUser(
                _checkFounders(user),
                oldNode.All_Left,
                oldNode.All_Right,
                oldNode.Left,
                oldNode.Right,
                oldNode.Direct_Number,
                oldNode.Left_Or_Right,
                _checkFounders(oldNode.UpLine_Address),
                _checkFounders(oldNode.Left_Address),
                _checkFounders(oldNode.Right_Address),
                maxPoints
            );
        }

        Waiting = false;
    }

    function _importUser(
        address owner,
        uint32 allLeft,
        uint32 allRight,
        uint32 left,
        uint32 right,
        uint8 directNumber,
        bool leftOrRight,
        address upLineAddress,
        address leftAddress,
        address rightAddress,
        bool maxPoints
    ) private {
        VV[JK] = owner;
        JK++;

        Node memory newNode = Node({
            id: JK,
            AL: allLeft,
            AR: allRight,
            LT: left,
            RT: right,
            XI: directNumber,
            YY: leftOrRight,
            UP: upLineAddress,
            PO: leftAddress,
            QO: rightAddress
        });

        KW[owner] = newNode;
        MaxPoint[owner] = maxPoints;
    }

    function _checkFounders(address owner) private view returns (address) {
        if (changeFounders[owner] == address(0)) return owner;
        return changeFounders[owner];
    }

    function Import_Status() external view returns (bool) {
        return importCompleted;
    }

    function Old_Contract_Address() external view returns (address) {
        return address(oldContract);
    }

    function BeCome_Owner(address Up) external {
        DC(Up);
    }

    function DC(address Up) private {
        require(importCompleted, "Import not completed yet");
        require(I_C(_msgSender()) == false, "Just Wallet");
        require(Up != address(0), "Dont Enter address 0");
        require(KW[Up].XI != 2, " Upline Has 2 Directs ");
        require(_msgSender() != Up, " Dont Enter Your Address ");
        require(!DX(_msgSender()), " You Are An Owner ");
        require(DX(Up), " Upline Not Exist ");
        require(Agreement_[_msgSender()] == true, " Write Agreement");
        require(Waiting == false, " Processing ");
        Waiting = true;
        stableCoin.safeTransferFrom(_msgSender(), address(this), 100 * 10 ** 18);
        IERC20(stableCoin).transfer(address(smart_Gift), 5 * 10 ** 18);
        smart_Bank.Buy(_msgSender(), 2 * 10 ** 18);
        VV[JK] = _msgSender();
        JK++;
        Node memory owner = Node({
            id: JK,
            AL: 0,
            AR: 0,
            LT: 0,
            RT: 0,
            XI: 0,
            YY: KW[Up].XI == 0 ? false : true,
            UP: Up,
            PO: address(0),
            QO: address(0)
        });
        KW[_msgSender()] = owner;
        JJ[newMember] = _msgSender();
        DZ++;
        newMember++;
        if (KW[Up].XI == 0) {
            KW[Up].LT++;
            KW[Up].AL++;
            KW[Up].PO = _msgSender();
        } else {
            KW[Up].RT++;
            KW[Up].AR++;
            KW[Up].QO = _msgSender();
        }
        KW[Up].XI++;
        Waiting = false;
    }

    function Reward() external {
        DH();
    }

    function DH() private {
        require(importCompleted, "Import not completed yet");
        require(I_C(_msgSender()) == false, "Just Wallet");
        require(Owner_All_Point(_msgSender()) > 0, "Just NetWorker");
        require(block.timestamp > time + 1 hours, " Reward Time Has Not Come ");
        ZB();
        require(ZI() > 0, " Total Point Is 0 ");
        require(Waiting == false, " Processing ");
        Waiting = true;
        ZL = ZI();
        JY = _msgSender();
        uint256 ZO = ZK();
        ZM = ZO;
        RCr++;
        VPL[RCr] = ZO;
        uint256 D_T = ((DZ * rewardFee * 10 ** 18) / 2);
        for (uint24 i = 0; i < DJ; i++) {
            Node memory ZN = KW[JL[i]];
            uint32 UT = ZH(JL[i]);
            if (ZN.LT == UT) {
                ZN.LT = 0;
                ZN.RT -= UT;
            } else if (ZN.RT == UT) {
                ZN.LT -= UT;
                ZN.RT = 0;
            } else {
                if (ZN.LT < ZN.RT) {
                    ZN.RT -= ZN.LT;
                    ZN.LT = 0;
                } else {
                    ZN.LT -= ZN.RT;
                    ZN.RT = 0;
                }
            }
            KW[JL[i]] = ZN;
            if (Owner_All_Point(JL[i]) < 100) {
                if (UT * ZO > stableCoin.balanceOf(address(this))) {
                    stableCoin.safeTransfer(_checkSupport(JL[i]), stableCoin.balanceOf(address(this)));
                } else {
                    stableCoin.safeTransfer(_checkSupport(JL[i]), UT * ZO);
                }
            } else {
                if (((UT * ZO * 9) / 10) > stableCoin.balanceOf(address(this))) {
                    stableCoin.safeTransfer(_checkSupport(JL[i]), stableCoin.balanceOf(address(this)));
                } else {
                    stableCoin.safeTransfer(_checkSupport(JL[i]), ((UT * ZO * 9) / 10));
                }
            }
        }
        if (D_T <= stableCoin.balanceOf(address(this))) {
            stableCoin.safeTransfer(_msgSender(), D_T);
        }
        stableCoin.safeTransfer(address(smart_Bank), stableCoin.balanceOf(address(this)));
        time = block.timestamp;
        DZ = 0;
        newMember = 0;
        LZ = 0;
        DJ = 0;
        Waiting = false;
    }

    function _checkSupport(address owner) private view returns (address) {
        if (supportAddresses[owner]) {
            return address(smart_Bank);
        }
        return owner;
    }

    function Point_BroadCast() external {
        require(I_C(_msgSender()) == false, "Just Wallet");
        require(DX(_msgSender()), "Owner Not Exist");
        require(newMember >= 5, " After 5 BeCome_Owner ");
        require(Waiting == false, " Processing ");
        Waiting = true;
        ZB();
        newMember = 0;
        Waiting = false;
    }

    function ZB() private {
        address ZC;
        address ZD;
        for (uint256 k = 0; k < newMember; k++) {
            ZC = KW[KW[JJ[k]].UP].UP;
            ZD = KW[JJ[k]].UP;
            if (ZE(ZD) == true) {
                JL[DJ] = ZD;
                DJ++;
            }
            while (ZC != address(0)) {
                if (KW[ZD].YY == false) {
                    KW[ZC].LT++;
                    KW[ZC].AL++;
                } else {
                    KW[ZC].RT++;
                    KW[ZC].AR++;
                }
                if (ZE(ZC) == true) {
                    JL[DJ] = ZC;
                    DJ++;
                }
                ZD = ZC;
                ZC = KW[ZC].UP;
            }
        }
    }

    function _Change_Wallet(address I) external {
        require(importCompleted, "Import not completed yet");
        require(I != address(0), "Dont Enter address 0");
        require(changeSwitch == true, "Do After ChangeSwitch");
        require(DX(_msgSender()), "You Are Not Exist");
        require(I_C(I) == false, "New address can not be contract");
        require(IRT(_msgSender()), " Do After Reward");
        if (Owner_All_Point(_msgSender()) > 1000) {
            require(ChCr[KW[_msgSender()].id] < 8, "Just 8 Times");
        } else {
            require(ChCr[KW[_msgSender()].id] < 3, "Just 3 Times");
        }
        require(!DX(I), "New Address Exist!");
        require(DX(KW[_msgSender()].UP), "Your UpLine Not Exist");
        require(Waiting == false, "Processing");
        Waiting = true;
        Node memory F = KW[_msgSender()];
        VV[F.id] = I;
        Node memory B = KW[F.PO];
        B.UP = I;
        KW[F.PO] = B;
        Node memory C = KW[F.QO];
        C.UP = I;
        KW[F.QO] = C;
        Node memory U = KW[F.UP];
        if (F.YY == false) {
            U.PO = I;
        } else {
            U.QO = I;
        }
        KW[F.UP] = U;
        KW[I] = F;
        ChCr[KW[I].id]++;
        ChCr[KW[_msgSender()].id]++;
        delete KW[_msgSender()];
        Waiting = false;
    }

    function _Dont_Change_Wallet() external {
        require(importCompleted, "Import not completed yet");
        require(DX(_msgSender()), "Owner Not Exist");
        ChCr[KW[_msgSender()].id] = 8;
    }

    function DX(address F) private view returns (bool) {
        return (KW[F].id != 0);
    }

    function ZE(address F) private view returns (bool) {
        if (ZH(F) > 0) {
            for (uint24 i = 0; i < DJ; i++) {
                if (JL[i] == F) {
                    return false;
                }
            }
            return true;
        } else {
            return false;
        }
    }

    function ZI() private view returns (uint32) {
        uint32 AA;
        for (uint24 i = 0; i < DJ; i++) {
            AA += ZH(JL[i]);
        }
        return AA;
    }

    function ZH(address F) private view returns (uint32) {
        uint32 min = KW[F].LT <= KW[F].RT ? KW[F].LT : KW[F].RT;
        if (MaxPoint[F] == false) {
            if (min > 5) {
                min = 5;
            }
        } else {
            if (min > 10) {
                min = 10;
            }
        }
        return min;
    }

    function IRT(address F) private view returns (bool) {
        for (uint256 i = 0; i < DZ; i++) {
            if (JJ[i] == F) {
                return false;
            }
        }
        return true;
    }

    function I_C(address F) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(F)
        }
        return size > 0;
    }

    function ZK() private view returns (uint256) {
        return (stableCoin.balanceOf(address(this)) - (DZ * 3 * 10 ** 18)) / ZI();
    }

    function Owner_Exists(address owner) public view returns (bool) {
        return DX(owner);
    }

    function Add_Approve_USDT() external view returns (address) {
        return address(stableCoin);
    }

    function All_Owner_Number() public view returns (uint64) {
        return JK;
    }

    function All_Owner_Address(uint32 start, uint32 end) public view returns (address[] memory) {
        uint32 index;
        address[] memory ret = new address[]((end - start) + 1);
        for (uint32 i = start; i <= end; i++) {
            ret[index] = VV[i];
            index++;
        }
        return ret;
    }

    function Last_Value_Point() public view returns (uint256) {
        return ZM / 10 ** 18;
    }

    function Last_Reward_Writer() public view returns (address) {
        return JY;
    }

    function Last_Total_Point() public view returns (uint32) {
        return ZL;
    }

    function Last_Value_Points_Average(uint256 I) external view returns (uint256) {
        require(I <= RCr, " Out Of Range ");
        uint256 Lv = 0;
        for (uint256 i = RCr; i > (RCr - I); i--) {
            Lv += (VPL[i] / 10 ** 18);
        }
        return (Lv / I);
    }

    function Just_Contract_Balance() public view returns (uint256) {
        return stableCoin.balanceOf(address(this)) / 10 ** 18;
    }

    function Owner_Info_Classic(address owner)
        external
        view
        returns (
            uint64 ID,
            uint32 All_Left,
            uint32 All_Right,
            uint32 Left,
            uint32 Right,
            address UpLine_Address,
            address Left_Address,
            address Right_Address
        )
    {
        Node memory node = KW[owner];
        return (node.id, node.AL, node.AR, node.LT, node.RT, node.UP, node.PO, node.QO);
    }

    function Owner_Big_Side(address F) public view returns (uint32) {
        return KW[F].AL >= KW[F].AR ? KW[F].AL : KW[F].AR;
    }

    function Owner_All_Point(address F) public view returns (uint32) {
        return KW[F].AL <= KW[F].AR ? KW[F].AL : KW[F].AR;
    }

    function Owner_Info_Global(address F) public view returns (Node memory) {
        return KW[F];
    }

    function Owner_UpLine(address F) public view returns (address) {
        return KW[F].UP;
    }

    function Owner_Directs(address F) public view returns (address, address) {
        return (KW[F].PO, KW[F].QO);
    }

    function Owner_Left_Right_All(address F) public view returns (uint32, uint32) {
        return (KW[F].AL, KW[F].AR);
    }

    function Owner_Left_Right_Save(address F) public view returns (uint32, uint32) {
        return (KW[F].LT, KW[F].RT);
    }

    function Owner_All_Team(address F) public view returns (uint32) {
        return (KW[F].AL + KW[F].AR);
    }

    function Smart_DeFi_Bank_() external view returns (Fly_Infinity_Token) {
        return smart_Bank;
    }

    function Smart_DeFi_Gift_() external view returns (Fly_Infinity_Gift) {
        return smart_Gift;
    }

    function Smart_DeFi_DAO_() external view returns (address) {
        return daoContract;
    }

    function _Set_Reward_Fee(uint256 F) external {
        require(_msgSender() == Agent, "Just Agent");
        require(F <= 5 && F > 0, "Just 1-5");
        rewardFee = F;
    }

    function Reward_Fee_Status() public view returns (uint256) {
        return rewardFee;
    }

    function Reward_Counter_Status() public view returns (uint256) {
        return RCr;
    }

    function _New_Owner_Status() public view returns (uint256) {
        return newMember;
    }

    function Owner_UpLines_All_Address(address F) public view returns (address[] memory) {
        address[] memory OUAL = new address[](JK);
        uint32 OUAC;
        address _D_UpLine = KW[F].UP;
        address _D = F;
        while (_D != address(0)) {
            OUAL[OUAC] = _D_UpLine;
            OUAC++;
            _D = _D_UpLine;
            _D_UpLine = KW[_D_UpLine].UP;
        }
        address[] memory ret = new address[](OUAC);
        for (uint32 i = 0; i < OUAC; i++) {
            ret[i] = OUAL[i];
        }
        return ret;
    }

    function Max_Point(address Left_100, address Right_100) external {
        DC2(Left_100, Right_100);
    }

    function DC2(address Left_100, address Right_100) private {
        require(importCompleted, "Import not completed yet");
        require(DX(_msgSender()), "Owner Not Exist");
        require(MaxPoint[_msgSender()] == false, "You Did Max_Point");
        require(Owner_Is_My_Line(KW[_msgSender()].PO, Left_100) == true, "Left_100 is not your line");
        require(Owner_Is_My_Line(KW[_msgSender()].QO, Right_100) == true, "Right_100 is not your line");
        require(Owner_All_Point(Left_100) >= 100, "Left_100 is not +100 point");
        require(Owner_All_Point(Right_100) >= 100, "Right_100 is not +100 point");
        MaxPoint[_msgSender()] = true;
    }

    function Owner_Is_My_Line(address Up_Line, address Down_Line) public view returns (bool) {
        if (Up_Line == Down_Line) {
            return true;
        } else {
            address E = KW[Down_Line].UP;
            bool temp;
            while (E != address(0)) {
                if (E == Up_Line) {
                    temp = true;
                    break;
                }
                E = KW[E].UP;
            }
            if (temp) {
                return true;
            } else {
                return false;
            }
        }
    }

    function Agreement_Road_Map() external {
        require(I_C(_msgSender()) == false, "Just Wallet");
        require(Agreement_[_msgSender()] == false, "You Did Before ");
        Agreement_[_msgSender()] = true;
    }

    function Owner_Max_Point_Status(address Owner) public view returns (bool) {
        return MaxPoint[Owner];
    }

    function _UnLess_Reward() external {
        require(importCompleted, "Import not completed yet");
        require(Owner_All_Point(_msgSender()) > 1000, "Just +1000");
        require(block.timestamp > time + 4 hours, "UnLess_Reward Time Has Not Come");
        newMember = 0;
        LZ = 0;
        DJ = 0;
        Waiting = false;
    }

    function _Switch_Change_Status() public view returns (bool) {
        return changeSwitch;
    }

    function _Switch_Change() external {
        require(_msgSender() == Agent, "Just Agent");
        if (changeSwitch == false) {
            changeSwitch = true;
        } else {
            changeSwitch = false;
        }
    }

    function _Write_Road_Map(string memory I) public {
        require(_msgSender() == Founder, " Just Founder ");
        Road_Map = I;
    }

    function _Write_Founder_Message(string memory M) public {
        require(_msgSender() == Founder, " Just Founder ");
        Founder_Message = M;
    }

    function Road_Map_() public view returns (string memory) {
        return Road_Map;
    }

    /**
     * @dev Migrate all stableCoin balance from this Network contract to a new Network contract.
     * Can only be called by the DAO after a successful network address change proposal.
     */
    function migrateFundsToNewNetwork(address _newNetwork) external onlyDAO {
        require(_newNetwork != address(0), "Invalid address");
        require(_newNetwork != address(this), "Same as current address");
        require(I_C(_newNetwork), "New address can not be wallet");

        uint256 balance = stableCoin.balanceOf(address(this));
        if (balance > 0) {
            stableCoin.safeTransfer(_newNetwork, balance);
        }
    }
}
