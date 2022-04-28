pragma ton-solidity >= 0.52.0;

import './resolvers/IndexResolver.sol';
import './interfaces/IData.sol';
import './libraries/Errors.sol';
import './libraries/Constants.sol';


contract Data is IData, IndexResolver {

    string _version = "2";
    address _addrOwner;
    address _addrAuthor;
    uint128 _createdAt;
    address _addrRoot;
    string _meta;

    uint256 static public _id;

    bool public _deployed;

    uint128 _royalty;
    uint128 _royaltyMin;

    bool _onSale;
    uint128 _price;

    constructor(
        address addrOwner,
        address addrAuthor,
        string meta,
        TvmCell codeIndex
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), Errors.CONTRACT_CODE_NOT_SALTED);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, Errors.INVALID_CALLER);
        require(msg.value >= Constants.DEPLOY_SM, Errors.INVALID_VALUE);
        _addrOwner = addrOwner;
        _addrAuthor = addrAuthor;
        _createdAt = uint128(now);
        _addrRoot = addrRoot;
        _meta = meta;
        _codeIndex = codeIndex;

        deployIndex(addrOwner);
    }

    function setRoyalty(uint128 royalty, uint128 royaltyMin) public override {
        require(msg.sender == _addrAuthor, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);
        require(_royalty <= 100000, Errors.INVALID_ARGUMENTS);
        require(_royalty == 0 && _royaltyMin == 0, Errors.ROYALTY_ALREADY_SET);

        _royalty = royalty;
        _royaltyMin = royaltyMin;

        msg.sender.transfer({ value: 0, flag: 64 });
    }

    function putOnSale(uint128 price) public override {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);

        _price = price;
        _onSale = true;

        msg.sender.transfer({ value: 0, flag: 64 });
    }

    function removeFromSale() public override {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);
        require(_onSale == true, Errors.CONTRACT_IS_NOT_ON_SALE);

        _price = 0;
        _onSale = false;

        msg.sender.transfer({ value: 0, flag: 64 });
    }

    function buy() public override {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        require(
            msg.value >= (uint256(_price * _royalty / 100000) < _royaltyMin ? _royaltyMin : _price * _royalty / 100000) + Constants.PROCESS_MIN,
            Errors.INVALID_VALUE
        );
        require(_onSale == true, Errors.CONTRACT_IS_NOT_ON_SALE);

        _price = 0;
        _onSale = false;

        // msg.sender.transfer({ value: 0, flag: 64 });
    }

    function transfer(address addrTo) public override {
        transferValidation();
        transferLogic();

        address oldIndexOwner = resolveIndex(
            _addrRoot,
            address(this),
            _addrOwner
        );
        IIndex(oldIndexOwner).destruct();
        address oldIndexOwnerRoot = resolveIndex(
            address(0),
            address(this),
            _addrOwner
        );
        IIndex(oldIndexOwnerRoot).destruct();

        _addrOwner = addrTo;

        deployIndex(addrTo);
    }

    function transferValidation() internal virtual inline {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.DEPLOY_SM, Errors.INVALID_VALUE);
        require(_onSale != true, Errors.CONTRACT_IS_ON_SALE);
    }

    function transferLogic() internal virtual inline {
    }

    function deployIndex(address owner) internal {
        TvmCell codeIndexOwner = _buildIndexCode(_addrRoot, owner);
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index{stateInit: stateIndexOwner, value: Constants.DEPLOY_MIN}(_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), owner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: Constants.DEPLOY_MIN}(_addrRoot);
    }


    function getInfo() public view returns (
        string version,
        address addrOwner,
        address addrAuthor,
        uint128 createdAt,
        address addrRoot,
        string meta,
        uint128 royalty,
        uint128 royaltyMin
    ) {
        version = _version;
        addrOwner = _addrOwner;
        addrAuthor = _addrAuthor;
        createdAt = _createdAt;
        addrRoot = _addrRoot;
        meta = _meta;
        royalty = _royalty;
        royaltyMin = _royaltyMin;
    }
}
