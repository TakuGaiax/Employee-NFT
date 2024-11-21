const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EmployeeId",function(){
    it("should mint an NFT to a holder's address", async function (){
      
      //コントラクトのデプロイ
      const Mint = await ethers.getContractFactory("EmployeeId");
      const mintContract = await Mint.deploy();
      await mintContract.waitForDeployment();

      const [owner, admin, addr1, addr2] = await ethers.getSigners();

      await mintContract.addAdmin(admin.address);
      await mintContract.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");
      await mintContract.connect(admin).mintEmployeeIdNFT(addr2.address, "Ama", "DAO", "Hello!");

      const minters = await mintContract.getAllMinters();

      expect(await mintContract.ownerOf(0)).to.equal(addr1.address);
      expect (minters).to.include(addr1.address);
      expect (minters).to.include(addr2.address);
      expect (minters.length).to.equal(2);
    });
    it("should fail to mint an NFT by a non-owner",async function(){
      const Mint = await ethers.getContractFactory("EmployeeId");
      const mintContract = await Mint.deploy();
      await mintContract.waitForDeployment();

      const [owner, admin, addr1] = await ethers.getSigners();

      await mintContract.addAdmin(admin.address);
      expect(mintContract.connect(addr1).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!")).to.be.revertedWith("non-owner");
    })
    it("should fail to mint an NFT because already has a NFT", async function(){
      const Mint = await ethers.getContractFactory("EmployeeId");
      const mintContract = await Mint.deploy();
      await mintContract.waitForDeployment();

      const [owner, admin, addr1] = await ethers.getSigners();

      await mintContract.addAdmin(admin.address);
      //1回目
      await mintContract.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");
      //2回目
      expect(mintContract.connect(admin).mintEmployeeIdNFT(addr1.address, "Taku", "NFT", "Hey!")).to.be.revertedWith("Employee already has an ID NFT");

    })
    it("should update an token owner's NFT", async function(){
      //コントラクトのデプロイ
      const Mint = await ethers.getContractFactory("EmployeeId");
      const mintContract = await Mint.deploy();
      await mintContract.waitForDeployment();

      const [owner, admin, addr1] = await ethers.getSigners();

      await mintContract.addAdmin(admin.address);
      await mintContract.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");
      await mintContract.connect(admin).updateEmployeeInfo(0, "Taku", "NFT", "Good day!");

      const updatedMetadata= await mintContract.tokenURI(0);

      const base64String = updatedMetadata.split(',')[1];
      const decodedJson = Buffer.from(base64String, 'base64').toString('utf8');
      const decodedSvgData = Buffer.from(decodedJson, 'base64').toString('utf8');

      expect(decodedSvgData).to.include("Taku");
      expect(decodedSvgData).to.include("NFT");
      expect(decodedSvgData).to.include("Good day!"); 
    })
    it("should fail to update an NFT with non-existent tokenId", async function(){
      const Mint = await ethers.getContractFactory("EmployeeId");
      const mintContract = await Mint.deploy();
      await mintContract.waitForDeployment();

      const [owner, admin, addr1] = await ethers.getSigners();

      await mintContract.addAdmin(admin.address);
      await mintContract.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");
      expect(mintContract.connect(admin).updateEmployeeInfo(9999, "Taku", "NFT", "Good day!")).to.be.revertedWith("Invalid token");
    });
    it("should fail to update an NFT by a non-owner",async function(){
      const Mint = await ethers.getContractFactory("EmployeeId");
      const mintContract = await Mint.deploy();
      await mintContract.waitForDeployment();

      const [owner, admin, addr1] = await ethers.getSigners();

      await mintContract.addAdmin(admin.address);
      await mintContract.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");
      expect(mintContract.connect(addr1).updateEmployeeInfo(0, "Taku", "NFT", "Good day!")).to.be.revertedWith("non-owner");
    })
    it("should return the correct SVG data", async function(){
      //コントラクトのデプロイ
      const Mint = await ethers.getContractFactory("EmployeeId");
      const mintContract = await Mint.deploy();
      await mintContract.waitForDeployment();

      const [owner, admin, addr1, addr2] = await ethers.getSigners();

      await mintContract.addAdmin(admin.address);
      await mintContract.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");
      await mintContract.connect(admin).mintEmployeeIdNFT(addr2.address, "Ama", "DAO", "Hello!");

      const svgData = await  mintContract.getSVGData(0);

      const base64String = svgData.split(',')[1];
      const decodedSvg = Buffer.from(base64String, 'base64').toString('utf8');
  
      expect(decodedSvg).to.include("Ama");
      expect(decodedSvg).to.include("DAO");
      expect(decodedSvg).to.include("Hello!");
      })
});

