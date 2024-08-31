import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "hardhat";

const tokenAddress = "0xAB35C28842fBCAef412af34d2242D29C187b8483";

const StakeTokenModule = buildModule("StakeTokenModule", (m) => {

//   const lockedAmount = m.getParameter("lockedAmount", ONE_GWEI);

  const stakeToken = m.contract("StakeToken", [tokenAddress]);

  return { stakeToken };
});

export default StakeTokenModule;