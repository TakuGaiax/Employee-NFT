//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";//トークンIdの集合を格納するためのもの

contract EmployeeId is ERC721, AccessControl{
    using Strings for uint256; //トークンIdを文字列変換しメタデータへ組み込む

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address [] private adminList;//管理者のアドレスの配列

    uint256 private _tokenIdCounter =0;//NFT作成されるたびにtokenIdを追跡
    uint256[] private _allTokens;
    struct EmployeeInfo {
        string employeeName;
        string departmentName;
        string message;
    }
    mapping (uint256 => EmployeeInfo) private _tokenInfo; //各トークンIdに対応する社員情報
    mapping(address => uint256[]) private _ownedTokenIds;//アドレスごとに所有するトークンIDのセットをマッピング
    mapping(uint256 => address) private _tokenMinter;//tokenIdとミントしたユーザーのアドレスを関連づける

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private minters; //ミンターのアドレスをセットで格納する
    
    function exists(uint256 tokenId) public view returns (bool) {
        try this.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    constructor() ERC721("EmployeeNFT", "EPNFT"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); //ロールの管理ができる
        _grantRole(ADMIN_ROLE, msg.sender);//特定の管理機能が実行できる
        adminList.push(msg.sender);
    }
    
    //管理者が管理者権限を与えるアドレスを追加＆削除する
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);

    function addAdmin(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(!hasRole(ADMIN_ROLE, newAdmin), "This address is already an admin");
        grantRole(ADMIN_ROLE, newAdmin);
        adminList.push(newAdmin);
        emit AdminAdded(newAdmin);
    }

    function removeAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, admin);
    }

    function removeAdminFromList (address admin) public {
        uint256 length = adminList.length;
        for (uint256 i = 0; i < length; i++) {
            if (adminList[i] == admin) {
                adminList[i] = adminList[length - 1];
                adminList.pop();
                break;
            }
        }
    }

    //Adminの役割を持っているかチェック
    function isAdmin(address _address) public view returns (bool) {
        return hasRole(ADMIN_ROLE, _address);
    }
    function getAdmins() public view returns (address[] memory) {
        return adminList;
    }
    
    //社員自身が自らのNFTを発行する
    //ERC721
    function mintEmployeeIdNFT(address to, string memory employeeName, string memory departmentName, string memory message) public onlyRole(ADMIN_ROLE){
        require(_ownedTokenIds[to].length == 0, "Employee already has an ID NFT");
        uint256 newTokenId = _tokenIdCounter;
        _mint(to, newTokenId);
        _tokenInfo[newTokenId] = EmployeeInfo(employeeName, departmentName, message);
        _tokenIdCounter += 1;
        _tokenMinter[newTokenId] = to;
        _ownedTokenIds[to].push(newTokenId);
        minters.add(to);
    }
    
    // tokenIdを引数にメタデータを返している
    function tokenURI(uint256 tokenId) public view override returns (string memory){
        EmployeeInfo memory info = _tokenInfo[tokenId];
        string memory json = Base64.encode(bytes(abi.encodePacked(
            '{"name": "G_CompanyNFT', tokenId.toString(), '",',
            '"description": "Test",',
            '"image":"data:image/svg+xml;base64,',generateSVG(info.employeeName, info.departmentName, info.message),
            '"}'
        )));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    //tokenIdに紐づいたNFT情報の更新
    mapping(uint256 => string) private _customTokenURIs;
    function getCustomTokenURI(uint256 tokenId) public view returns(string memory) {
        return _customTokenURIs[tokenId];
    }

    function updateEmployeeInfo(uint256 tokenId, string memory newEmployeeName, string memory newDepartmentName, string memory newMessage) public onlyRole(ADMIN_ROLE){
        //メタデータ更新
        _tokenInfo[tokenId] = EmployeeInfo(newEmployeeName, newDepartmentName, newMessage);
        string memory newSVG = generateSVG(newEmployeeName, newDepartmentName, newMessage);
        string memory newMetadata = string(abi.encodePacked(
            '{"name": "G_CompanyNFT', tokenId.toString(), '",',
            '","description": "Test',
            '","image":"data:image/svg+xml;base64,',
            newSVG,
            '"}'
        ));
        string memory base64newMetadata = Base64.encode(bytes(newMetadata));
        string memory newTokenURI = string(abi.encodePacked("data:application/json;base64,", base64newMetadata));

        _customTokenURIs[tokenId] = newTokenURI;
    }

    //SVG画像を生成する
    function generateSVG(string memory employeeName, string memory departmentName, string memory message) public pure returns (string memory svg){
        return Base64.encode(bytes(string(abi.encodePacked(
            '<svg width="700" height="700" xmlns="http://www.w3.org/2000/svg" style="background-color: #172853;">',
            '<title>EmployeeNFT_Image</title>',
            '<text transform="matrix(1.11174 0 0 1.37965 -21.1841 -28.3464)" stroke="#9ACEE6" fill="#ffffff" stroke-width="0" x="242.59793" y="74.82061" id="svg_3" font-size="24" font-family="\'Arimo\'" text-anchor="start" xml:space="preserve" font-weight="bold">Employee ID</text>',
            '<rect stroke="#9ACEE6" id="svg_4" height="19" width="115" y="38" x="81.00026" stroke-width="0" fill="#ffffff"/>',
            '<rect stroke="#9ACEE6" id="svg_6" height="19" width="115" y="67" x="81.00026" stroke-width="0" fill="#ffffff"/>',
            '<rect stroke="#9ACEE6" id="svg_4" height="19" width="115" y="38" x="526.1776" stroke-width="0" fill="#ffffff"/>',
            '<rect stroke="#9ACEE6" id="svg_6" height="19" width="115" y="67" x="526.1776" stroke-width="0" fill="#ffffff"/>',
            '<path stroke="#9ACEE6" id="svg_16" d="m271.98914,181.54163l34.92858,-63.99999l93.14286,0l34.92856,63.99999l-34.92856,63.99999l-93.14286,0l-34.92858,-63.99999z" stroke-width="0" fill="#0de877"/>',
            '<text transform="matrix(1.96805 0 0 1.65613 -232.941 -134.326)" stroke="#9ACEE6" xml:space="preserve" text-anchor="start" font-family="\'Arimo\'" font-size="24" id="svg_19" y="197.57912" x="287.9161" stroke-width="0" fill="#000000">G</text>',
            '<text xml:space="preserve" text-anchor="start" font-family="\'Arimo\'" font-size="24" id="svg_22" y="288.05874" x="291.82417" stroke-width="0" stroke="#9ACEE6" fill="#ffffff">Your Name</text>',
            '<rect stroke="#000000" id="svg_23" height="32" width="248" y="307.76465" x="232.00065" stroke-width="2" fill="#ffffff"/>',
            '<text xml:space="preserve" text-anchor="start" font-family="\'Arimo\'" font-size="24" id="svg_24" y="401.58817" x="153.35348" stroke-width="0" stroke="#000000" fill="#ffffff">',
            'Team',
            '</text>',
            '<rect fill="#ffffff" stroke-width="2" x="256.70669" y="373.64743" width="248" height="32" id="svg_5" stroke="#000000"/>',
            '<text style="cursor: move;" stroke="#000000" xml:space="preserve" text-anchor="start" font-family="\'Arimo\'" font-size="24" id="svg_30" y="455.70591" x="126.64743" stroke-width="0" fill="#ffffff">',
            'Message',
            '</text>',
            '<rect stroke="#000000" fill="#ffffff" stroke-width="2" x="256.70669" y="431.29487" width="248" height="34.35295" id="svg_7"/>',
            '<text style="cursor: move;" xml:space="preserve" text-anchor="start" font-family="\'Arimo\'" font-size="24" id="svg_32" y="582.059" x="274.35347" stroke-width="0" stroke="#000000" fill="#ffffff">xxxxxx</text>',
            ' <text xml:space="preserve" text-anchor="start" font-family="\'Arimo\'" font-size="24" id="svg_33" y="624.6473" x="257.11813" stroke-width="0" stroke="#000000" fill="#ffffff">xxx-xxxx-xxx</text>'
            '<text fill="#000000" stroke="#ffffff" stroke-width="0" x="324.76555" y="333.94139" id="svg_14" font-size="24" font-family="\'Arimo\'" text-anchor="start" xml:space="preserve">',employeeName,'</text>',
            '<text fill="#000000" stroke="#ffffff" stroke-width="0" x="274.17699" y="398.64769" id="svg_15" font-size="24" font-family="\'Arimo\'" text-anchor="start" xml:space="preserve">',departmentName,'</text>',
            '<text fill="#000000" stroke="#ffffff" stroke-width="0" x="274.17699" y="457.4716" id="svg_17" font-size="24" font-family="\'Arimo\'" text-anchor="start" xml:space="preserve">',message,'</text>',
            '</svg>'
        ))));
    }
    //SVG画像データを取得する
    function getSVGData(uint256 tokenId) public view returns (string memory) {
        EmployeeInfo memory info = _tokenInfo[tokenId];
        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            generateSVG(info.employeeName, info.departmentName, info.message)
        ));
    }

    //tokenIdを取得する
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require (index < balanceOf(owner),"ERC721Enumerable: owner index out of bounds" );
        return _ownedTokenIds[owner][index];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //ミンターのリストを取得
    function getAllMinters() public view returns (address[] memory) {
        return minters.values();
    }

    
}