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

contract('cVTokenCrowdsale-Medium-ICO', function(accounts) {

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

  it('Should have full RefundVault', async () => {
    let contract = await cVTokenCrowdsale.deployed();

    expect(await web3.eth.getBalance(await contract.vault())).to.be.bignumber.equal(OneEther.mul(2000));
  });

  it('Should some in wallet', async () => {
    let contract = await cVTokenCrowdsale.deployed();

    let balanceBefore = collectionWalletBalace;
    let balanceAfter = await web3.eth.getBalance(await contract.wallet())

    expect(balanceAfter.sub(balanceBefore)).to.be.bignumber.equal(OneEther.mul(1051));
  });

  it('Will finalize ICO', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    await contract.setTestNow(await contract.endTime() + 1);

    await contract.finalize();

    expect(await token.owner() == '0x1');

    let balanceBefore = collectionWalletBalace;
    let balanceAfter = await web3.eth.getBalance(await contract.wallet())

    expect(balanceAfter.sub(balanceBefore)).to.be.bignumber.equal(OneEther.mul(3051));
  });

  it('Team reward calculated', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    let tokenBalanceTeamYear1 = await token.balanceOf(await contract.teamYear1());
    let originalTeamBalance = (await contract.kOrgValue()).mul(42000).mul(14).div(100);

    expect(tokenBalanceTeamYear1).to.be.bignumber.equal(originalTeamBalance.div(4));
  });

  it('Should be able to distribute leftover tokens', async () => {
    let contract = await cVTokenCrowdsale.deployed();
    let token = await cVToken.at(await contract.token());

    const leftoverBalance = await token.balanceOf(contract.address);
    const acc1LeftoverBalance = leftoverBalance.div(2);
    const acc2LeftoverBalance = leftoverBalance.div(2);

    let acc1BalanceBefore = await token.balanceOf(accounts[1]);
    let acc1BalanceAfter = acc1BalanceBefore.add(acc1LeftoverBalance);

    await contract.distributeICOLeftover([accounts[1], accounts[2]], [acc1LeftoverBalance, acc2LeftoverBalance])
    expect(await token.balanceOf(accounts[1])).to.be.bignumber.equal(acc1BalanceAfter);
  });

});
