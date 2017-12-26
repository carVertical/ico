const BigNumber = require('bignumber.js');

const chai = require('chai');
chai.use(require('chai-as-promised'));
chai.use(require('chai-bignumber')(BigNumber));

const expect = chai.expect;

const cVTokenCrowdsale = artifacts.require("./cVTokenCrowdsale.sol");
const cVToken = artifacts.require("./cVToken.sol");
const RefundVault = artifacts.require("./RefundVault.sol");

const OneEther = new BigNumber(web3.toWei(1, 'ether'));
const OneToken = new BigNumber(web3.toWei(1, 'ether'));

contract('cVTokenCrowdsale-GOOD-ICO', function(accounts) {

  let collectionWalletBalace = 0;

  before(async () => {
    let contract = await cVTokenCrowdsale.deployed();

    collectionWalletBalace = await web3.eth.getBalance(await contract.wallet());
  });

  it('ICO period should be 100 days', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let [start, end] = await Promise.all([contract.startTime(), contract.endTime()]);

    const hundredDaysInSecs = (60 * 60 * 24 * 100);
    const period = (end - start);

    assert.equal(period, hundredDaysInSecs, 'is hundred days');
  });

  it('Should have 0 get now on start', async () => {
    let contract = await cVTokenCrowdsale.deployed();

    expect(await contract.getNow()).to.be.bignumber.equal(0);
  });

  it('Token ownership is transfered', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());
    await token.transferOwnership(contract.address);

    expect(await token.tokenOwner()).to.be.equal(contract.address);
    // expect(await contract.isWhitelisted(accounts[1])).to.be.true;
  });

  it('Should not accept funds before startTime', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    // const startTime = await contract.startTime();
    // await contract.setTestNow(startTime);

    await expect(contract.sendTransaction({from: accounts[1], value: web3.toWei(1, 'ether')}))
      .to.be.eventually.rejected;
  });

  it('Should have correct getNow value', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    const startTime = await contract.startTime();
    await contract.setTestNow(startTime);

    expect(await contract.getNow()).to.be.bignumber.equal(startTime);
  });

  it('Acc 1 whitelisted', async () => {
    let contract = await cVTokenCrowdsale.deployed();

    expect(await contract.isWhitelisted(accounts[1])).to.be.true;
  });

  it('Should accept funds after startTime', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    let balanceBefore = await token.balanceOf(accounts[1]);
    expect(balanceBefore).to.be.bignumber.equal(0);
    await contract.sendTransaction({from: accounts[1], value: web3.toWei(1, 'ether')});
    let balanceAfter = await token.balanceOf(accounts[1]);
    let expectedTokens = new BigNumber(web3.toWei(1, 'ether')).mul(42000).mul(145).div(100);
    expect(balanceAfter).to.be.bignumber.equal(expectedTokens);
  });


  it('Should correctly cross from stage 0 to stage 1', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    await contract.sendTransaction({from: accounts[1], value: web3.toWei(1050, 'ether')});
    let balanceAfter = await token.balanceOf(accounts[1]);
    let expectedTokensInStage0 = OneToken.mul(1050).mul(42000).mul(145).div(100);
    let expectedTokensInStage1 = OneToken.mul(1).mul(42000).mul(135).div(100);
    let expectedTokens = expectedTokensInStage0.add(expectedTokensInStage1);
    expect(balanceAfter).to.be.bignumber.equal(expectedTokens);
  });

  it('Have 1 Ether in refundVault', async () => {
    let contract = await cVTokenCrowdsale.deployed();

    expect(await web3.eth.getBalance(await contract.vault())).to.be.bignumber.equal(OneEther);
  });

  it('Should not be able to Finalize ICO before soft-cap is reached', async () => {
    let contract = await cVTokenCrowdsale.deployed();

    await expect(contract.finalize()).eventually.rejected;
  });

  it('Should correctly cross from stage 1 to stage 2', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    await contract.sendTransaction({from: accounts[2], value: web3.toWei(2000, 'ether')});
    let balanceAfter = await token.balanceOf(accounts[2]);
    let expectedTokensInStage1 = OneToken.mul(1999).mul(42000).mul(135).div(100);
    let expectedTokensInStage2 = OneToken.mul(1).mul(42000).mul(125).div(100);
    let expectedTokens = expectedTokensInStage1.add(expectedTokensInStage2);
    expect(balanceAfter).to.be.bignumber.equal(expectedTokens);
  });

  it('Should correctly cross from stage 2 to stage 3', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    let balanceBefore = await token.balanceOf(accounts[2]);

    await contract.sendTransaction({from: accounts[2], value: web3.toWei(1500, 'ether')});
    await contract.sendTransaction({from: accounts[2], value: web3.toWei(1500, 'ether')});
    let balanceAfter = await token.balanceOf(accounts[2]);
    let expectedTokensInStage2 = OneToken.mul(2999).mul(42000).mul(125).div(100);
    let expectedTokensInStage3 = OneToken.mul(1).mul(42000).mul(115).div(100);
    let expectedTokens = expectedTokensInStage2.add(expectedTokensInStage3);
    expect(balanceAfter.sub(balanceBefore)).to.be.bignumber.equal(expectedTokens);
  });

  it('Should correctly cross from stage 3 to stage 4', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    let balanceBefore = await token.balanceOf(accounts[2]);

    await contract.sendTransaction({from: accounts[2], value: web3.toWei(1500, 'ether')});
    await contract.sendTransaction({from: accounts[2], value: web3.toWei(1500, 'ether')});
    let balanceAfter = await token.balanceOf(accounts[2]);
    let expectedTokensInStage3 = OneToken.mul(2999).mul(42000).mul(115).div(100);
    let expectedTokensInStage4 = OneToken.mul(1).mul(42000).mul(110).div(100);
    let expectedTokens = expectedTokensInStage3.add(expectedTokensInStage4);
    expect(balanceAfter.sub(balanceBefore)).to.be.bignumber.equal(expectedTokens);
  });

  it('Should be possible to mint manually', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    let balanceBefore = await token.balanceOf(accounts[2]);

    await contract.manualTokenMint(accounts[2], web3.toWei(100, 'ether'));

    let balanceAfter = await token.balanceOf(accounts[2]);
    let expectedTokens = OneToken.mul(100).mul(42000).mul(110).div(100);

    expect(balanceAfter.sub(balanceBefore)).to.be.bignumber.equal(expectedTokens);
  });

  it('Should correctly cross from stage 4 to stage 5', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    let balanceBefore = await token.balanceOf(accounts[2]);

    await contract.sendTransaction({from: accounts[2], value: web3.toWei(1400, 'ether')});
    await contract.sendTransaction({from: accounts[2], value: web3.toWei(1500, 'ether')});
    let balanceAfter = await token.balanceOf(accounts[2]);
    let expectedTokensInStage4 = OneToken.mul(2899).mul(42000).mul(110).div(100);
    let expectedTokensInStage5 = OneToken.mul(1).mul(42000).mul(105).div(100);
    let expectedTokens = expectedTokensInStage4.add(expectedTokensInStage5);
    expect(balanceAfter.sub(balanceBefore)).to.be.bignumber.equal(expectedTokens);
  });

  it('Should correctly cross from stage 5 to stage 6', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    let balanceBefore = await token.balanceOf(accounts[2]);

    let etherbalanceBefore = web3.fromWei(await web3.eth.getBalance(accounts[2]));

    await contract.sendTransaction({from: accounts[2], value: web3.toWei(1500, 'ether')});
    await contract.sendTransaction({from: accounts[2], value: web3.toWei(1500, 'ether')});
    let balanceAfter = await token.balanceOf(accounts[2]);
    let expectedTokensInStage5 = OneToken.mul(2999).mul(42000).mul(105).div(100);
    let etherbalanceAfter = web3.fromWei(await web3.eth.getBalance(accounts[2]))

    const spentBalance = etherbalanceBefore.sub(etherbalanceAfter);

    expect(balanceAfter.sub(balanceBefore)).to.be.bignumber.equal(expectedTokensInStage5);

    expect(spentBalance).to.be.bignumber.equal(2999, 1);
  });

  it('Should have full RefundVault', async () => {
    let contract = await cVTokenCrowdsale.deployed();

    expect(await web3.eth.getBalance(await contract.vault())).to.be.bignumber.equal(OneEther.mul(2000));
  });

  it('Should some in wallet', async () => {
    let contract = await cVTokenCrowdsale.deployed();

    let balanceBefore = collectionWalletBalace;
    let balanceAfter = await web3.eth.getBalance(await contract.wallet())

    expect(balanceAfter.sub(balanceBefore)).to.be.bignumber.equal(OneEther.mul(12950));
  });

  it('Will finalize ICO', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    await contract.setTestNow(await contract.endTime() + 1);

    await contract.finalize();

    expect(await token.owner() == '0x1');

    let balanceBefore = collectionWalletBalace;
    let balanceAfter = await web3.eth.getBalance(await contract.wallet())

    expect(balanceAfter.sub(balanceBefore)).to.be.bignumber.equal(OneEther.mul(14950));
  });

  it('Team reward calculated', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    let tokenBalanceTeamYear1 = await token.balanceOf(await contract.teamYear1());
    let originalTeamBalance = (await contract.kOrgValue()).mul(42000).mul(14).div(100);

    expect(tokenBalanceTeamYear1).to.be.bignumber.equal(originalTeamBalance.div(4));
  });

  it('No leftover tokens', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    expect(await token.balanceOf(contract.address)).to.be.bignumber.equal(0);
  });

});
