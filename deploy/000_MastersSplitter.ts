import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();
  const chainId = await hre.getChainId();
  const isMainnet = chainId === "1";

  const payees = isMainnet?
  [
    deployer, // TODO
  ]:
  [
    "0x567845983Df071999c3b8e680B3cED559312Bf45",
    "0x4b92ddE957ccB9038a3Aa22054356e69773D5645",
    "0xF6bE263C77efdea14067D9381Ee002c8cAE4a33c",
    "0xF633B5C4ae432fCd25006eB67A7bb21DBd60080e",
  ];

  const shares = isMainnet?
  [
    1, // TODO
  ]:
  [
    10,
    10,
    30,
    50,
  ];

  // deploy
  await deploy("MastersSplitter", {
    from: deployer,
    args:[
      payees,
      shares,
    ],
    log: true,
  });
};
export default func;
func.tags = ["MastersDAO"];
