const { expectRevert } = require('@openzeppelin/test-helpers');
const Pin = artifacts.require('dummy/Pin.sol');
const Zrx = artifacts.require('dummy/Zrx.sol');
const Exc = artifacts.require('Exc.sol');

const SIDE = {
    BUY: 0,
    SELL: 1
};

contract('Exc', (accounts) => {

    let pin, zrx, exc;
    const [trader1, trader2] = [accounts[1], accounts[2]];
    const [PIN, ZRX] = ['PIN', 'ZRX']
        .map(ticker => web3.utils.fromAscii(ticker));

    beforeEach(async() => {
        ([pin, zrx] = await Promise.all([
            Pin.new(),
            Zrx.new()
        ]));
        exc = await Exc.new();
    });

    
    it('testing withdraw and deposit', async () => {
        
        // adding 100 pine into trader1's account
        await pin.mint(trader1, 100);
        await pin.approve(exc.address, 100, {from: trader1})
        
        // invalid token test for deposit
        expectRevert(
            exc.deposit(200, web3.utils.fromAscii("invalid token")),
            "revert"
        );
        
        // invalid token test for withdraw
        expectRevert(
            exc.withdraw(100, web3.utils.fromAscii("invalid token")),
            "revert"
        );
        
        // withdrawing more than current balance
        expectRevert(
            exc.withdraw(200, PIN),
            "revert"
        );

    });
    
    it('adding and getting tokens', async () => {
        exc.addToken(PIN, trader1);
    
        // checks that 1 token has been added
        assert(exc.getTokens(), 1);
        
    });
    
    it('testing order functions', async () => {
        
        //making some limit orders
        exc.makeLimitOrder(web3.utils.fromAscii("ABC"), 100, 2, SIDE.BUY);
        exc.makeLimitOrder(web3.utils.fromAscii("ABC"), 150, 4, SIDE.BUY),

        // testing getOrders() to get the orders created above
        assert(exc.getOrders(web3.utils.fromAscii("ABC"), SIDE.BUY), 3);
        
    });
    
});