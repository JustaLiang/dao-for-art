import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const parseDate = (date: Date) => {
  return Math.round(date.valueOf()/1000);
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deploy, get } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();
  const chainId = await hre.getChainId();
  const isMainnet = chainId === "1";

  const contractURI = "ipfs://QmafcRHT1EwasBR7KteNTmctGGv4mkNAyVfWEwYAfT9XAg/"; // TODO
  const baseURI = "ipfs://QmazDA25V9CyL55vuPJqqAH7dMe5TtAWjH2KdzXKHminH5/" // TODO
  const saleInfo = isMainnet? {
    isPublic: true,
    startTime: parseDate(new Date(2022, 6-1, 6)), // TODO
    endTime: parseDate(new Date(2022, 6-1, 7)), // TODO
    price: ethers.utils.parseEther("0.1"),
  }:{
    isPublic: true,
    startTime: Math.round(Date.now()/1000) + 60 * 10,
    endTime: Math.round(Date.now()/1000) + 60 * 60 * 24,
    price: ethers.utils.parseEther("0.1"),
  };

  const beneficiary = (await get("MastersSplitter")).address;

  // deploy
  await deploy("MastersDAO", {
    from: deployer,
    args:[
      contractURI,
      baseURI,
      saleInfo,
      beneficiary,
    ],
    log: true,
  });
};
export default func;
func.tags = ["MastersDAO"];
