import { BigNumber } from 'ethers';
import hre, { ethers } from 'hardhat';
import { getContractAndData } from '../tasks';

enum Rarity {
  Common,
  Uncommon,
  Rare,
  Epic,
  Legendary
}

type AllowlistConfig = {
  duration: number;
  discount: number;
}

type RoyaltyConfig = {
  treasury: string;
  basisPoints: string;
}

type MintConfig = {
  startTime: number;
  price: BigNumber;
}


type DesignBase = {
  rarity: Rarity
  remaining: BigNumber;
}

interface Design extends DesignBase {
  id: number;
  name: string;
}

type Collection = {
  id: number;
  name: string;
  mintConfig: MintConfig
  allowlistConfig: AllowlistConfig
  allowlist: string[];
  royaltyConfig?: RoyaltyConfig;
  designs: Design[];
  random: boolean;
}

const allowlist = ["0x54bd130b2b31bEF0ee37DcD6BB8A62D9300A52C0", "0x0fF86f706bce6d1DC98fC58CcF6C39ccb2047Af8", "0x2633E2642E83FcAe6F0cbc0D186BAf5dA221BAD1", "0xd85BEcFdef255077603FAb6D24B71B5c5807Fe9d", "0xb7ec2463c84B586CfD55df67D031F2EbaCDCaefa", "0x902380478B443bb8bDc0734385BB19CF3bB71e65", "0x4D73FFfd6d25746bcd72BE1C998107b421e14773", "0xF6D64A23ce944B56EdB2Cb582d3715f88b1308b2", "0xa464d2113b1636a7A39a5bF5A0b1c3C9C937aE3e", "0xD297b259Ca843FF5167B51e030D590Ff70D56E64", "0x43D9eD45Bc6931661402fce8FFe1590413185e21", "0x00000D51150525d92e6848F626Fe86C248a421A5", "0x000036949a1D9667825644183620cDdB7D7FAA1E", "0x0000003d1CAA27701198736E145677f9Fc76364d", "0x01521f06C55526a7fFf11236B9a4ea65986bc1b3", "0x1D35F32431C08c4dfE4df95fa439991f72B0A08e", "0x39eB6Aa9bCb4e9547A3c80b146a8101406058458", "0x3E83AeCaa0d05861264Bb0600179D8FACCe4C27b", "0x47AFBe262dd9b6A3EE2254b004122a87763983e6", "0xB327A450C7D51706228DC5026aA4061b1cD47780", "0x6f8285e2397Cc0d364e38a5FB2783f265c97c533", "0xb7D725F0049a6beE66ad832009c92950D80a44EC", "0xc0f94dC7e6d69A5aF4B6bAf54A0dB8EeDbB10d63", "0x4082e997Ec720A4894EFec53b0d9AabfeeA44cBE", "0xF6644893CD097987ebD69c1a5f7f7429999228bB", "0x3bf0C7912C75d8bF43A10F7f512035378B4617Ff", "0xC5fF7F8bcEc501DCc054307C0a352347FE0880Af", "0x8e8DA8a1cA7CE589a89865fA97135E86C16C2864", "0xf9E87da0D921098Eaab704281FaD081B8abDd8C4", "0x2B73fEB5af7ef568A194499Da1bcE71FF35Cb209", "0xfaff8ac0421d7579C81Bb5B80f979849Df81D4Ee", "0x97a284a91a0B2b683729081dBb3a32116e1Bb6A4", "0x8D6F070e5e3F73758426007dA680324C10C2869C", "0x6A33317bb7A3f02140a36d512B9653AEFD9b072c", "0x498E57a8A689523c957b79692D4DC81B7EAFD203", "0xda485b890e6C44e3B5da7Df953CB0f5B4fe5A743", "0x5b0b89a2C12c8b7B52b528c3894f571E5d57Cb1A", "0x98649049E84c9949176C1379fb92563DA95bCB0E", "0xf44725568d06038a2fc2d4278F19fe8951Fca93B", "0xe0D3B203853Fd07904Ec42188836b967afdDA690", "0x6D825a6e7F785D40017c0FA97BFA803c19Fd651F", "0x17fcDd289a3431cb9Be3Facbda08A26f15B7938A"];

