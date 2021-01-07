pragma solidity >=0.4.21 <0.6.0;

contract GreatPay {

    address payable public buyer;
    address payable public seller;
    uint public startDate;
    uint public dealTimeout;
    uint public dealPrice;
    uint public dealStatus;//1表示已经购买，没有付款;2表示已经付款;3表示存在争议
    mapping (address => bool) public referees;
    uint private voteBuyer;
    uint private voteSeller;

    constructor(address to, uint timeout, uint price) public {
        seller = address(uint160(to));
        buyer = msg.sender;
        startDate = now;
        dealTimeout = timeout;
        dealPrice = price;
        dealStatus = 1;
    }
    function BeReferee() public {
        referees[msg.sender] = true;
    }
    function Vote(bytes32 hash, uint8 v, bytes32 r, bytes32 s, bool isVoteBuyer) public {
        if(dealStatus == 3){
            // get signer from signature
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            address signer = ecrecover(prefixedHash, v, r, s);

            prefixedHash = keccak256(abi.encodePacked(this, isVoteBuyer));

            // 保证信息正确
            require(prefixedHash == hash, "signed information wrong");

            // 保证签名正确
            require(referees[signer], "not referee!");

            if(isVoteBuyer) voteBuyer += 1;
            else voteSeller += 1;
        }        
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

    // 需要买家或卖家调用，需要双方签名
    function DealFailed(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public payable {
        if(dealStatus == 2){
            // get signer from signature
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            address signer = ecrecover(prefixedHash, v, r, s);

            prefixedHash = keccak256(abi.encodePacked(this, "fail"));

            // 保证信息正确
            require(prefixedHash == hash, "signed information wrong");

            // 保证签名正确
            require(signer == buyer || signer == seller, "signature wrong!");

            dealStatus = 3;
        }        
    }

    function DealTimeout() public payable {
        require(startDate + dealTimeout < now, "please wait!");
        if(dealStatus == 2 || (dealStatus == 3 && (voteSeller > voteBuyer))){            
            seller.transfer(address(this).balance);
            selfdestruct(msg.sender);
        }else{
            buyer.transfer(address(this).balance);
            selfdestruct(msg.sender);
        }
        
    }
}