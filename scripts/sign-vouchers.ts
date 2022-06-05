import { TypedDataDomain } from "@ethersproject/abstract-signer";
import { ethers, getNamedAccounts, getChainId } from "hardhat";
import { writeFileSync, readFileSync } from "fs";
import { NFTVoucher, SignedResult, VOUCHER_TYPE, CONTRACT_ADDRESS } from "../misc/constants";

async function main() {
  const { deployer } = await getNamedAccounts();
  const signer = await ethers.getSigner(deployer);
  console.log("Singer address:", signer.address);

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
  console.log("domain data:", domainData);

  const whitelist = readFileSync(`./whitelist/whitelist_${chainId}.txt`).toString().split("\n");
  const sigMap = new Map<string, SignedResult>();
  await Promise.all(
    whitelist.map(async (list, index) => {
      const struct = list.split(' ');
      const redeemer = ethers.utils.getAddress(struct[0]);
      const amount = parseInt(struct[1]);
      const voucher: NFTVoucher = { 
        index,
        amount,
        redeemer,
      };
      const signature: string = await signer._signTypedData(
        domainData,
        VOUCHER_TYPE,
        voucher,
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
