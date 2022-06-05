import { TypedDataDomain } from "@ethersproject/abstract-signer";
import { ethers, getNamedAccounts, getChainId } from "hardhat";
import { ethers as eth } from "ethers";
import { writeFileSync, readFileSync } from "fs";
import { NFTVoucher, VOUCHER_TYPE, CONTRACT_ADDRESS } from "../misc/constants";

type SignedResult = {
  voucher: NFTVoucher,
  signature: string,
}

async function main() {
  const { deployer } = await getNamedAccounts();
  console.log("Singer address:", deployer);
  const signer = await ethers.getSigner(deployer);
  // domain data
  const chainId = await getChainId();

  const contractAddr = CONTRACT_ADDRESS[chainId];
  if (!contractAddr) {
    console.log("[ERROR] contract address not set");
    return;
  }

  const domainData: TypedDataDomain = {
    name: "MastersDAO",
    version: "1",
    chainId: chainId,
    verifyingContract: contractAddr,
  };
  const whitelist = readFileSync("./whitelist/whitelist.txt").toString().split("\n");
  const sigMap = new Map<string, SignedResult>();
  await Promise.all(
    whitelist.map(async (list, index) => {
      const struct = list.split(' ');
      const redeemer = eth.utils.getAddress(struct[0]);
      const amount = parseInt(struct[1]);
      const voucher: NFTVoucher = { 
        index,
        redeemer,
        amount,
      };
      const signature: string = await signer._signTypedData(
        domainData,
        VOUCHER_TYPE,
        voucher
      );
      sigMap.set(redeemer, {voucher, signature});
      return signature;
    })
  );
  console.log("voucher count:", sigMap.size);
  writeFileSync(
    `./whitelist/whitelist_${chainId}.json`,
    JSON.stringify(Object.fromEntries(sigMap), null, 2)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
