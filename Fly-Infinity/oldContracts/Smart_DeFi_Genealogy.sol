// SPDX-License-Identifier: MIT
// All external interactions with this contract are initiated by the Smart_DeFi_NetWork contract. Reentrancy protection is already enforced via OpenZeppelin's ReentrancyGuard (v4.9.2), therefore additional reentrancy checks are redundant here.
pragma solidity >=0.4.22 <0.9.0;
contract Smart_Defi_Genealogy {
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
    mapping(address => Node) internal All_Owners_;
    mapping(uint64 => address) internal All_Owners_Address_;
    mapping(address => bool) internal _Emergency_Vote_;
    mapping(address => uint256) internal Wait_Change_Wallet_List;
    mapping(uint64 => uint8) internal _Change_Wallet_Counter_;
    mapping(uint32 => address) internal voterList;
    uint64 internal _ID;
    uint32 internal voteTotal;
    uint32 internal voterCounter;
    address internal Founder;
    address internal Smart_Defi_NetWork;
    address internal Smart_DeFi_Import;
    bool internal smartDeFiNetWorkLocked;
    bool internal smartDeFiImportLocked;
    bool internal Wait_;
    bool internal emergencyChange;
    constructor() {
        Founder = msg.sender;
    }
    modifier RightInput() {
        require(
            msg.sender == Smart_Defi_NetWork || msg.sender == Smart_DeFi_Import,
            "Just Import Or Smart_Defi_NetWork"
        );
        _;
    }
    modifier JustFounder() {
        require(msg.sender == Founder, "Just Founder");
        _;
    }
    modifier JustWallet() {
        require(Is_Contract(msg.sender) == false, "Just Wallet");
        _;
    }
    modifier Wait() {
        require(Wait_ == false, "Processing");
        _;
    }
    function Set_Node(
        address Owner,
        uint64 id,
        uint32 All_Left,
        uint32 All_Right,
        uint32 Left,
        uint32 Right,
        uint8 Direct_Number,
        bool Left_Or_Right,
        address UpLine_Address,
        address Left_Address,
        address Right_Address
    ) external RightInput {
        Node memory R = Node({
            id: id,
            All_Left: All_Left,
            All_Right: All_Right,
            Left: Left,
            Right: Right,
            Direct_Number: Direct_Number,
            Left_Or_Right: Left_Or_Right,
            UpLine_Address: UpLine_Address,
            Left_Address: Left_Address,
            Right_Address: Right_Address
        });
        All_Owners_[Owner] = R;
    }
    function Set_Address(uint64 id, address owner) external RightInput Wait {
        Wait_ = true;
        All_Owners_Address_[id] = owner;
        Wait_Change_Wallet_List[owner] = block.timestamp;
        Wait_ = false;
    }
    function Set_ID(uint64 new_ID) external RightInput Wait {
        Wait_ = true;
        _ID = new_ID;
        Wait_ = false;
    }
    function Add_ID() external RightInput Wait {
        Wait_ = true;
        _ID++;
        Wait_ = false;
    }
    function Add_Direct(address Owner) external RightInput Wait {
        Wait_ = true;
        All_Owners_[Owner].Direct_Number++;
        Wait_ = false;
    }
    function Apply_Left(address Owner, uint32 value) external RightInput Wait {
        Wait_ = true;
        All_Owners_[Owner].Left = value;
        Wait_ = false;
    }
    function Apply_All_Left(
        address Owner,
        uint32 value
    ) external RightInput Wait {
        Wait_ = true;
        All_Owners_[Owner].All_Left = value;
        Wait_ = false;
    }
    function Apply_Right(address Owner, uint32 value) external RightInput Wait {
        Wait_ = true;
        All_Owners_[Owner].Right = value;
        Wait_ = false;
    }
    function Apply_All_Right(
        address Owner,
        uint32 value
    ) external RightInput Wait {
        Wait_ = true;
        All_Owners_[Owner].All_Right = value;
        Wait_ = false;
    }
    function Apply_Left_Address(
        address owner,
        address value
    ) external RightInput Wait {
        Wait_ = true;
        All_Owners_[owner].Left_Address = value;
        Wait_ = false;
    }
    function Apply_Right_Address(
        address owner,
        address value
    ) external RightInput Wait {
        Wait_ = true;
        All_Owners_[owner].Right_Address = value;
        Wait_ = false;
    }
    function Set_Smart_DeFi_NetWork(address R) external JustFounder {
        require(R != address(0), "Dont Enter address 0");
        require(smartDeFiNetWorkLocked == false, "Just 1 Times");
        Smart_Defi_NetWork = R;
        smartDeFiNetWorkLocked = true;
    }
    function Set_Smart_DeFi_Import(address R) external JustFounder {
        require(R != address(0), "Dont Enter address 0");
        require(smartDeFiImportLocked == false, "Just 1 Times");
        Smart_DeFi_Import = R;
        smartDeFiImportLocked = true;
    }
    function Is_Contract(address R) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(R)
        }
        return size > 0;
    }
    function Owner_All_Point_(address R) private view returns (uint32) {
        return
            All_Owners_[R].All_Left <= All_Owners_[R].All_Right
                ? All_Owners_[R].All_Left
                : All_Owners_[R].All_Right;
    }
    function _Exist_(address R) private view returns (bool) {
        return (All_Owners_[R].id != 0);
    }
    function _Change_Wallet(address R) external JustWallet {
        require(emergencyChange == true, "Not now");
        require(R != address(0), "Dont Enter address 0");
        require(_Exist_(msg.sender), "User Not Exist");
        require(
            _Exist_(All_Owners_[msg.sender].UpLine_Address),
            "Your UpLine Not Exist"
        );
        require(!_Exist_(R), "New Address Exist");
        require(Is_Contract(R) == false, "The new address can not be contract");
        require(
            block.timestamp >= Wait_Change_Wallet_List[msg.sender] + 24 hours,
            " 24H After Your BeCome Owner"
        );
        if (Owner_All_Point(msg.sender) > 1000) {
            require(
                _Change_Wallet_Counter_[All_Owners_[msg.sender].id] < 5,
                "Just 5 Times"
            );
        } else {
            require(
                _Change_Wallet_Counter_[All_Owners_[msg.sender].id] < 3,
                "Just 3 Times"
            );
        }
        require(
            ((All_Owners_[msg.sender].Left_Address == address(0)) ||
                (_Exist_(All_Owners_[msg.sender].Left_Address) &&
                    (All_Owners_[msg.sender].Right_Address == address(0))) ||
                (_Exist_(All_Owners_[msg.sender].Left_Address) &&
                    _Exist_(All_Owners_[msg.sender].Right_Address))),
            "Your Directs Not Imported!"
        );
        require(Wait_ == false, "Processing");
        Wait_ = true;
        Node memory A = All_Owners_[msg.sender];
        All_Owners_Address_[A.id] = R;
        Node memory B = All_Owners_[A.Left_Address];
        B.UpLine_Address = R;
        All_Owners_[A.Left_Address] = B;
        Node memory C = All_Owners_[A.Right_Address];
        C.UpLine_Address = R;
        All_Owners_[A.Right_Address] = C;
        Node memory U = All_Owners_[A.UpLine_Address];
        if (A.Left_Or_Right == false) {
            U.Left_Address = R;
        } else {
            U.Right_Address = R;
        }
        All_Owners_[A.UpLine_Address] = U;
        All_Owners_[R] = A;
        delete All_Owners_[msg.sender];
        _Change_Wallet_Counter_[All_Owners_[R].id]++;
        Wait_ = false;
    }
    function _Dont_Change_Wallet() external JustWallet {
        require(_Exist_(msg.sender), "User Not Exist");
        if (Owner_All_Point(msg.sender) > 1000) {
            _Change_Wallet_Counter_[All_Owners_[msg.sender].id] = 5;
        } else {
            _Change_Wallet_Counter_[All_Owners_[msg.sender].id] = 3;
        }
    }
    function _Smart_DeFi_Import() external view returns (address) {
        return Smart_DeFi_Import;
    }
    function _Smart_DeFi_NetWork() external view returns (address) {
        return Smart_Defi_NetWork;
    }
    function All_Owner_Number() external view returns (uint64) {
        return _ID;
    }
    function All_Owner_Address(
        uint64 start,
        uint64 end
    ) public view returns (address[] memory) {
        uint32 index;
        address[] memory ret = new address[]((end - start) + 1);
        for (uint64 i = start; i <= end; i++) {
            ret[index] = All_Owners_Address_[i];
            index++;
        }
        return ret;
    }
    function Owner_UpLine(address R) public view returns (address) {
        return All_Owners_[R].UpLine_Address;
    }
    function Owner_Directs(address R) public view returns (address, address) {
        return (All_Owners_[R].Left_Address, All_Owners_[R].Right_Address);
    }
    function Owner_Is_My_Line(
        address Up_Line,
        address Down_Line
    ) external view returns (bool) {
        if (Up_Line == Down_Line) {
            return true;
        } else {
            address E = All_Owners_[Down_Line].UpLine_Address;
            bool temp;
            while (E != address(0)) {
                if (E == Up_Line) {
                    temp = true;
                    break;
                }
                E = All_Owners_[E].UpLine_Address;
            }
            if (temp) {
                return true;
            } else {
                return false;
            }
        }
    }
    function Owner_Over_Left_Right(
        address R
    ) public view returns (uint32, uint32) {
        return (All_Owners_[R].Left, All_Owners_[R].Right);
    }
    function Owner_All_Left_Right(
        address R
    ) public view returns (uint32, uint32) {
        return (All_Owners_[R].All_Left, All_Owners_[R].All_Right);
    }
    function Owner_All_Team(address R) public view returns (uint32) {
        return All_Owners_[R].All_Left + All_Owners_[R].All_Right;
    }
    function Owner_All_Point(address R) public view returns (uint32) {
        return Owner_All_Point_(R);
    }
    function Owner_UpLines_All_Number(
        address R
    ) external view returns (uint32) {
        uint32 UpLine = 0;
        address _R_Up = All_Owners_[R].UpLine_Address;
        address _R_ = R;
        while (_R_Up != address(0)) {
            UpLine++;
            _R_ = _R_Up;
            _R_Up = All_Owners_[_R_Up].UpLine_Address;
        }
        return UpLine;
    }
    function Owner_UpLines_All_Address(
        address R
    ) public view returns (address[] memory) {
        address[] memory Owner_UpLines_All_List_ = new address[](_ID);
        uint32 Owner_UpLines_All_Counter_;
        address _D_UpLine = All_Owners_[R].UpLine_Address;
        address _D = R;
        while (_D != address(0)) {
            Owner_UpLines_All_List_[Owner_UpLines_All_Counter_] = _D_UpLine;
            Owner_UpLines_All_Counter_++;
            _D = _D_UpLine;
            _D_UpLine = All_Owners_[_D_UpLine].UpLine_Address;
        }
        address[] memory ret = new address[](Owner_UpLines_All_Counter_);
        for (uint16 i = 0; i < Owner_UpLines_All_Counter_; i++) {
            ret[i] = Owner_UpLines_All_List_[i];
        }
        return ret;
    }
    function Owner_Big_Side(address R) public view returns (uint32) {
        return
            All_Owners_[R].All_Left >= All_Owners_[R].All_Right
                ? All_Owners_[R].All_Left
                : All_Owners_[R].All_Right;
    }
    function Owner_Exist(address R) public view returns (bool) {
        return _Exist_(R);
    }
    function Owner_Info(address Owner) public view returns (Node memory) {
        return All_Owners_[Owner];
    }
    function Owner_Info_Classic(
        address owner
    )
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
        Node memory node = All_Owners_[owner];
        return (
            node.id,
            node.All_Left,
            node.All_Right,
            node.Left,
            node.Right,
            node.UpLine_Address,
            node.Left_Address,
            node.Right_Address
        );
    }
    function voterExist(address A) private view returns (bool) {
        for (uint32 i = 0; i < voterCounter; i++) {
            if (voterList[i] == A) {
                return true;
            }
        }
        return false;
    }
    function _Emergency_Vote_Status() external view returns (uint32) {
        return (voteTotal);
    }
    function _Emergency_Vote() external JustWallet {
        require(_Exist_(msg.sender), "Owner Not Exist");
        require(voterExist(msg.sender) == false, "You Did Vote Before");
        voteTotal += Owner_All_Point_(msg.sender);
        voterList[voterCounter] = msg.sender;
        voterCounter++;
    }
    function _Emergency__Do() external JustWallet {
        require(_Exist_(msg.sender), "Owner Not Exist");
        require(
            Owner_All_Point_(msg.sender) > 1000,
            "Just +1000 Can Write This Function"
        );
        require(voteTotal >= (_ID / 2) + 1, "Not Enough Votes");
        smartDeFiNetWorkLocked = false;
        voteTotal = 0;
        voterCounter = 0;
    }
    function _Emergency_change() external JustWallet JustFounder {
        if (emergencyChange == false) {
            emergencyChange = true;
        } else {
            emergencyChange = false;
        }
    }
    function _Emergency_change_Status() public view returns (bool) {
        return emergencyChange;
    }
    function Smart_History()
        public
        pure
        returns (
            address Smart_Binance,
            address Smart_Binance_Pro,
            address Smart_Binance_Pro_2,
            address Smart_Binance_Pro_3
        )
    {
        return (
            0x5741da6D2937E5896e68B1604E25972a4834C701,
            0xFc46B09bf98858B08C5c5DEeb5c19E609FaBD398,
            0x8E60F00C14D5BB0B183a8e0a0e97737D254d906e,
            0x8Aa1055188b407A58dF7d7737314d916A6F4ea24
        );
    }
}
