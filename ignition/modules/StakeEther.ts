import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "hardhat";

// const JAN_1ST_2030 = 1893456000;
// const ONE_GWEI: bigint = 1_000_000_000n;

const StakeEtherModule = buildModule("StakeEtherModule", (m) => {
//   const unlockTime = m.getParameter("unlockTime", JAN_1ST_2030);
//   const lockedAmount = m.getParameter("lockedAmount", ONE_GWEI);

  const stakeEther = m.contract("StakeEther", [], {
    value: ethers.parseEther("0.01"),
  });

  return { stakeEther };
});

export default StakeEtherModule;
