// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("Web3Mint Contract", function () {
//   let Web3Mint;
//   let web3Mint;
//   let owner;
//   let addr1;

//   beforeEach(async function () {
//     // コントラクトのデプロイ
//     Web3Mint = await ethers.getContractFactory("Web3Mint");
//     [owner, addr1] = await ethers.getSigners();
//     web3Mint = await Web3Mint.deploy();
//     await web3Mint.deployed();
//   });

//   describe("Updating Employee Info", function () {
//     it("Should update the employee info of an NFT correctly", async function () {
//       // NFTをミント
//       await web3Mint.connect(owner).mintNFT(addr1.address, "Employee Name", "Department Name", "Message");
      
//       // NFTの情報を更新
//       await web3Mint.connect(owner).updateEmployeeInfo(0, "New Employee Name", "New Department Name", "New Message");

//       // トークンURIを取得して、更新された情報が含まれているか確認
//       let tokenURI = await web3Mint.tokenURI(0);
//       let decodedURI = Buffer.from(tokenURI.split(',')[1], 'base64').toString('utf8');

//       // 更新された情報が含まれていることを確認
//       expect(decodedURI).to.include("New Employee Name");
//       expect(decodedURI).to.include("New Department Name");
//       expect(decodedURI).to.include("New Message");
//     });
//   });
// });
