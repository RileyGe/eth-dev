const GreatPay = artifacts.require("GreatPay");

contract('GreatPay--成功交易测试集', (accounts) => {
  it('向合约付钱', async () => {
    const contract = await GreatPay.deployed();
    await contract.Pay.sendTransaction({from: accounts[0], value: web3.utils.toWei('1', 'ether')});
    const status = await contract.dealStatus.call();

    assert.equal(parseInt(status, 10), 2, "Pay not success!");
  });
  it('交易成功', async () => {
    etherDiff = (await web3.eth.getBalance(accounts[2]));
    const contract = await GreatPay.deployed();
    await contract.DealSuccess.sendTransaction({from: accounts[0]});
    etherDiff = (await web3.eth.getBalance(accounts[2])) - etherDiff;

    assert.equal(web3.utils.toWei('1', 'ether'), etherDiff, "deal not success finished!");
  });
});
contract('GreatPay--失败交易测试集', (accounts) => {
  it('向合约付钱', async () => {
    const contract = await GreatPay.deployed();
    await contract.Pay.sendTransaction({from: accounts[0], value: web3.utils.toWei('1', 'ether')});
    const status = await contract.dealStatus.call();

    assert.equal(parseInt(status, 10), 2, "Pay not success!");
  });
  it('交易失败by seller', async () => {
    //首先要获取buyers（accounts[0]）的签名
    let msg = web3.utils.sha3('fail');//在实际使用中不可使用固定的词，否则容易被盗窃
    console.log(msg);
    let signature = await web3.eth.sign(msg, accounts[0]);
    console.log(signature);
    let r = signature.slice(0, 66);
    let s = '0x' + signature.slice(66, 130);
    let v = '0x' + signature.slice(130, 132);
    v = web3.utils.hexToNumber(v) + 27;
    web3.eth.defaultAccount = accounts[2];//默认账号变成seller，则buyer的帐户数量改变为定值
    etherDiff = (await web3.eth.getBalance(accounts[0]));
    const contract = await GreatPay.deployed();
    await contract.DealFailed.sendTransaction(msg, v, r, s, {from: accounts[2]});
    etherDiff = (await web3.eth.getBalance(accounts[0])) - etherDiff;

    assert.equal(web3.utils.toWei('1', 'ether'), etherDiff, "deal not success finished!");
  });
});
