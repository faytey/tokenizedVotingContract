import { ethers } from "hardhat";

async function main() {
  const [owner, owner2] = await ethers.getSigners();
  const VoteToken = await ethers.getContractFactory("tokenizedVotingDao");
  const voteToken = await VoteToken.deploy("FITEX", "FTT", 100000000000);
  await voteToken.deployed();

  console.log(`Your voteToken Address is ${voteToken.address}`);
////////////////////////////////////////////////////////////
// DEPLOYMENT COMPLETED..  CONTRACT INTERACTION BEGINS
////////////////////////////////////////////////////////////
const buyToken = await voteToken.buyTokens({value: ethers.utils.parseEther("0.01")})
console.log(buyToken);

const createPool = await voteToken.contestCreation("0x31D97fdb6E31955Ad79899Eb0D28F2d0431684A0","0xa3d008b205d97892fBf937D1fA2Fc5568dB2A254", "0xC5cb2013586755CCeAE6229da853d6Ef96FB26AD");
let event = await createPool.wait();
console.log(event);

let child = await event.events[1].args;
let voteId = child[0];
console.log(`VOTE POOL ID IS ${voteId}`);

const contenders = voteToken.displayContenders(voteId);
const contenders2 = await contenders;
console.log(await contenders2);

const vote = await voteToken.vote(voteId, "0x31D97fdb6E31955Ad79899Eb0D28F2d0431684A0", "0xC5cb2013586755CCeAE6229da853d6Ef96FB26AD", "0xa3d008b205d97892fBf937D1fA2Fc5568dB2A254");

// close voting pool
await voteToken.closeVotingPool(voteId);
const closePool = voteToken.closeVotingPool(voteId);
const win = await voteToken.displayWinner(voteId);
const winner = await win;
console.log(winner);
}

  //  We recommend this pattern to be able to use async/await everywhere
  //  and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});