const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("KFF", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const minAmount = ethers.utils.parseEther('0.1');

    const KFF = await ethers.getContractFactory('KFF');
    const kff = await KFF.deploy('Freedom Flowers', 'KFF', 0, '');

    return { kff, minAmount, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Mint nft", async function () {
      const { kff, minAmount, otherAccount } = await loadFixture(deployFixture);

      const tx = await kff.connect(otherAccount).mint(otherAccount.address, { value: minAmount });
      const receipt = await tx.wait();
      const tokenId = receipt.events[0].args.tokenId;

      expect(tokenId).to.equal(1);
    });

    it("Fail mint nft - not enough ETH", async function () {
      const { kff, minAmount, otherAccount } = await loadFixture(deployFixture);

      await expect(
        kff.connect(otherAccount).mint(otherAccount.address, { value: minAmount.sub(1) })
      ).to.be.revertedWith('Not enough eth');
    });
  });
});
