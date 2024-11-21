//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";//トークンIdの集合を格納するためのもの
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interface.sol";

contract BusinessCard is ERC1155, AccessControl {
    IEmployeeId private employeeIdContract;

    using Strings for uint256; //トークンIdを文字列変換しメタデータへ組み込む

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address [] private adminList;//管理者のアドレスの配列

    using EnumerableSet for EnumerableSet.UintSet;
    uint256 private _tokenIdCounter =0;//NFT作成されるたびにtokenIdを追跡
    struct EmployeeInfo {
        string employeeName;
        string departmentName;
        string message;
    }
    mapping (uint256 => EmployeeInfo) private _tokenInfo;
    mapping(address => EnumerableSet.UintSet) private _holderTokenIds;//アドレスごとに所有するトークンIDのセットをマッピング
    mapping(uint256 => address) private _tokenMinter;//tokenIdとミントしたユーザーのアドレスを関連づける

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private minters; //ミンターのアドレスをセットで格納する

    function _exists(uint256 tokenId) private view returns (bool) {
        return bytes(_tokenInfo[tokenId].employeeName).length > 0;
    }

    constructor(address employeeIdAddress) ERC1155("") {
        employeeIdContract = IEmployeeId(employeeIdAddress);//EmployeeeIdコントラクトを取得
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); //ロールの管理ができる
        _grantRole(ADMIN_ROLE, msg.sender);//特定の管理機能が実行できる
        adminList.push(msg.sender);
    }
        //複数のアドレスに対してNFTを発行
        //ERC1155

        //管理者が管理者権限を与えるアドレスを追加＆削除する
        function addAdmin(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE){
            require(!hasRole(ADMIN_ROLE, newAdmin), "This address is already an admin");
            grantRole(ADMIN_ROLE, newAdmin);
            adminList.push(newAdmin);
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
        
        //tokenIdを新規発行してNFTを発行する
        function mintNewBusinessCardNFT(address to, uint256 tokenId, string memory employeeName, string memory departmentName, string memory message) public onlyRole(ADMIN_ROLE){
            require(employeeIdContract.ownerOf(tokenId) == to, "No employeeId NFT");
            require(balanceOf(to, tokenId) == 0, "Already minted");
            _mint(to, tokenId, 1, "");
            _tokenInfo[tokenId] = EmployeeInfo(employeeName, departmentName, message);
            _tokenMinter[tokenId] = msg.sender;
            _holderTokenIds[to].add(tokenId);//新規発行したtokenIdのみ
            minters.add(to);
        }

        //既存のtokenIdを使って複数ユーザーへミントする
        function mintExistingBusinessCardNFT(uint256 tokenId, address[] memory toAddresses) public {
            //名刺NFTを持っているか
            require(balanceOf(msg.sender, tokenId) > 0, "Not business card NFT");
            //保有している社員証NFTと名刺NFTが一致するか
            require(employeeIdContract.ownerOf(tokenId) == msg.sender, "Not owner of minted employee ID NFT");
            for (uint i=0; i<toAddresses.length; i++) {
                address to = toAddresses[i];
                _mint(to, tokenId, 1, "");
            }
        }

        // tokenIdを引数にメタデータを返している
        function uri(uint256 tokenId) public view override returns (string memory){
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
            // require(balanceOf(msg.sender, tokenId) > 0, "No exists tokenIds");//tokenIdの存在を確かめる
            // require (_tokenMinter[tokenId] == msg.sender, "Not token owner");
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
                '<svg width="700" height="700" xmlns="http://www.w3.org/2000/svg" style="background-color: #088395;">',
                '<title>EmployeeNFT_Image</title>',
                '<text transform="matrix(1.11174 0 0 1.37965 -21.1841 -28.3464)" stroke="#9ACEE6" fill="#ffffff" stroke-width="0" x="242.59793" y="74.82061" id="svg_3" font-size="24" font-family="\'Arimo\'" text-anchor="start" xml:space="preserve" font-weight="bold">Business Card</text>',
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
        require (_exists(tokenId), "Token does not exist");
        EmployeeInfo memory info = _tokenInfo[tokenId];
        return string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            generateSVG(info.employeeName, info.departmentName, info.message)
        ));
    }

    function getTokenCount(address owner) public view returns (uint256) {
    return _holderTokenIds[owner].length();}
    
    //アドレスごとにtokenIdを返す（ただし、自分でミントしたもののみ）
    function getTokenIds(address user) public view returns (uint256[] memory) {
        uint256 totalTokens = _holderTokenIds[user].length();//アドレスが所有するtokenIdの総数
        uint256[] memory tempTokenIds = new uint256[](totalTokens);//一時的に配列へ保存
        uint256 count =0;//条件に合ったtokenIdの総数のインクリメント

        //tokenIdをミントしたユーザーであるか
        for (uint256 i=0; i < totalTokens; i++) {
            uint256 tokenId = _holderTokenIds[user].at(i);//アドレスが所有するi番目のtokenId
            tempTokenIds[count] = tokenId;
            count++;
        }

        //最終的な配列の作成（ミントしたもの）
        uint256[] memory mintedTokenIds = new uint256[](count);
        for (uint256 i=0; i < count; i++) {
            mintedTokenIds[i] = tempTokenIds[i];//一時的に保存した配列のi番目のidを格納していく
        }

        return mintedTokenIds;
        
    }

    //tokenIdごとにNFT情報を取得
    function getBusinessCardInfo(uint256 tokenId) public view returns(string memory employeeName, string memory departmentName, string memory message) {
        require (_exists(tokenId), "TokenId is not existed");//tokenIdの存在の確認

        EmployeeInfo memory info = _tokenInfo[tokenId];//tokenIdに対応する情報を取得
        return (info.employeeName, info.departmentName, info.message);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //ミンターのリストを取得
    function getAllMinters() public view returns (address[] memory) {
        return minters.values();
    }

}