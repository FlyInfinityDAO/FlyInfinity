// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ISmart_DeFi_Network {
    /* ========== STRUCTS ========== */

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

    /* ========== CORE ACTIONS ========== */

    function BeCome_Owner(address Up) external;
    function Reward() external;
    function Point_BroadCast() external;

    /* ========== WALLET / EMERGENCY ========== */

    function _Change_Wallet(address X) external;
    function _Dont_Change_Wallet() external;

    function _Emergency_Vote() external;
    function _Emergency__Do() external;

    /* ========== VIEW / INFO ========== */

    function Add_Approve_USDT() external view returns (address);
    function All_Owner_Number() external view returns (uint64);
    function All_Owner_Address(uint32 start, uint32 end) external view returns (address[] memory);

    function Last_Value_Point() external view returns (uint256);
    function Last_Reward_Writer() external view returns (address);
    function Last_Total_Point() external view returns (uint32);

    function Last_Value_Points_Average(uint256 X) external view returns (uint256);
    function Just_Contract_Balance() external view returns (uint256);

    /* ========== OWNER INFO ========== */

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
        );

    function Owner_Big_Side(address R) external view returns (uint32);
    function Owner_All_Point(address R) external view returns (uint32);
    function Owner_Info_Global(address R) external view returns (Node memory);
    function Owner_UpLine(address R) external view returns (address);
    function Owner_Directs(address R) external view returns (address, address);
    function Owner_Left_Right_All(address R) external view returns (uint32, uint32);
    function Owner_Left_Right_Save(address R) external view returns (uint32, uint32);
    function Owner_All_Team(address R) external view returns (uint32);

    function Owner_UpLines_All_Address(address R) external view returns (address[] memory);
    function Owner_Is_My_Line(address Up_Line, address Down_Line) external view returns (bool);

    /* ========== MAX POINT ========== */

    function Max_Point(address Left_100, address Right_100) external;
    function Owner_Max_Point_Status(address Owner) external view returns (bool);

    /* ========== AGREEMENT ========== */

    function Agreement_Road_Map() external;

    /* ========== SYSTEM / STATUS ========== */

    function Smart_History()
        external
        pure
        returns (
            address Smart_Binance,
            address Smart_Binance_Pro,
            address Smart_Binance_Pro_2,
            address Smart_Binance_Pro_3
        );

    function Smart_DeFi_Bank_() external view returns (address);
    function Smart_DeFi_Gift_() external view returns (address);

    function Reward_Fee_Status() external view returns (uint256);
    function Reward_Counter_Status() external view returns (uint256);
    function _New_Owner_Status() external view returns (uint256);

    function _Emergency_Vote_Status() external view returns (uint32);
    function _Switch_Change_Status() external view returns (bool);

    /* ========== ADMIN / AGENT ========== */

    function _Set_Reward_Fee(uint256 R) external;
    function _Switch_Change() external;
    function _Set_Stable_Coin(uint8 R) external;

    function _Set_Smart_DeFi_Bank(address X) external;
    function _Set_Smart_DeFi_Gift(address X) external;

    function _Write_Road_Map(string calldata I) external;
    function _Write_Founder_Message(string calldata M) external;

    function Smart_Road_Map_() external view returns (string memory);

    /* ========== IMPORT ========== */

    function _Set_Import_Setup_Irreturnable(address R) external;

    function _Import_Setup(
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
    ) external;

    /* ========== FAILSAFE ========== */

    function _UnLess_Reward() external;
}
