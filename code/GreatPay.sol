pragma solidity >=0.4.21 <0.6.0;

contract GreatPay {

    address payable public buyer;
    address payable public seller;
    uint public startDate;
    uint public dealTimeout;
    uint public dealPrice;
    uint public dealStatus;//1表示已经购买，没有付款；2表示已经付款

    constructor(address to, uint timeout, uint price) public {
        seller = address(uint160(to));
        buyer = msg.sender;
        startDate = now;
        dealTimeout = timeout;
        dealPrice = price;
        dealStatus = 1;
    }
    function Pay() public payable{
        //buyer建立了交易之后，所有人都可以付款
        if(msg.value >= dealPrice)
            dealStatus = 2;
    }

    //只有buyer可以调用
    function DealSuccess() public payable {
        if(dealStatus == 2)
        {
            require(msg.sender == buyer, "only buyer can call this function!");
            seller.transfer(address(this).balance);
            selfdestruct(msg.sender);
        }        
    }

    //需要买家或卖家调用，需要双方签名
    function DealFailed(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public payable {
        if(dealStatus == 2){
            // get signer from signature
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            address signer = ecrecover(prefixedHash, v, r, s);

            // 保证签名正确
            require(signer == buyer || signer == seller, "signature wrong!");

            if ((signer == buyer && msg.sender == seller) || (signer == seller && msg.sender == buyer)){
                buyer.transfer(address(this).balance);
                selfdestruct(msg.sender);
            }
        }        
    }

    function DealTimeout() public payable {
        if(dealStatus == 2){
            require(startDate + dealTimeout < now, "please wait!");
            seller.transfer(address(this).balance);
            selfdestruct(msg.sender);
        }
        
    }
}