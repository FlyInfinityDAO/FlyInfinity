// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import {Fly_Infinity_Network} from "../../../../src/Fly_Infinity_Network.sol";

contract MockToken {
    Fly_Infinity_Network smart_Network;

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

    function Change_Network_Address(address _newGiftAddress) external onlyDAO {
        require(_newGiftAddress != address(0), "Invalid address");
        require(_newGiftAddress != address(smart_Network), "Same as current address");
        smart_Network = Fly_Infinity_Network(_newGiftAddress);
    }

    function flyInfinityNetwork() external view returns (Fly_Infinity_Network) {
        return smart_Network;
    }
}