describe("BusinessCard",function(){
  it("should mint an new NFT to multiple addresses ", async function (){
    //社員証コントラクトデプロイ
    const EmployeeId = await ethers.getContractFactory("EmployeeId");
    const employeeId = await EmployeeId.deploy();
    await employeeId.waitForDeployment();

    //BusinessCardコントラクトのデプロイ
    const BusinessCard = await ethers.getContractFactory("BusinessCard");
    const businessCard = await BusinessCard.deploy(employeeId.target);
    await businessCard.waitForDeployment();


    const [owner, admin, addr1,addr2] = await ethers.getSigners();

    await employeeId.addAdmin(admin.address);
    await businessCard.addAdmin(admin.address); 

    await employeeId.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");   
    await businessCard.connect(admin).mintNewBusinessCardNFT(addr1.address, 0, "Ama", "DAO", "Hello!");

    await employeeId.connect(admin).mintEmployeeIdNFT(addr2.address, "Ama", "DAO", "Hello!");   
    await businessCard.connect(admin).mintNewBusinessCardNFT(addr2.address, 1, "Ama", "DAO", "Hello!");

    const minters = await businessCard.getAllMinters();

    expect(await businessCard.balanceOf(addr1.address, 0)).to.equal(1);
    expect (minters).to.include(addr1.address);
    expect (minters).to.include(addr2.address);
    expect (minters.length).to.equal(2);
});
  it("should fail to mint NFT by non-owner ", async function (){
    //社員証コントラクトデプロイ
    const EmployeeId = await ethers.getContractFactory("EmployeeId");
    const employeeId = await EmployeeId.deploy();
    await employeeId.waitForDeployment();

    //BusinessCardコントラクトのデプロイ
    const BusinessCard = await ethers.getContractFactory("BusinessCard");
    const businessCard = await BusinessCard.deploy(employeeId.target);
    await businessCard.waitForDeployment();


    const [owner, admin, addr1] = await ethers.getSigners();
    await employeeId.addAdmin(admin.address);
    await businessCard.addAdmin(admin.address);

    await employeeId.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");   
    expect(businessCard.connect(addr1).mintNewBusinessCardNFT(addr1.address, 0, "Ama", "DAO", "Hello!")).to.be.revertedWith("non-owner");
  });
  // it("should mint NFT to multiple addresses", async function() {
  //   //社員証コントラクトデプロイ
  //   const EmployeeId = await ethers.getContractFactory("EmployeeId");
  //   const employeeId = await EmployeeId.deploy();
  //   await employeeId.waitForDeployment();

  //   //BusinessCardコントラクトのデプロイ
  //   const BusinessCard = await ethers.getContractFactory("BusinessCard");
  //   const businessCard = await BusinessCard.deploy(employeeId.target);
  //   await businessCard.waitForDeployment();

  //   const [owner, admin, addr1, addr2, addr3] = await ethers.getSigners();

  //   await employeeId.addAdmin(admin.address);
  //   await businessCard.addAdmin(admin.address);

  //   await employeeId.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");   
  //   await businessCard.connect(admin).mintNewBusinessCardNFT(addr1.address, 0, "Ama", "DAO", "Hello!");

  //   //NFTを送信する
  //   const toAddresses = [addr2.address, addr3.address];
  //   await businessCard.connect(addr1).mintExistingBusinessCardNFT(0, toAddresses);
  //   expect(await businessCard.balanceOf(addr2.address,0)).to.equal(1);
  //   expect(await businessCard.balanceOf(addr3.address,0)).to.equal(1);

  // });
  it("should fail to send nfts to multiple addresses by non-holder", async function () {
    //社員証コントラクトデプロイ
    const EmployeeId = await ethers.getContractFactory("EmployeeId");
    const employeeId = await EmployeeId.deploy();
    await employeeId.waitForDeployment();

    //BusinessCardコントラクトのデプロイ
    const BusinessCard = await ethers.getContractFactory("BusinessCard");
    const businessCard = await BusinessCard.deploy(employeeId.target);
    await businessCard.waitForDeployment();

    const [owner, admin, addr1, addr2, addr3] = await ethers.getSigners();

    await employeeId.addAdmin(admin.address);
    await businessCard.addAdmin(admin.address);

    await employeeId.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");   
    await businessCard.connect(admin).mintNewBusinessCardNFT(addr1.address, 0, "Ama", "DAO", "Hello!");

    const toAddresses = [addr2.address, addr3.address];
    expect(businessCard.connect(admin).mintExistingBusinessCardNFT(0, toAddresses))
      .to.be.revertedWith("You are not token owner");
  });
  it("should return the minted tokenIds by token owner", async function() {
    //社員証コントラクトデプロイ
    const EmployeeId = await ethers.getContractFactory("EmployeeId");
    const employeeId = await EmployeeId.deploy();
    await employeeId.waitForDeployment();

    //BusinessCardコントラクトのデプロイ
    const BusinessCard = await ethers.getContractFactory("BusinessCard");
    const businessCard = await BusinessCard.deploy(employeeId.target);
    await businessCard.waitForDeployment();

    const [owner, admin, addr1, addr2, addr3] = await ethers.getSigners();
    // console.log('admin:', admin.address); //0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    // console.log('addr1:', addr1.address); //0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC


    await employeeId.addAdmin(admin.address);
    await businessCard.addAdmin(admin.address);

    await employeeId.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");   
    const txn = await businessCard.connect(admin).mintNewBusinessCardNFT(addr1.address, 0, "Ama", "DAO", "Hello!");
    // console.log(txn);
    //tokenIdを取得する
    const tokenCount = await businessCard.getTokenCount(addr1.address);
    // console.log('トークンの数：',tokenCount);
    const addr1TokenIds = await businessCard.getTokenIds(addr1.address);
    // console.log('tokenId is:',addr1TokenIds);

    expect(addr1TokenIds.length).to.equal(1);

  })
  it("should return the correct SVG data", async function() {
    //社員証コントラクトデプロイ
    const EmployeeId = await ethers.getContractFactory("EmployeeId");
    const employeeId = await EmployeeId.deploy();
    await employeeId.waitForDeployment();

    //BusinessCardコントラクトのデプロイ
    const BusinessCard = await ethers.getContractFactory("BusinessCard");
    const businessCard = await BusinessCard.deploy(employeeId.target);
    await businessCard.waitForDeployment();


    const [owner, admin, addr1,addr2] = await ethers.getSigners();

    await employeeId.addAdmin(admin.address);
    await businessCard.addAdmin(admin.address); 

    await employeeId.connect(admin).mintEmployeeIdNFT(addr1.address, "Ama", "DAO", "Hello!");   
    await businessCard.connect(admin).mintNewBusinessCardNFT(addr1.address, 0, "Ama", "DAO", "Hello!");

    await employeeId.connect(admin).mintEmployeeIdNFT(addr2.address, "Ama", "DAO", "Hello!");   
    await businessCard.connect(admin).mintNewBusinessCardNFT(addr2.address, 1, "Ama", "DAO", "Hello!");

    const svgData = await businessCard.getSVGData(0);

    const base64String = svgData.split(',')[1];
    const decodedSvg = Buffer.from(base64String, 'base64').toString('utf8');

    expect(decodedSvg).to.include("Ama");
    expect(decodedSvg).to.include("DAO");
    expect(decodedSvg).to.include("Hello!");
  })
});
