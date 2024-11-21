//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

interface IEmployeeId {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function ADMIN_ROLE() external pure returns (bytes32);
    function tokenExists(uint256 tokenId) external view returns (bool);
}
