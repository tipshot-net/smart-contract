/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { MinerNFT, MinerNFTInterface } from "../MinerNFT";

const _abi = [
  {
    inputs: [
      {
        internalType: "string",
        name: "_name",
        type: "string",
      },
      {
        internalType: "string",
        name: "_symbol",
        type: "string",
      },
      {
        internalType: "string",
        name: "_initBaseURI",
        type: "string",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "approved",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "approved",
        type: "bool",
      },
    ],
    name: "ApprovalForAll",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "bool",
        name: "lock_status",
        type: "bool",
      },
    ],
    name: "IsLocked",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "nominee",
        type: "address",
      },
    ],
    name: "NewOwnerNominated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "baseExtension",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "baseURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "cost",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "getApproved",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
    ],
    name: "isApprovedForAll",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "lock",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "locked",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "maxSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_to",
        type: "address",
      },
    ],
    name: "mint",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_address",
        type: "address",
      },
    ],
    name: "nominateNewOwner",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "nominatedOwner",
    outputs: [
      {
        internalType: "address payable",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address payable",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "ownerOf",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_user",
        type: "address",
      },
    ],
    name: "removeWhitelistUser",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "safeTransferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "_data",
        type: "bytes",
      },
    ],
    name: "safeTransferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        internalType: "bool",
        name: "approved",
        type: "bool",
      },
    ],
    name: "setApprovalForAll",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_newBaseExtension",
        type: "string",
      },
    ],
    name: "setBaseExtension",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_newBaseURI",
        type: "string",
      },
    ],
    name: "setBaseURI",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_newCost",
        type: "uint256",
      },
    ],
    name: "setCost",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "index",
        type: "uint256",
      },
    ],
    name: "tokenByIndex",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "index",
        type: "uint256",
      },
    ],
    name: "tokenOfOwnerByIndex",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "tokenURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "unlock",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_owner",
        type: "address",
      },
    ],
    name: "walletOfOwner",
    outputs: [
      {
        internalType: "uint256[]",
        name: "",
        type: "uint256[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_user",
        type: "address",
      },
    ],
    name: "whitelistUser",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "whitelisted",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "withdraw",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
];

