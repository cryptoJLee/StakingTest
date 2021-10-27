var Stacking = artifacts.require("Staking");
var Token = artifacts.require("ERC20Mock");
module.exports = async function(deployer) {
  await deployer.deploy(Stacking);
  staking = await Stacking.deployed();
  await deployer.deploy(Token, "test", "KTN", staking.address, 1);
};
