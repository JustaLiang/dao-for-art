
import { TypedDataField } from "@ethersproject/abstract-signer";

export type NFTVoucher = {
    index: number,
    redeemer: string,
    amount: number,
};

export const VOUCHER_TYPE: Record<string, TypedDataField[]> = {
    NFTVoucher: [
      { name: "index", type: "uint16" },
      { name: "redeemer", type: "address" },
      { name: "amount", type: "uint16" }, 
    ]
};

type AddressMap = { [chainId: string]: string }

export const CONTRACT_ADDRESS: AddressMap = {
  '1':    '0x970aAd14d99Ab8ff4DC699458a2183F44c1A6507',
  '4':    '0x8ab314eB7fb9cc8CBe050408A8FA93Be88C0E163',
  '1337': '0x5FbDB2315678afecb367f032d93F642f64180aa3',
}