const _bytecode =
  "0x600a805460ff60a01b1916905560e0604052600560a081905264173539b7b760d91b60c09081526200003591600d91906200013c565b506104b06080523480156200004957600080fd5b50604051620029dc380380620029dc8339810160408190526200006c9162000295565b825183908390620000859060009060208501906200013c565b5080516200009b9060019060208401906200013c565b5050600a80546001600160a01b0319163317905550620000bb81620000c4565b50505062000375565b600a546001600160a01b03163314620001235760405162461bcd60e51b815260206004820152601360248201527f556e617574686f72697a65642061636365737300000000000000000000000000604482015260640160405180910390fd5b80516200013890600c9060208401906200013c565b5050565b8280546200014a9062000322565b90600052602060002090601f0160209004810192826200016e5760008555620001b9565b82601f106200018957805160ff1916838001178555620001b9565b82800160010185558215620001b9579182015b82811115620001b95782518255916020019190600101906200019c565b50620001c7929150620001cb565b5090565b5b80821115620001c75760008155600101620001cc565b600082601f830112620001f3578081fd5b81516001600160401b03808211156200021057620002106200035f565b604051601f8301601f19908116603f011681019082821181831017156200023b576200023b6200035f565b8160405283815260209250868385880101111562000257578485fd5b8491505b838210156200027a57858201830151818301840152908201906200025b565b838211156200028b57848385830101525b9695505050505050565b600080600060608486031215620002aa578283fd5b83516001600160401b0380821115620002c1578485fd5b620002cf87838801620001e2565b94506020860151915080821115620002e5578384fd5b620002f387838801620001e2565b9350604086015191508082111562000309578283fd5b506200031886828701620001e2565b9150509250925092565b600181811c908216806200033757607f821691505b602082108114156200035957634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052604160045260246000fd5b60805161264462000398600039600081816105e20152610ed901526126446000f3fe60806040526004361061020f5760003560e01c80636352211e11610118578063b88d4fde116100a0578063d5abeb011161006f578063d5abeb01146105d0578063d936547e14610604578063da3ef23f14610634578063e985e9c514610654578063f83d08ba1461069d57600080fd5b8063b88d4fde1461055a578063c66828621461057a578063c87b56dd1461058f578063cf309012146105af57600080fd5b8063880ad0af116100e7578063880ad0af146104db5780638da5cb5b146104f057806395d89b4114610510578063a22cb46514610525578063a69df4b51461054557600080fd5b80636352211e146104735780636a627842146104935780636c0360eb146104a657806370a08231146104bb57600080fd5b806330cc7ae01161019b57806344a0d68a1161016a57806344a0d68a146103d35780634a4c560d146103f35780634f6ccce71461041357806353a47bb71461043357806355f804b31461045357600080fd5b806330cc7ae01461035e5780633ccfd60b1461037e57806342842e0e14610386578063438b6300146103a657600080fd5b806313faede6116101e257806313faede6146102c55780631627540c146102e957806318160ddd1461030957806323b872dd1461031e5780632f745c591461033e57600080fd5b806301ffc9a71461021457806306fdde0314610249578063081812fc1461026b578063095ea7b3146102a3575b600080fd5b34801561022057600080fd5b5061023461022f3660046121f2565b6106b2565b60405190151581526020015b60405180910390f35b34801561025557600080fd5b5061025e6106dd565b60405161024091906123f7565b34801561027757600080fd5b5061028b610286366004612270565b61076f565b6040516001600160a01b039091168152602001610240565b3480156102af57600080fd5b506102c36102be3660046121c9565b610809565b005b3480156102d157600080fd5b506102db600e5481565b604051908152602001610240565b3480156102f557600080fd5b506102c361030436600461208f565b61091f565b34801561031557600080fd5b506008546102db565b34801561032a57600080fd5b506102c36103393660046120db565b610a53565b34801561034a57600080fd5b506102db6103593660046121c9565b610a84565b34801561036a57600080fd5b506102c361037936600461208f565b610b1a565b6102c3610b65565b34801561039257600080fd5b506102c36103a13660046120db565b610bb5565b3480156103b257600080fd5b506103c66103c136600461208f565b610bd0565b60405161024091906123b3565b3480156103df57600080fd5b506102c36103ee366004612270565b610c8e565b3480156103ff57600080fd5b506102c361040e36600461208f565b610cbd565b34801561041f57600080fd5b506102db61042e366004612270565b610d0b565b34801561043f57600080fd5b50600b5461028b906001600160a01b031681565b34801561045f57600080fd5b506102c361046e36600461222a565b610dac565b34801561047f57600080fd5b5061028b61048e366004612270565b610ded565b6102c36104a136600461208f565b610e64565b3480156104b257600080fd5b5061025e611043565b3480156104c757600080fd5b506102db6104d636600461208f565b6110d1565b3480156104e757600080fd5b506102c3611158565b3480156104fc57600080fd5b50600a5461028b906001600160a01b031681565b34801561051c57600080fd5b5061025e611259565b34801561053157600080fd5b506102c361054036600461218f565b611268565b34801561055157600080fd5b506102c3611273565b34801561056657600080fd5b506102c3610575366004612116565b6112ea565b34801561058657600080fd5b5061025e611322565b34801561059b57600080fd5b5061025e6105aa366004612270565b61132f565b3480156105bb57600080fd5b50600a5461023490600160a01b900460ff1681565b3480156105dc57600080fd5b506102db7f000000000000000000000000000000000000000000000000000000000000000081565b34801561061057600080fd5b5061023461061f36600461208f565b600f6020526000908152604090205460ff1681565b34801561064057600080fd5b506102c361064f36600461222a565b61140d565b34801561066057600080fd5b5061023461066f3660046120a9565b6001600160a01b03918216600090815260056020908152604080832093909416825291909152205460ff1690565b3480156106a957600080fd5b506102c361144a565b60006001600160e01b0319821663780e9d6360e01b14806106d757506106d7826114c3565b92915050565b6060600080546106ec90612549565b80601f016020809104026020016040519081016040528092919081815260200182805461071890612549565b80156107655780601f1061073a57610100808354040283529160200191610765565b820191906000526020600020905b81548152906001019060200180831161074857829003601f168201915b5050505050905090565b6000818152600260205260408120546001600160a01b03166107ed5760405162461bcd60e51b815260206004820152602c60248201527f4552433732313a20617070726f76656420717565727920666f72206e6f6e657860448201526b34b9ba32b73a103a37b5b2b760a11b60648201526084015b60405180910390fd5b506000908152600460205260409020546001600160a01b031690565b600061081482610ded565b9050806001600160a01b0316836001600160a01b031614156108825760405162461bcd60e51b815260206004820152602160248201527f4552433732313a20617070726f76616c20746f2063757272656e74206f776e656044820152603960f91b60648201526084016107e4565b336001600160a01b038216148061089e575061089e813361066f565b6109105760405162461bcd60e51b815260206004820152603860248201527f4552433732313a20617070726f76652063616c6c6572206973206e6f74206f7760448201527f6e6572206e6f7220617070726f76656420666f7220616c6c000000000000000060648201526084016107e4565b61091a8383611513565b505050565b600a546001600160a01b031633146109495760405162461bcd60e51b81526004016107e49061245c565b806001600160a01b0381166109a05760405162461bcd60e51b815260206004820152601860248201527f43616e6e6f74207370656369667920302061646472657373000000000000000060448201526064016107e4565b600a546001600160a01b03838116911614156109fe5760405162461bcd60e51b815260206004820181905260248201527f4f776e657220616464726573732063616e2774206265206e6f6d696e6174656460448201526064016107e4565b600b80546001600160a01b0319166001600160a01b0384169081179091556040519081527f4b8d098f259d8e813c68a57f09712ee062e342e1c2bc9063f1827c45b4900a999060200160405180910390a15050565b610a5d3382611581565b610a795760405162461bcd60e51b81526004016107e490612489565b61091a838383611678565b6000610a8f836110d1565b8210610af15760405162461bcd60e51b815260206004820152602b60248201527f455243373231456e756d657261626c653a206f776e657220696e646578206f7560448201526a74206f6620626f756e647360a81b60648201526084016107e4565b506001600160a01b03919091166000908152600660209081526040808320938352929052205490565b600a546001600160a01b03163314610b445760405162461bcd60e51b81526004016107e49061245c565b6001600160a01b03166000908152600f60205260409020805460ff19169055565b600a546001600160a01b03163314610b8f5760405162461bcd60e51b81526004016107e49061245c565b60405133904780156108fc02916000818181858888f19350505050610bb357600080fd5b565b61091a838383604051806020016040528060008152506112ea565b60606000610bdd836110d1565b905060008167ffffffffffffffff811115610c0857634e487b7160e01b600052604160045260246000fd5b604051908082528060200260200182016040528015610c31578160200160208202803683370190505b50905060005b82811015610c8657610c498582610a84565b828281518110610c6957634e487b7160e01b600052603260045260246000fd5b602090810291909101015280610c7e81612584565b915050610c37565b509392505050565b600a546001600160a01b03163314610cb85760405162461bcd60e51b81526004016107e49061245c565b600e55565b600a546001600160a01b03163314610ce75760405162461bcd60e51b81526004016107e49061245c565b6001600160a01b03166000908152600f60205260409020805460ff19166001179055565b6000610d1660085490565b8210610d795760405162461bcd60e51b815260206004820152602c60248201527f455243373231456e756d657261626c653a20676c6f62616c20696e646578206f60448201526b7574206f6620626f756e647360a01b60648201526084016107e4565b60088281548110610d9a57634e487b7160e01b600052603260045260246000fd5b90600052602060002001549050919050565b600a546001600160a01b03163314610dd65760405162461bcd60e51b81526004016107e49061245c565b8051610de990600c906020840190611f64565b5050565b6000818152600260205260408120546001600160a01b0316806106d75760405162461bcd60e51b815260206004820152602960248201527f4552433732313a206f776e657220717565727920666f72206e6f6e657869737460448201526832b73a103a37b5b2b760b91b60648201526084016107e4565b6000610e6f60085490565b600a54909150600160a01b900460ff1615610ed75760405162461bcd60e51b815260206004820152602260248201527f4d696e65724e46543a20436f6e747261637420696e206c6f636b656420737461604482015261746560f01b60648201526084016107e4565b7f00000000000000000000000000000000000000000000000000000000000000008110610f465760405162461bcd60e51b815260206004820152601c60248201527f4d696e65724e46543a204d617820737570706c7920726561636865640000000060448201526064016107e4565b600a546001600160a01b0316331461101457336000908152600f602052604090205460ff16610fb75760405162461bcd60e51b815260206004820152601960248201527f4d696e65724e46543a204e6f742077686974656c69737465640000000000000060448201526064016107e4565b600e5434146110145760405162461bcd60e51b8152602060048201526024808201527f4554482073656e74206d7573742062652065786163746c792073656c6c696e676044820152632066656560e01b60648201526084016107e4565b611028826110238360016124da565b61181f565b5050336000908152600f60205260409020805460ff19169055565b600c805461105090612549565b80601f016020809104026020016040519081016040528092919081815260200182805461107c90612549565b80156110c95780601f1061109e576101008083540402835291602001916110c9565b820191906000526020600020905b8154815290600101906020018083116110ac57829003601f168201915b505050505081565b60006001600160a01b03821661113c5760405162461bcd60e51b815260206004820152602a60248201527f4552433732313a2062616c616e636520717565727920666f7220746865207a65604482015269726f206164647265737360b01b60648201526084016107e4565b506001600160a01b031660009081526003602052604090205490565b600b546001600160a01b03166111b05760405162461bcd60e51b815260206004820152601760248201527f4e6f6d696e61746564206f776e6572206e6f742073657400000000000000000060448201526064016107e4565b600b546001600160a01b031633146112025760405162461bcd60e51b81526020600482015260156024820152742737ba1030903737b6b4b730ba32b21037bbb732b960591b60448201526064016107e4565b600b54600a80546001600160a01b0319166001600160a01b0390921691821790556040519081527f04dba622d284ed0014ee4b9a6a68386be1a4c08a4913ae272de89199cc686163906020015b60405180910390a1565b6060600180546106ec90612549565b610de9338383611839565b600a546001600160a01b0316331461129d5760405162461bcd60e51b81526004016107e49061245c565b600a805460ff60a01b1916908190556040517f34b31e61a2baf88ffda83bb8d6443ee3dc3bff0ac4bef8f406d7fd16c7d82e239161124f91600160a01b90910460ff161515815260200190565b6112f43383611581565b6113105760405162461bcd60e51b81526004016107e490612489565b61131c84848484611908565b50505050565b600d805461105090612549565b6000818152600260205260409020546060906001600160a01b03166113ae5760405162461bcd60e51b815260206004820152602f60248201527f4552433732314d657461646174613a2055524920717565727920666f72206e6f60448201526e3732bc34b9ba32b73a103a37b5b2b760891b60648201526084016107e4565b60006113b861193b565b905060008151116113d85760405180602001604052806000815250611406565b806113e28461194a565b600d6040516020016113f6939291906122b4565b6040516020818303038152906040525b9392505050565b600a546001600160a01b031633146114375760405162461bcd60e51b81526004016107e49061245c565b8051610de990600d906020840190611f64565b600a546001600160a01b031633146114745760405162461bcd60e51b81526004016107e49061245c565b600a805460ff60a01b1916600160a01b908117918290556040517f34b31e61a2baf88ffda83bb8d6443ee3dc3bff0ac4bef8f406d7fd16c7d82e239261124f92900460ff161515815260200190565b60006001600160e01b031982166380ac58cd60e01b14806114f457506001600160e01b03198216635b5e139f60e01b145b806106d757506301ffc9a760e01b6001600160e01b03198316146106d7565b600081815260046020526040902080546001600160a01b0319166001600160a01b038416908117909155819061154882610ded565b6001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92560405160405180910390a45050565b6000818152600260205260408120546001600160a01b03166115fa5760405162461bcd60e51b815260206004820152602c60248201527f4552433732313a206f70657261746f7220717565727920666f72206e6f6e657860448201526b34b9ba32b73a103a37b5b2b760a11b60648201526084016107e4565b600061160583610ded565b9050806001600160a01b0316846001600160a01b031614806116405750836001600160a01b03166116358461076f565b6001600160a01b0316145b8061167057506001600160a01b0380821660009081526005602090815260408083209388168352929052205460ff165b949350505050565b826001600160a01b031661168b82610ded565b6001600160a01b0316146116ef5760405162461bcd60e51b815260206004820152602560248201527f4552433732313a207472616e736665722066726f6d20696e636f72726563742060448201526437bbb732b960d91b60648201526084016107e4565b6001600160a01b0382166117515760405162461bcd60e51b8152602060048201526024808201527f4552433732313a207472616e7366657220746f20746865207a65726f206164646044820152637265737360e01b60648201526084016107e4565b61175c838383611a64565b611767600082611513565b6001600160a01b0383166000908152600360205260408120805460019290611790908490612506565b90915550506001600160a01b03821660009081526003602052604081208054600192906117be9084906124da565b909155505060008181526002602052604080822080546001600160a01b0319166001600160a01b0386811691821790925591518493918716917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef91a4505050565b610de9828260405180602001604052806000815250611b1c565b816001600160a01b0316836001600160a01b0316141561189b5760405162461bcd60e51b815260206004820152601960248201527f4552433732313a20617070726f766520746f2063616c6c65720000000000000060448201526064016107e4565b6001600160a01b03838116600081815260056020908152604080832094871680845294825291829020805460ff191686151590811790915591519182527f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31910160405180910390a3505050565b611913848484611678565b61191f84848484611b4f565b61131c5760405162461bcd60e51b81526004016107e49061240a565b6060600c80546106ec90612549565b60608161196e5750506040805180820190915260018152600360fc1b602082015290565b8160005b8115611998578061198281612584565b91506119919050600a836124f2565b9150611972565b60008167ffffffffffffffff8111156119c157634e487b7160e01b600052604160045260246000fd5b6040519080825280601f01601f1916602001820160405280156119eb576020820181803683370190505b5090505b841561167057611a00600183612506565b9150611a0d600a8661259f565b611a189060306124da565b60f81b818381518110611a3b57634e487b7160e01b600052603260045260246000fd5b60200101906001600160f81b031916908160001a905350611a5d600a866124f2565b94506119ef565b6001600160a01b038316611abf57611aba81600880546000838152600960205260408120829055600182018355919091527ff3f7a9fe364faab93b216da50a3214154f22a0a2b415b23a84c8169e8b636ee30155565b611ae2565b816001600160a01b0316836001600160a01b031614611ae257611ae28382611c5c565b6001600160a01b038216611af95761091a81611cf9565b826001600160a01b0316826001600160a01b03161461091a5761091a8282611dd2565b611b268383611e16565b611b336000848484611b4f565b61091a5760405162461bcd60e51b81526004016107e49061240a565b60006001600160a01b0384163b15611c5157604051630a85bd0160e11b81526001600160a01b0385169063150b7a0290611b93903390899088908890600401612376565b602060405180830381600087803b158015611bad57600080fd5b505af1925050508015611bdd575060408051601f3d908101601f19168201909252611bda9181019061220e565b60015b611c37573d808015611c0b576040519150601f19603f3d011682016040523d82523d6000602084013e611c10565b606091505b508051611c2f5760405162461bcd60e51b81526004016107e49061240a565b805181602001fd5b6001600160e01b031916630a85bd0160e11b149050611670565b506001949350505050565b60006001611c69846110d1565b611c739190612506565b600083815260076020526040902054909150808214611cc6576001600160a01b03841660009081526006602090815260408083208584528252808320548484528184208190558352600790915290208190555b5060009182526007602090815260408084208490556001600160a01b039094168352600681528383209183525290812055565b600854600090611d0b90600190612506565b60008381526009602052604081205460088054939450909284908110611d4157634e487b7160e01b600052603260045260246000fd5b906000526020600020015490508060088381548110611d7057634e487b7160e01b600052603260045260246000fd5b6000918252602080832090910192909255828152600990915260408082208490558582528120556008805480611db657634e487b7160e01b600052603160045260246000fd5b6001900381819060005260206000200160009055905550505050565b6000611ddd836110d1565b6001600160a01b039093166000908152600660209081526040808320868452825280832085905593825260079052919091209190915550565b6001600160a01b038216611e6c5760405162461bcd60e51b815260206004820181905260248201527f4552433732313a206d696e7420746f20746865207a65726f206164647265737360448201526064016107e4565b6000818152600260205260409020546001600160a01b031615611ed15760405162461bcd60e51b815260206004820152601c60248201527f4552433732313a20746f6b656e20616c7265616479206d696e7465640000000060448201526064016107e4565b611edd60008383611a64565b6001600160a01b0382166000908152600360205260408120805460019290611f069084906124da565b909155505060008181526002602052604080822080546001600160a01b0319166001600160a01b03861690811790915590518392907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef908290a45050565b828054611f7090612549565b90600052602060002090601f016020900481019282611f925760008555611fd8565b82601f10611fab57805160ff1916838001178555611fd8565b82800160010185558215611fd8579182015b82811115611fd8578251825591602001919060010190611fbd565b50611fe4929150611fe8565b5090565b5b80821115611fe45760008155600101611fe9565b600067ffffffffffffffff80841115612018576120186125df565b604051601f8501601f19908116603f01168101908282118183101715612040576120406125df565b8160405280935085815286868601111561205957600080fd5b858560208301376000602087830101525050509392505050565b80356001600160a01b038116811461208a57600080fd5b919050565b6000602082840312156120a0578081fd5b61140682612073565b600080604083850312156120bb578081fd5b6120c483612073565b91506120d260208401612073565b90509250929050565b6000806000606084860312156120ef578081fd5b6120f884612073565b925061210660208501612073565b9150604084013590509250925092565b6000806000806080858703121561212b578081fd5b61213485612073565b935061214260208601612073565b925060408501359150606085013567ffffffffffffffff811115612164578182fd5b8501601f81018713612174578182fd5b61218387823560208401611ffd565b91505092959194509250565b600080604083850312156121a1578182fd5b6121aa83612073565b9150602083013580151581146121be578182fd5b809150509250929050565b600080604083850312156121db578182fd5b6121e483612073565b946020939093013593505050565b600060208284031215612203578081fd5b8135611406816125f5565b60006020828403121561221f578081fd5b8151611406816125f5565b60006020828403121561223b578081fd5b813567ffffffffffffffff811115612251578182fd5b8201601f81018413612261578182fd5b61167084823560208401611ffd565b600060208284031215612281578081fd5b5035919050565b600081518084526122a081602086016020860161251d565b601f01601f19169290920160200192915050565b6000845160206122c78285838a0161251d565b8551918401916122da8184848a0161251d565b85549201918390600181811c90808316806122f657607f831692505b85831081141561231457634e487b7160e01b88526022600452602488fd5b808015612328576001811461233957612365565b60ff19851688528388019550612365565b60008b815260209020895b8581101561235d5781548a820152908401908801612344565b505083880195505b50939b9a5050505050505050505050565b6001600160a01b03858116825284166020820152604081018390526080606082018190526000906123a990830184612288565b9695505050505050565b6020808252825182820181905260009190848201906040850190845b818110156123eb578351835292840192918401916001016123cf565b50909695505050505050565b6020815260006114066020830184612288565b60208082526032908201527f4552433732313a207472616e7366657220746f206e6f6e20455243373231526560408201527131b2b4bb32b91034b6b83632b6b2b73a32b960711b606082015260800190565b602080825260139082015272556e617574686f72697a65642061636365737360681b604082015260600190565b60208082526031908201527f4552433732313a207472616e736665722063616c6c6572206973206e6f74206f6040820152701ddb995c881b9bdc88185c1c1c9bdd9959607a1b606082015260800190565b600082198211156124ed576124ed6125b3565b500190565b600082612501576125016125c9565b500490565b600082821015612518576125186125b3565b500390565b60005b83811015612538578181015183820152602001612520565b8381111561131c5750506000910152565b600181811c9082168061255d57607f821691505b6020821081141561257e57634e487b7160e01b600052602260045260246000fd5b50919050565b6000600019821415612598576125986125b3565b5060010190565b6000826125ae576125ae6125c9565b500690565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052601260045260246000fd5b634e487b7160e01b600052604160045260246000fd5b6001600160e01b03198116811461260b57600080fd5b5056fea2646970667358221220a3ba6725d4ec3a01015e9aa43c9637c7d7ce70869f1f158f9f913de3c472ecc664736f6c63430008040033";

export class MinerNFT__factory extends ContractFactory {
  constructor(
    ...args: [signer: Signer] | ConstructorParameters<typeof ContractFactory>
  ) {
    if (args.length === 1) {
      super(_abi, _bytecode, args[0]);
    } else {
      super(...args);
    }
  }

  deploy(
    _name: string,
    _symbol: string,
    _initBaseURI: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<MinerNFT> {
    return super.deploy(
      _name,
      _symbol,
      _initBaseURI,
      overrides || {}
    ) as Promise<MinerNFT>;
  }
  getDeployTransaction(
    _name: string,
    _symbol: string,
    _initBaseURI: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _name,
      _symbol,
      _initBaseURI,
      overrides || {}
    );
  }
  attach(address: string): MinerNFT {
    return super.attach(address) as MinerNFT;
  }
  connect(signer: Signer): MinerNFT__factory {
    return super.connect(signer) as MinerNFT__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MinerNFTInterface {
    return new utils.Interface(_abi) as MinerNFTInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MinerNFT {
    return new Contract(address, _abi, signerOrProvider) as MinerNFT;
  }
}
