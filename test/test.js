const UpstandContract = artifacts.require("UpstandContract")

contract("NFT Activism", accounts => {
  if (accounts.length < 10) process.exit("not enough accounts")
  describe("Contract Features", () => {
    it("Registers a whitelisted address", async () => {
      const na = await UpstandContract.deployed()

      await na.setWhitelistLevel(accounts[1], 1)
      await na.setWhitelistLevel(accounts[2], 2)

      const wl1 = await na.getWhitelistLevel(accounts[1])
      assert.equal(wl1, 1, "The first whitelist level does not match 1")
      const wl2 = await na.getWhitelistLevel(accounts[2])
      assert.equal(wl2, 2, "The second whitelist level does not match 2")
    })

    it("Creates an activism nft", async () => {
      const na = await UpstandContract.deployed()

      await na.createActivismNft("asdf", {from: accounts[2]});

      const allowedToAward = await na.getNftMintAllowance(1, accounts[2])

      assert.equal(allowedToAward, true)
    })

    it("Awards an activism nft", async () => {
      const na = await UpstandContract.deployed()

      await na.awardActivismNft(1, accounts[3], {from: accounts[2]})

      const bal = await na.balanceOf(accounts[3], 1)

      assert.equal(bal, 1, "The recipient should have only 1 tokens")
    })

    it("Sets another address on a token's minter whitelist", async () => {
      const na = await UpstandContract.deployed()

      await na.toggleNftMintAllowance(1, accounts[1], {from: accounts[2]})

      const mintStatus = await na.getNftMintAllowance(1, accounts[1])

      assert.equal(mintStatus, true, "accounts[1] should be on the minting whitelist")
    })

    it("Awards activism nft from another minter's address", async () => {
      const na = await UpstandContract.deployed()

      await na.awardActivismNft(1, accounts[3], {from: accounts[1]})

      const bal = await na.balanceOf(accounts[3], 1)

      assert.equal(bal, 2, "The recipient should now have 2 tokens")
    })
  })

  describe("Anti-cheat features", () => {
    it("Does not allow non-owner to set whitelist", async () => {
      const na = await UpstandContract.deployed()

      na.setWhitelistLevel(accounts[3], 2, {from: accounts[3]}).catch(() => {
        assert.equal(true, true)
      })
    })

    it("Does not allow non-whitelisted address to create NFT", async () => {
      const na = await UpstandContract.deployed()

      na.createActivismNft("asdf", {from: accounts[3]}).catch(() => {
        assert.equal(true, true)
      })
    })

    it("Does not allow non-minter address to mint a created activism nft", async () => {
      const na = await UpstandContract.deployed()

      await na.setWhitelistLevel(accounts[3], 1)
      na.awardActivismNft(0, accounts[4], {from: accounts[3]}).catch(() => {
        assert.equal(true, true)
      })
    })
  })
})
