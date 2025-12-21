// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

contract MockContract {
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

    address[] users;

    constructor() {
        for (uint160 i = 1; i <= 100; i++) {
            if (i == 6 || i == 35 || i == 56 || i == 70 || i == 86 || i == 90) {
                users.push(address(1000 + i));
            }
            users.push(address(1000 + i));
        }
    }

    function All_Owner_Number() public view returns (uint256) {
        return 105;
    }

    function All_Owner_Address(uint32 start, uint32 stop) public view returns (address[] memory) {
        address[] memory addresses = new address[](stop - start + 1);
        for (uint32 i = start; i <= stop; i++) {
            addresses[i - start] = users[i];
        }
        return addresses;
    }

    function Owner_Info_Global(address user) public view returns (Node memory) {
        uint160 id = uint160(user) - 1000;
        if (id > 100 || id < 1) {
            return Node({
                id: 0,
                AL: 0,
                AR: 0,
                LT: 0,
                RT: 0,
                XI: 0,
                YY: false,
                UP: address(0),
                PO: address(0),
                QO: address(0)
            });
        }
        return Node({
            id: uint64(id),
            AL: id < 52 ? 1 : 0,
            AR: id < 52 ? 1 : 0,
            LT: id < 52 ? 1 : 0,
            RT: id < 52 ? 1 : 0,
            XI: id < 52 ? 2 : 0,
            YY: false,
            UP: id % 2 == 0 ? address(id / 2) : address((id - 1) / 2),
            PO: address(id * 2),
            QO: address(id * 2 + 1)
        });
    }

        function Owner_Max_Point_Status(address owner) external view returns (bool){
            return false;
        }

}
