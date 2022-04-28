pragma ton-solidity >= 0.52.0;

import './IData.sol';

enum MintType { OnlyOwner, OnlyFee, OwnerAndFee, All }

interface INftRoot {
    function mintNft(
        string meta
    ) external;
}
