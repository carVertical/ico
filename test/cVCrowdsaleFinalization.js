const BigNumber = require('bignumber.js');

const chai = require('chai');
chai.use(require('chai-as-promised'));
chai.use(require('chai-bignumber')(BigNumber));

const expect = chai.expect;

const cVCrowdsaleFinalization = artifacts.require("./cVCrowdsaleFinalization.sol");
const cVCrowdsaleFinalizationMock = artifacts.require("./cVCrowdsaleFinalizationMock.sol");

const cVToken = artifacts.require("./cVToken.sol");
const cVTokenMock = artifacts.require("./cVTokenMock.sol");

const OneEther = new BigNumber(web3.toWei(1, 'ether'));
const OneToken = new BigNumber(web3.toWei(1, 'ether'));

contract('cVCrowdsaleFinalization', (accounts) => {

  const realTokenAddress = '0xdA6cb58A0D0C01610a29c5A65c303e13e885887C';

  let currentTime;

  it('contract should have real Token address', async () => {
    const c = await cVCrowdsaleFinalization.deployed();
    await c.tokenSetup();

    const tokenAddress = await c.token();

    assert.equal(tokenAddress, realTokenAddress.toLowerCase(), 'token address is real');
  });

  it('mock should be non-zero', async () => {
    let m = await cVCrowdsaleFinalizationMock.deployed();
    await m.tokenSetup();

    const tokenAddress = await m.token();
    const t = await cVToken.at(tokenAddress);

    expect(await t.totalSupply()).to.be.bignumber.equal('4637734523665296890795280000');
  });

  it('tokens should be correctly distributed', async () => {
    let m = await cVCrowdsaleFinalizationMock.deployed();
    const { receipt } = await m.tokenSetup();

    const block = web3.eth.getBlock(receipt.blockNumber);
    currentTime = block.timestamp;

    const tokenAddress = await m.token();
    const t = await cVToken.at(tokenAddress);

    await m.transferTokenOwnership(accounts[0]);
    await t.mint(accounts[0], OneToken);

    const monthInSec = (31536000 / 12);
    const inTwoMonths = (currentTime + monthInSec * 2)

    await t.lockTill(accounts[1], inTwoMonths);

    await t.transferOwnership(m.address);

    const totalSold = await t.totalSupply();

    await m.distributeTokens();

    const totalSupply = await t.totalSupply();

    const wallets = {
      teamYear1: '0x66BD5aDa347071D73D3cb6fc21dCAee28DB6f356',
      teamYear2: '0x3549a1463A78B44930F6BF6DefaD518B08C0523D',
      teamYear3: '0xfC1827355d7340aC40482c85e9Be6dE8eF71E45A',
      teamYear4: '0xbaA3895cCa486500494b678E0B3Abd487eAeC99e',
      foundersYear1: '0x27c90dE13eE38D41fC78b6939C4ECc754bF22cAf',
      foundersYear2: '0xC56E30E3358613b8D3f4E066C12eEAFefcCD0966',
      foundersYear3: '0x1c76b7B84A90D1CbB330b6Cb6E73208FBe674A7E',
      foundersYear4: '0x4c57513Abec55c9FfF8e7aBF915B63E94eDb0eFC',
      teamICOBonusWallet: '0x5661c9a1899fbF122F6ca9de26144f2ff2213a50',
      specialMintWallet: '0x3FEA3828f22d0AD4846F0D20CC145070D96BC85b',
      earlyBirdsWallet: '0x75F5eDC08A468a8596D2248814B9A1d1c5653D1D'
    };

    const percentages = {
      teamYear1: 3,
      teamYear2: 3,
      teamYear3: 3,
      teamYear4: 3,
      foundersYear1: 2.5,
      foundersYear2: 2.5,
      foundersYear3: 2.5,
      foundersYear4: 2.5,
      teamICOBonusWallet: 11,
      specialMintWallet: 1,
      earlyBirdsWallet: 23+43  // earlyBirdsPool + icoPool
    };

    await Promise.all(Object.keys(wallets).map(async (key) => {
      let balance = await t.balanceOf(wallets[key]);

      if (key === 'earlyBirdsWallet') {
        balance = balance.add(totalSold);
      }

      const actualPercentage = balance.div(totalSupply).mul(100).toNumber();
      const expectedPercentage = percentages[key];
      expect(actualPercentage).to.be.equal(expectedPercentage);
    }))

    expect(totalSupply).to.be.bignumber.equal('9931143978000000000000000000');
    expect((await t.balanceOf(accounts[0]))).to.be.bignumber.equal(OneToken);
  });

  it('tokens should not be transferable', async () => {
    let m = await cVCrowdsaleFinalizationMock.deployed();

    const tokenAddress = await m.token();
    const t = await cVToken.at(tokenAddress);

    await expect(t.transfer('0x3FEA3828f22d0AD4846F0D20CC145070D96BC85b', OneToken, {from: accounts[0]})).eventually.rejected;
  });

  it('tokens should be transferable', async () => {
    let m = await cVCrowdsaleFinalizationMock.deployed();

    await m.makeTokenTransferable();

    const tokenAddress = await m.token();
    const t = await cVToken.at(tokenAddress);

    const balanceBeforeFrom = await t.balanceOf(accounts[0]);
    const balanceBeforeTo = await t.balanceOf(accounts[1]);

    await t.transfer(accounts[1], OneToken, {from: accounts[0]});

    const balanceAfterFrom = await t.balanceOf(accounts[0]);
    const balanceAfterTo = await t.balanceOf(accounts[1]);

    expect(balanceBeforeFrom.sub(balanceAfterFrom)).to.be.bignumber.equal(OneToken);
    expect(balanceAfterTo.sub(balanceBeforeTo)).to.be.bignumber.equal(OneToken);
  });

  it('tokens should be frozable', async () => {
    let m = await cVCrowdsaleFinalizationMock.deployed();

    const tokenAddress = await m.token();
    const t = await cVTokenMock.at(tokenAddress);

    async function jumpMonthForward(_monthCount) {
      const monthInSec = (31536000 / 12);
      currentTime += monthInSec * _monthCount;

      await t.setNow(currentTime);
    }

    currentTime += 1;

    await expect(t.transfer(accounts[2], OneToken, {from: accounts[1]})).eventually.rejected;
    await jumpMonthForward(1);
    await expect(t.transfer(accounts[2], OneToken, {from: accounts[1]})).eventually.rejected;
    await jumpMonthForward(1);
    await expect(t.transfer(accounts[2], OneToken, {from: accounts[1]})).eventually.fulfilled;
  });

  it('tokens should own itself', async () => {
    let m = await cVCrowdsaleFinalizationMock.deployed();

    const tokenAddress = await m.token();
    const t = await cVTokenMock.at(tokenAddress);

    await expect(m.transferTokenOwnership(accounts[3])).eventually.rejected;
    await expect(t.transferOwnership(accounts[3])).eventually.rejected;

    expect(await t.owner()).to.be.equal(t.address);
  });

});
