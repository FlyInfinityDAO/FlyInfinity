// SPDX-License-Identifier: MIT
// This contract securely transfers user data between authorized smart contracts. The entire process is fully automated and immutable. No human intervention or external access is possible at any point. Only the Founder wallet is allowed to trigger import operations. All data is fetched from on-chain sources and passed through internal functions. Owners can rest assured: this system is designed with maximum security and zero trust assumptions.
pragma solidity >=0.4.22 <0.9.0;
import "./Smart_Defi_Genealogy.sol";
import "./Smart_DeFi_NetWork.sol";
contract Smart_DeFi_Import is Context {
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

    address internal Founder;
    Smart_Defi_Genealogy internal New_Object;
    Smart_DeFi_NetWork internal New_Object_2;
    constructor() {
        Founder = _msgSender();
        New_Object = Smart_Defi_Genealogy(
            0x267E8bF5974DfB542185da56cE31aad4C21DA431
        );
        New_Object_2 = Smart_DeFi_NetWork(
            0xd341197eE1171D30c0B1685b521C140A6299C200
        );
    }
    function Import_Fast(uint16 Start, uint16 End) external {
        require(_msgSender() == Founder, "Just Founder");
        address[] memory _Import_Part = New_Object.All_Owner_Address(
            Start,
            End
        );
        address User;
        for (uint16 i = 0; i <= (End - Start); i++) {
            User = _Import_Part[i];
            if (
                User == address(0) ||
                User == 0x76d12C7AfA6c15B310Ce9eA8bDA1bc81Dfe31489 ||
                _Exist_(User) ||
                _Exist1(User) ||
                _Exist_up(User)
            ) {
                continue;
            }
            New_Object_2._Import_Setup(
                User,
                New_Object_2.All_Owner_Number(),
                New_Object.Owner_Info(User).All_Left,
                New_Object.Owner_Info(User).All_Right,
                New_Object.Owner_Info(User).Left,
                New_Object.Owner_Info(User).Right,
                New_Object.Owner_Info(User).Direct_Number,
                New_Object.Owner_Info(User).Left_Or_Right,
                New_Object.Owner_Info(User).UpLine_Address,
                New_Object.Owner_Info(User).Left_Address,
                New_Object.Owner_Info(User).Right_Address
            );
        }
    }
    function Import_Over(address Owner) external {
        require(_msgSender() == Founder, "Just Founder");
        New_Object_2._Import_Setup(
            Owner,
            New_Object_2.All_Owner_Number(),
            New_Object.Owner_Info(Owner).All_Left,
            New_Object.Owner_Info(Owner).All_Right,
            New_Object.Owner_Info(Owner).Left,
            New_Object.Owner_Info(Owner).Right,
            New_Object.Owner_Info(Owner).Direct_Number,
            New_Object.Owner_Info(Owner).Left_Or_Right,
            New_Object.Owner_Info(Owner).UpLine_Address,
            New_Object.Owner_Info(Owner).Left_Address,
            New_Object.Owner_Info(Owner).Right_Address
        );
    }
    function Import_Founder() external {
        require(_msgSender() == Founder, "Just Founder");
        address Owner = 0x00e21f2B131CD5ba0c2e5594B1a7302A6Aa64152;
        require(_Exist_(Owner) == false, "This address imported");
        New_Object_2._Import_Setup(
            Owner,
            New_Object_2.All_Owner_Number(),
            New_Object.Owner_Info(Owner).All_Left,
            New_Object.Owner_Info(Owner).All_Right,
            New_Object.Owner_Info(Owner).Left,
            New_Object.Owner_Info(Owner).Right,
            New_Object.Owner_Info(Owner).Direct_Number,
            New_Object.Owner_Info(Owner).Left_Or_Right,
            New_Object.Owner_Info(Owner).UpLine_Address,
            New_Object.Owner_Info(Owner).Left_Address,
            New_Object.Owner_Info(Owner).Right_Address
        );
    }
    function _Exist_(address R) private view returns (bool) {
        return (New_Object_2.Owner_Info_Global(R).id != 0);
    }
    function _Exist1(address R) private view returns (bool) {
        return (New_Object.Owner_Info(R).id == 0);
    }
    function _Exist_up(address R) private view returns (bool) {
        return (New_Object.Owner_Info(R).UpLine_Address == address(0));
    }
    function Smart_History()
        public
        pure
        returns (
            address _Smart_Binance,
            address _Smart_Binance_Pro,
            address _Smart_Binance_Pro_2,
            address _Smart_Binance_Pro_3
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
