
import { TypedDataField } from "@ethersproject/abstract-signer";
import { BigNumberish } from "ethers";

export type NFTVoucher = {
  index: BigNumberish;
  amount: BigNumberish;
  redeemer: string;
};

export type SignedResult = {
  voucher: NFTVoucher;
  signature: string;
};

export const VOUCHER_TYPE: Record<string, TypedDataField[]> = {
  NFTVoucher: [
    { name: "index", type: "uint256" },
    { name: "amount", type: "uint256" }, 
    { name: "redeemer", type: "address" },
  ]
};

type AddressMap = { [chainId: string]: string };

export const CONTRACT_ADDRESS: AddressMap = {
     "1": "0x970aAd14d99Ab8ff4DC699458a2183F44c1A6507",
     "4": "0x8ab314eB7fb9cc8CBe050408A8FA93Be88C0E163",
  "1337": "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
}