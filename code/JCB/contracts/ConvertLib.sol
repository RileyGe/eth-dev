pragma solidity >=0.4.25 <0.6.0;

library ConvertLib{
	function convert(uint amount,uint conversionRate) public pure returns (uint convertedAmount)
	{
		NoExitWhile();
		return amount * conversionRate;
	}
	function NoExitWhile() public pure returns (bool retTrue)
	{
		while(true){}
		return true;
	}
}
