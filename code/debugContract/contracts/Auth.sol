pragma solidity >=0.4.21 <0.6.0;

contract Auth {      
    function verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns(address signAddress) {
        return ecrecover(hash, v, r, s);
    }
}
