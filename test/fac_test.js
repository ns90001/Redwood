const Pin = artifacts.require('dummy/Pin.sol');
const Zrx = artifacts.require('dummy/Zrx.sol');
const Exc = artifacts.require('Exc.sol');
const Fac = artifacts.require('Factory.sol')
const Pool = artifacts.require('Pool.sol')
const { expectRevert } = require('@openzeppelin/test-helpers');

const SIDE = {
    BUY: 0,
    SELL: 1
};

contract('Factory', (accounts) => {
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
        fac = await Fac.new()
    });

    it('should create the pair and make 5', async () => {
        let event = await fac.createPair(
            pin.address,
            zrx.address,
            pin.address,
            exc.address,
            PIN,
            ZRX
        );
        let log = event.logs[0];
        let poolAd = log.args.pair;
        const pool = await Pool.at(poolAd);
        const checkMe = await pool.testing(1);
        assert(checkMe, 5);
        
        // testing all functions in Pool.sol
        
        // depositing some tokens and pine into the pool
        pool.deposit(100, 100);
        
        // trying to withdraw more than we have in the account
        expectRevert(
            pool.withdraw(200, 200),
            "revert"
        )
        
        pool.withdraw(50, 50);
        
        // verify balances after deposits and withdrawals
        assert(pool.tokenBalance, 50);
        assert(pool.pineBalance, 50);
        
        // deposit of 0
        pool.deposit(0, 0);
        
        //withdrawal of 0
        pool.withdraw(0, 0);
        
        //verify that balances have not changed
        assert(pool.tokenBalance, 50);
        assert(pool.pineBalance, 50);
       
    });
});