const collections: Collection[] = [
  {
    id: 1,
    name: "Main",
    mintConfig: {
      startTime: 1735689600,
      price: ethers.utils.parseEther("1.0")
    },
    allowlistConfig: {
      duration: 86400,
      discount: 1000,
    },
    allowlist,
    designs: ["Walnut Cue", "Striker Cue", "Ivory Cue", "Classic Cue", "Aqua Cue", "Teak Cue", "Artisan Cue", "Carbon Alloy Cue", "Carbon Ivory Cue", "Clifton Cue", "Huxley Cue", "Raylee Cue", "Marlin Cue", "Granite Cue", "Brass Cue", "Bourbon Cue", "Guardian Cue", "Black & Gold Cue", "Meranti Cue", "Alpha Cue", "Onyx & Brass Cue", "Hyper Cue", "Spin Dr Cue", "Mighty Cue", "Legacy Cue", "Nirvana Cue", "Redvolt Cue", "Servolt Cue", "Shahmans Eye Cue", "Windlass Cue", "Kings Cue", "Caramel Cue", "Lincoln Cue", "Sacred Cue", "Gatekeepers Cue", "Chamber Cue", "Lipton Cue", "Rameses Cue", "Titan Cue", "White Knight Cue", "Robe Cue", "Blue Diamond Cue", "Elixir Cue", "Virility Cue", "Dark Magic Cue", "Cyberpunk Cue", "Zircon Cue", "Samurais Revenge Cue", "Colonels Cue", "Guru Cue", "Artisan Cue", "Divided Cue", "Tanzanite Cue", "Paraiba Cue", "Cottonmouth Cue", "Obsidian Cue", "Temptation Cue", "Amazon Cue", "Polka Dot Cue", "Serrated Cue", "Mystic Flame Cue", "Royal Serpent Cue", "The Walking Stick", "Ethereum Cue", "Bitcoin Cue", "Queens Cue", "Cobra Cue", "Ankh Cue", "Seior Cue", "Dreamcatcher Cue", "Chequered Cue", "Sabre Cue", "Tribal Cue", "Eternal Flame Cue", "Emerald Cue", "Anunnaki Cue", "Mosaic Cue", "The Capacitor", "Explorer Cue", "Goblin Cue", "Steampunk Cue", "Mechanicles Cue", "The Mace", "Alien Cue", "Echo Cue", "Cue Of Destiny", "Eternal Cue", "The Key", "Amethyst Cue", "Master Blaster"]
      .map((name, i) => ({
        id: i + 1,
        name,
        rarity: i < 30 ? Rarity.Common : i < 54 ? Rarity.Uncommon : i < 72 ? Rarity.Rare : i < 84 ? Rarity.Epic : Rarity.Legendary,
        remaining: ethers.utils.parseUnits(i < 30 ? "200" : "100", 'wei')
      })),
    random: true,
  },
  {
    id: 2,
    name: "Country",
    mintConfig: {
      startTime: 1735689600,
      price: ethers.utils.parseEther("1.0")
    },
    allowlistConfig: {
      duration: 86400,
      discount: 1000,
    },
    allowlist,
    designs: ["Armenia Cue", "Australia Cue", "Austria Cue", "Belgium Cue", "Bosnia Cue", "Bulgaria Cue", "Canada Cue", "Chile Cue", "Costa Rica Cue", "Croatia Cue", "Cyprus Cue", "Czech Republic Cue", "Denmark Cue", "Estonia Cue", "Finland Cue", "France Cue", "Germany Cue", "Greece Cue", "Hungary Cue", "Iceland Cue", "Iran Cue", "Ireland Cue", "Italy cue", "Japan Cue", "Latvia Cue", "Lithuania Cue", "Luxembourg Cue", "Malaysia Cue", "Malta Cue", "Moldova Cue", "Montenegro Cue", "Netherlands Cue", "New Zealand Cue", "Macedonia Cue", "Norway Cue", "Poland Cue", "Portugal Cue", "Romania Cue", "Serbia Cue", "Singapore Cue", "Slovakia Cue", "Slovenia Cue", "South Africa Cue", "South Korea Cue", "Spain Cue", "Sweden Cue", "Switzerland Cue", "Tunisia Cue", "Turkey Cue", "UK Cue", "Uruguay Cue", "USA Cue"]
      .map((name, i) => ({
        id: i + 1,
        name,
        rarity: Rarity.Common,
        remaining: ethers.constants.MaxUint256
      })),
    random: false,
  },
  {
    id: 3,
    name: "Sonic",
    mintConfig: {
      startTime: 1735689600,
      price: ethers.utils.parseEther("1.0")
    },
    allowlistConfig: {
      duration: 86400,
      discount: 1000,
    },
    allowlist,
    designs: ["The Contender", "The Instigator", "The Protagonist", "The Regulator", "The Antagonizer"]
      .map((name, i) => ({
        id: i + 1,
        name,
        rarity: i,
        remaining: ethers.utils.parseUnits(["500", "200", "150", "100", "50"][i], 'wei')
      })),
    random: true,
  },
  {
    id: 4,
    name: "MTOP",
    mintConfig: {
      startTime: 1735689600,
      price: ethers.utils.parseEther("1.0")
    },
    allowlistConfig: {
      duration: 86400,
      discount: 1000,
    },
    allowlist,
    designs: ["Devin", "Degen Cue", "Even- Steven", "Father-Time", "Zeus"]
      .map((name, i) => ({
        id: i + 1,
        name,
        rarity: i,
        remaining: ethers.utils.parseUnits(["500", "200", "150", "100", "50"][i], 'wei')
      })),
    random: true,
  }
]

const roleCheck = async (minter: string) => {
  const { contract } = await getContractAndData("A8BallCue", hre)
  const CONTRACT_ROLE = hre.ethers.utils.keccak256(ethers.utils.toUtf8Bytes('CONTRACT_ROLE'));
  const allowed = await contract.hasRole(CONTRACT_ROLE, minter);
  if (!allowed) {
    const tx = await contract.grantRole(CONTRACT_ROLE, minter);
    await tx.wait();
  }
}
const main = async () => {
  const { contract } = await getContractAndData("A8BallCueMinter", hre)
  await roleCheck(contract.address);
  const collectionId = 4;
  const collection = collections.find(col => col.id === collectionId);
  if (!collection) {
    console.error("No collection config found for", collectionId);
    return;
  }
  console.log("Adding collection...")
  const tx = await contract.addCollection(
      collection.id,
      collection.name,
      collection.mintConfig,
      collection.allowlistConfig,
      collection.random,
      true,
  )
  await tx.wait();
  console.log("Added!")

  console.log("Adding designs...")
  const batchSize = 50;
  const batches = Math.ceil(collection.designs.length / batchSize)
  for (let i = 0; i < batches; i++) {
    const tx = await contract.addCollectionDesigns(
        collection.id,
        collection.designs.slice(i*batchSize, i*batchSize+batchSize)
    )
    await tx.wait();
  }
  console.log("Added!")

  if (collection.allowlist.length > 0) {
    console.log("Adding allowlisted...")
    const tx = await contract.addToCollectionAllowlist(collection.id, collection.allowlist);
    await tx.wait();
    console.log("Added!")
  }

  console.log("Done!")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })