pragma solidity 0.5.3;

import './Exc.sol';
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/math/SafeMath.sol';

contract Pool {
    
    /// @notice some parameters for the pool to function correctly, feel free to add more as needed
    address private tokenP;
    address private token1;
    address private dex;
    bytes32 private tokenPT;
    bytes32 private token1T;
    
    // todo: create wallet data structures
    uint public pineBalance = 0;
    uint public tokenBalance = 0;
    bool hasrun = false;
    uint idbuy = 0;
    uint idsell = 0;
    
    // todo: fill in the initialize method, which should simply set the parameters of the contract correctly. To be called once
    // upon deployment by the factory.
    function initialize(address _token0, address _token1, address _dex, uint whichP, bytes32 _tickerQ, bytes32 _tickerT)
    external {
        dex = _dex;

        if (whichP == 1) {
            tokenP = _token0;
            token1 = _token1;
        } else {
            tokenP = _token1;
            token1 = _token0;
        }
        tokenPT = _tickerQ;
        token1T = _tickerT;
        IExc(dex).addToken(token1T, token1);
        IExc(dex).addToken(tokenPT, tokenP);
    }
    
    event Debug(string text);
    event DebugBalances(string name, uint balance);
    
    // todo: implement wallet functionality and trading functionality

    // todo: implement withdraw and deposit functions so that a single deposit and a single withdraw can unstake
    // both tokens at the same time
    function deposit(uint tokenAmount, uint pineAmount) external {
        pineBalance = Exc(dex).traderBalances(address(this),tokenPT);
        tokenBalance = Exc(dex).traderBalances(address(this),token1T);
        pineBalance = SafeMath.add(pineBalance, pineAmount);
        tokenBalance = SafeMath.add(tokenBalance, tokenAmount);
        
        emit DebugBalances("pineBalance", pineBalance);
        emit DebugBalances("tokenBalance", tokenBalance);
        emit DebugBalances("pineAmount", pineAmount);
        emit DebugBalances("tokenAmount", tokenAmount);
        
        IERC20(token1).transferFrom(msg.sender, address(this), tokenAmount);
        IERC20(tokenP).transferFrom(msg.sender, address(this), pineAmount);
        
        IERC20(token1).approve(dex, tokenAmount);
        IERC20(tokenP).approve(dex, pineAmount);
        
        // IExc(dex).getToken(token1T).approve(dex, tokenAmount);
        IExc(dex).deposit(tokenAmount, token1T);
        IExc(dex).deposit(pineAmount, tokenPT);
        
        uint aprice = SafeMath.div(pineBalance, tokenBalance);
        if(hasrun == false){
            idbuy = IExc(dex).makeLimitOrder(token1T, tokenBalance, aprice, IExc.Side.BUY);
            idsell = IExc(dex).makeLimitOrder(token1T, tokenBalance, aprice, IExc.Side.SELL);
            hasrun = true;
        } else {
            IExc(dex).deleteLimitOrder(idbuy, token1T, IExc.Side.BUY);
            IExc(dex).deleteLimitOrder(idsell, token1T, IExc.Side.SELL);
            idbuy = IExc(dex).makeLimitOrder(token1T, tokenBalance, aprice, IExc.Side.BUY);
            idsell = IExc(dex).makeLimitOrder(token1T, tokenBalance, aprice, IExc.Side.SELL);
        }
        emit Debug("deposited!!!");
    }

    function withdraw(uint tokenAmount, uint pineAmount) external {
        pineBalance = Exc(dex).traderBalances(address(this), tokenPT);
        tokenBalance = Exc(dex).traderBalances(address(this), token1T);
        
        emit DebugBalances("pineBalance", pineBalance);
        emit DebugBalances("tokenBalance", tokenBalance);
        emit DebugBalances("pineAmount", pineAmount);
        emit DebugBalances("tokenAmount", tokenAmount);
        
            if (pineBalance >= pineAmount && tokenBalance >= tokenAmount) {
                tokenBalance = SafeMath.sub(pineBalance, pineAmount);
                tokenBalance = SafeMath.sub(tokenBalance, tokenAmount);
                IERC20(token1).approve(dex, tokenAmount);
                IERC20(tokenP).approve(dex, pineAmount);
                // IExc(address(this)).approve(dex, )
                IExc(dex).withdraw(tokenAmount, token1T);
                IExc(dex).withdraw(pineAmount, tokenPT);
        
                uint aprice = SafeMath.div(pineBalance, tokenBalance);
                if(hasrun == false){
                    idbuy = IExc(dex).makeLimitOrder(token1T, tokenBalance, aprice, IExc.Side.BUY);
                    idsell = IExc(dex).makeLimitOrder(token1T, tokenBalance, aprice, IExc.Side.SELL);
                    hasrun = true;
                } else {
                    IExc(dex).deleteLimitOrder(idbuy, token1T, IExc.Side.BUY);
                    IExc(dex).deleteLimitOrder(idsell, token1T, IExc.Side.SELL);
                    idbuy = Exc(dex).makeLimitOrder(token1T, tokenBalance, aprice, IExc.Side.BUY);
                    idsell = Exc(dex).makeLimitOrder(token1T, tokenBalance, aprice, IExc.Side.SELL);
                }
                IERC20(token1).transfer(msg.sender, tokenAmount);
                IERC20(tokenP).transfer(msg.sender, pineAmount);
            }
            emit Debug("withdrew!!!");
    }
    
    
    function testing(uint testMe) public view returns (uint) {
        if (testMe == 1) {
            return 5;
        } else {
            return 3;
        }
    }
}