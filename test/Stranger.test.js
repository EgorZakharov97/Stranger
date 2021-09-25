const truffleAssert = require('truffle-assertions');
const Stranger = artifacts.require("Stranger");
const expectThrow = require('./helpers/expectThrow');

contract("Stranger", accounts => {

  it("deploy successfully", () =>
    Stranger.deployed()
      .then(instance => instance.balanceOf.call(accounts[0]))
      .then(balance => {
        assert.equal(
          balance.valueOf(),
          0,
          "Balance was not equal 0"
        );
    }));

    it("Author can mint a token", async () => {
        const instance = await Stranger.deployed();
        const result = (await instance.mint.call(accounts[0], "fuck mate", false)).toNumber();
    });

    it("ID starts with 0", async () => {
        const instance = await Stranger.deployed();
        const result = (await instance.mint.call(accounts[0], "fuck mate", false)).toNumber();
        assert.equal(result, 0, "Balance does not start with 0")
    });

    it("Only owner can mint", async () => {
        const instance = await Stranger.deployed();
        await expectThrow(instance.mint.call(accounts[1], "fuck mate", false, {from: accounts[1]}));
    });

});