// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import {Fly_Infinity_Gift} from "../../../../src/Fly_Infinity_Gift.sol";

contract MockDeFi {
    Fly_Infinity_Gift smart_Gift;

    address internal Founder;
    address internal daoContract;

    modifier onlyDAO() {
        require(msg.sender == daoContract, "Only DAO can call this");
        _;
    }

    constructor(address _Founder, address _daoAddress) {
        Founder = _Founder;
        daoContract = _daoAddress;
    }

    function Change_Gift_Address(address _newGiftAddress) external onlyDAO {
        require(_newGiftAddress != address(0), "Invalid address");
        require(_newGiftAddress != address(smart_Gift), "Same as current address");
        smart_Gift = Fly_Infinity_Gift(_newGiftAddress);
    }

    function Fly_Infinity_Gift_() external view returns (Fly_Infinity_Gift) {
        return smart_Gift;
    }

    function Owner_Exists(address owner) external pure returns (bool) {
        return true;
    }

    function Owner_Left_Right_All(address owner) external pure returns (uint256, uint256) {
        return (150, 55);
    }

    function Migrate_Funds_To_New_Network(address newContract) external {}
}
