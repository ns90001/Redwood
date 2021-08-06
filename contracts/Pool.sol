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
    uint pineBalance = 0;
    uint tokenBalance = 0;
    
    
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
    }
    
    // todo: implement wallet functionality and trading functionality

    // todo: implement withdraw and deposit functions so that a single deposit and a single withdraw can unstake
    // both tokens at the same time
    function deposit(uint tokenAmount, uint pineAmount) external {
        pineBalance += pineAmount;
        tokenBalance += tokenAmount;
    }

    function withdraw(uint tokenAmount, uint pineAmount) external {
        require(pineBalance >= pineAmount && tokenBalance >= tokenAmount);
        pineBalance -= pineAmount;
        tokenBalance -= tokenAmount;
    }
    
    
    function testing(uint testMe) public view returns (uint) {
        if (testMe == 1) {
            return 5;
        } else {
            return 3;
        }
    }
}