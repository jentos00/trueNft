pragma ton-solidity >= 0.52.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './NftRoot.sol';

contract NftRootBase is NftRoot {

    constructor(
        string name,
        string description,
        address addrAuthor
    ) public {
        tvm.accept();
        _name = name;
        _description = description;
        _addrAuthor = addrAuthor;
        _createChecks();
    }

    function getInfo() public returns (
        string version,
        string name,
        string description,
        bytes icon,
        uint128 totalSupply,
        address addrAuthor,
        address addrOwner
    ) {
        version = _version;
        name = _name;
        description = _description;
        icon = _icon;
        totalSupply = _totalSupply;
        addrAuthor = _addrAuthor;
        addrOwner = _addrOwner;
    }
}
