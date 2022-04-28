pragma ton-solidity >= 0.52.0;

interface IData {
    function transfer(address addrTo) external;
    function setRoyalty(uint128 royalty, uint128 royaltyMin) external;
    function putOnSale(uint128 price) external;
    function removeFromSale() external;
    function buy() external;
}
