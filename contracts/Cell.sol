pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./provableAPI_0.5.sol";

pragma solidity ^0.5.16;

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}




pragma solidity ^0.5.0;


contract Cell is ERC721Full, usingProvable {
    using Address for address payable;
    using SafeMath for uint256;

    uint public massPool;
    address payable public owner = address(0xA096b47EbF7727d01Ff4F09c34Fc6591f2c375F0);
    address proxyRegistryAddress;
    uint constant private NUM_RANDOM_BYTES_REQUESTED = 2; //The variable `ceiling` should never be greater than: `(256 ^ NUM_RANDOM_BYTES_REQUESTED) - 1`.
    uint private _currentTokenId;
    uint private gasPrice = 4010000000; //many set exactly 4gwei, so adding 0.01 gwei increases speed much more than expected.
    uint private gasAmount = 250000;
    
    struct Wall {
        uint32 wave;
        bool round;
        uint24 color;
    }

    struct Nucleus {
        bool hidden;
        uint24 color;
    }

    struct Feature {
        uint8 category;
        uint8 family;
        uint8 count;
        uint24 color;
    }

    struct Metadata {
        uint mass;
        Wall wall;
        Nucleus nucleus;
        mapping(uint => Feature) features;
    }

    mapping(uint => Metadata) id_to_cell;
    mapping(bytes32 => uint16) public provableQueryToSeed;
    mapping(bytes32 => address) public provableQueryToAddress;
    mapping(bytes32 => uint) public provableQueryToTokenId;
    mapping(uint => uint) public nftSeed;
    
    event LogMintQuery(address minter, bytes32 queryId, uint seed, uint tokenId);

    constructor(address _proxyRegistryAddress) ERC721Full("Cell", "(Y)") public {
        massPool = 53000000000000000000000000000000000000;
        _mint(msg.sender, 1);
        proxyRegistryAddress = _proxyRegistryAddress;
        provable_setProof(proofType_Ledger);
        provable_setCustomGasPrice(gasPrice);
    }

    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress());

        uint16 seed = provableQueryToSeed[_queryId];
        address minterAddr = provableQueryToAddress[_queryId];
        uint tokenIdR = provableQueryToTokenId[_queryId];

        uint rand = uint(
                keccak256(abi.encodePacked(_result)) ^ blockhash(block.number-1) ^ bytes32(uint(seed))
            );
        nftSeed[tokenIdR] = rand.mod(65535);

        _safeMint(minterAddr,tokenIdR);
        
        delete provableQueryToSeed[_queryId];
        delete provableQueryToAddress[_queryId];
        delete provableQueryToTokenId[_queryId];
    }


    function mint(uint16 seed) public payable {
        require(msg.value == 2 finney);
        require(massPool >= 8);
        uint tokenId = totalSupply() + 1;
        Metadata storage cell = id_to_cell[tokenId];
        cell.mass = 2;
        cell.wall = Wall(1, true, 1);
        cell.nucleus = Nucleus(true, 1);
        cell.features[0] = Feature(1, 1, 1, 1);
        massPool = massPool.sub(8);
        _mint(msg.sender, tokenId);
        owner.toPayable().sendValue(2 finney);

        bytes32 queryId = provable_newRandomDSQuery(
            0, //Execution delay
            NUM_RANDOM_BYTES_REQUESTED,
            gasAmount
        );
        emit LogMintQuery(msg.sender, queryId, seed, _currentTokenId);
        provableQueryToSeed[queryId] = seed;
        provableQueryToAddress[queryId] = msg.sender;
        provableQueryToTokenId[queryId] = tokenId;

    }

    function merge(uint id1, uint id2) public payable {
        require(msg.value == 2 finney);
        require(massPool > 0);
        require(ownerOf(id1) == msg.sender);
        require(ownerOf(id2) == msg.sender);
        uint tokenId = totalSupply() + 1;
        Metadata storage cell = id_to_cell[tokenId];
        cell.mass = 2;
        cell.wall = Wall(1, true, 1);
        cell.nucleus = Nucleus(true, 1);
        cell.features[0] = Feature(1, 1, 1, 1);
        _mint(msg.sender, tokenId);
        _burn(id1);
        _burn(id2);
        owner.toPayable().sendValue(2 finney);
    }

    function split(uint id) public payable {
        require(msg.value == 2 finney);
        require(massPool > 0);
        require(ownerOf(id) == msg.sender);
        uint tokenId = totalSupply() + 1;
        Metadata storage cell = id_to_cell[tokenId];
        cell.mass = 2;
        cell.wall = Wall(1, true, 1);
        cell.nucleus = Nucleus(true, 1);
        cell.features[0] = Feature(1, 1, 1, 1);
        _mint(msg.sender, tokenId);
        id_to_cell[tokenId + 1] = cell;
        _mint(msg.sender, tokenId + 1);
        _burn(id);
        owner.toPayable().sendValue(2 finney);
    }

    function get(uint id) external view returns (uint mass) {
        Metadata memory cell = id_to_cell[id];
        mass = cell.mass;
    }
}