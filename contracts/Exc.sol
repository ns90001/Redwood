pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;

/// @notice these commented segments will differ based on where you're deploying these contracts. If you're deploying
/// on remix, feel free to uncomment the github imports, otherwise, use the uncommented imports

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/token/ERC20/ERC20.sol';
import '../contracts/libraries/math/SafeMath.sol';
import "./IExc.sol";

contract Exc is IExc{
    /// @notice simply notes that we are using SafeMath for uint, since Solidity's math is unsafe. For all the math
    /// you do, you must use the methods specified in SafeMath (found at the github link above), instead of Solidity's
    /// built-in operators.
    using SafeMath for uint;
    
    /// @notice these declarations are incomplete. You will still need a way to store the orderbook, the balances
    /// of the traders, and the IDs of the next trades and orders. Reference the NewTrade event and the IExc
    /// interface for more details about orders and sides.
    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    bytes32 constant PIN = bytes32('PIN');
    Order[] public Orderbook;
    uint curid = 0; 
    uint curTradeId = 0;


    /// @notice, this is the more standardized form of the main wallet data structure, if you're using something a bit
    /// different, implementing a function that just takes in the address of the trader and then the ticker of a
    /// token instead would suffice
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    
    /// @notice an event representing all the needed info regarding a new trade on the exchange
    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );
    
    // todo: implement getOrders, which simply returns the orders for a specific token on a specific side
    function getOrders(
      bytes32 ticker, 
      Side side) 
      external 
      view
      returns(Order[] memory) {
      Order[] memory temp = new Order[](Orderbook.length);
      uint count = 0;
      for(uint i = 0; i < Orderbook.length; i++){
          if(Orderbook[i].ticker == ticker && Orderbook[i].side == side){
              temp[count] = Orderbook[i];
              count = count + 1;
          }
      }
      Order[] memory toreturn = new Order[](count);
      for(uint i = 0; i < count; i++){
          toreturn[i] = temp[i];
      }
      return toreturn;
    }

    // todo: implement getTokens, which simply returns an array of the tokens currently traded on in the exchange
    function getTokens() 
      external 
      view 
      returns(Token[] memory) {
          Token[] memory returnTokens = new Token[](tokenList.length); 
          for (uint i = 0; i < tokenList.length; i++) {
              returnTokens[i] = tokens[tokenList[i]];
          }
          return returnTokens;
    }
    
    // todo: implement addToken, which should add the token desired to the exchange by interacting with tokenList and tokens
    function addToken(
        bytes32 ticker,
        address tokenAddress)
        external {
            tokens[ticker] = Token(ticker, tokenAddress);
            tokenList.push(ticker);
    }
    
    // todo: implement deposit, which should deposit a certain amount of tokens from a trader to their on-exchange wallet,
    // based on the wallet data structure you create and the IERC20 interface methods. Namely, you should transfer
    // tokens from the account of the trader on that token to this smart contract, and credit them appropriately
    function deposit(
        uint amount,
        bytes32 ticker)
        external tokenExists(ticker) {
            // require(IERC20(tokens[ticker].tokenAddress).balanceOf(msg.sender) >= amount);
            IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
            traderBalances[msg.sender][ticker] = SafeMath.add(traderBalances[msg.sender][ticker], amount);
    }
   
    
    // todo: implement withdraw, which should do the opposite of deposit. The trader should not be able to withdraw more than
    // they have in the exchange.
    function withdraw(
        uint amount,
        bytes32 ticker)
        external tokenExists(ticker) hasEnoughInAccount(ticker, amount){
            IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
            traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount); 
    }
    
    // todo: implement makeLimitOrder, which creates a limit order based on the parameters provided. This method should only be
    // used when the token desired exists and is not pine. This method should not execute if the trader's token or pine balances
    // are too low, depending on side. This order should be saved in the orderBook
    
    // todo: implement a sorting algorithm for limit orders, based on best prices for market orders having the highest priority.
    // i.e., a limit buy order with a high price should have a higher priority in the orderbook.
    function makeLimitOrder(
        bytes32 ticker,
        uint amount,
        uint price,
        Side side)
        external tokenExists(ticker) tokenIsNotPine(ticker) {

        bool isValid;
        
        if (side == Side.BUY) {
            isValid = traderBalances[msg.sender][bytes32('PIN')] >= amount.mul(price);
        } else {
            isValid = traderBalances[msg.sender][ticker] >= amount;
        }
        
        require(isValid == true);
        Order memory LimitOrder = Order(curid, msg.sender, side, ticker, amount, 0, price, now);
        curid += 1;
        Orderbook.push(LimitOrder);
        for(uint i = 1; i< Orderbook.length; i++){
            Order memory item = Orderbook[i];
            uint index = i;
    
            if (side == Side.BUY) {
                //If its a buy order, highest price first
                while(index > 0 && Orderbook[index-1].price < item.price){
                Orderbook[index] = Orderbook[index - 1];
                index -= 1;
                }
                Orderbook[index] = item;
            } else {
                //If its a sell order, lowest price first
                while(index > 0 && Orderbook[index-1].price > item.price){
                Orderbook[index] = Orderbook[index - 1];
                index -= 1;
                }
                Orderbook[index] = item;
            }
        }
        
    }
    
    // todo: implement deleteLimitOrder, which will delete a limit order from the orderBook as long as the same trader is deleting
    // it.
    function deleteLimitOrder(
        uint id,
        bytes32 ticker,
        Side side) external tokenExists(ticker) returns (bool) {
        bool sametrader = false;
        uint index = 0;
        for(uint i = 0; i<Orderbook.length; i++){
            if(Orderbook[i].id == id && Orderbook[i].trader == msg.sender){
                deleteNShift(i);
            }
            break;
        }
    }
    
    function deleteNShift(uint itodel) public {
        uint size = Orderbook.length - 1;
        for(uint i = itodel; i < size; i++){
            Orderbook[i] = Orderbook[i+1];
        }
        delete Orderbook[Orderbook.length - 1];
        Orderbook.length -= 1;
    }
    // todo: implement makeMarketOrder, which will execute a market order on the current orderbook. The market order need not be
    // added to the book explicitly, since it should execute against a limit order immediately. Make sure you are getting rid of
    // completely filled limit orders!
    function makeMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side)
        external tokenExists(ticker) tokenIsNotPine(ticker) {
          if(side == Side.BUY){
             require(traderBalances[msg.sender][ticker] >= amount);
          }
          Order memory marketOrder = Order(curid, msg.sender, side, ticker, amount, 0, 0, now);
          curid += 1;
          uint deleted = 0;
          uint amtcompleted = amount;
          for (uint i = 0; i < SafeMath.sub(Orderbook.length,deleted);i++) {
              if (Orderbook[i].side != side) {
                  Order memory limitOrder = Orderbook[i];
                  bool breaknext = false;
                  uint amt2fil = SafeMath.sub(limitOrder.amount, limitOrder.filled);
                  if (SafeMath.sub(limitOrder.amount, limitOrder.filled) >= amtcompleted) {
                      breaknext = true;
                      amt2fil = amount;
                  }
                  uint pineval = SafeMath.mul(amt2fil, limitOrder.price);
                  if(side == Side.BUY){
                      require(traderBalances[msg.sender][ticker] >= amt2fil);
                      require(traderBalances[msg.sender][bytes32("PIN")] >= pineval);
                      IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, limitOrder.trader, amt2fil);
                      traderBalances[msg.sender][ticker] = SafeMath.sub(traderBalances[msg.sender][ticker], amt2fil); 
                      traderBalances[limitOrder.trader][limitOrder.ticker] = SafeMath.add(traderBalances[limitOrder.trader][limitOrder.ticker], amt2fil); 
                      traderBalances[msg.sender][bytes32("PIN")] = SafeMath.sub(traderBalances[msg.sender][bytes32("PIN")], pineval);
                      traderBalances[limitOrder.trader][bytes32("PIN")] = SafeMath.add(traderBalances[msg.sender][bytes32("PIN")], pineval);
                  } else {
                      require(traderBalances[limitOrder.trader][limitOrder.ticker] >= amt2fil);
                      require(traderBalances[limitOrder.trader][bytes32("PIN")] >= pineval);
                      IERC20(tokens[limitOrder.ticker].tokenAddress).transferFrom(limitOrder.trader, msg.sender, amt2fil);
                      traderBalances[msg.sender][ticker] = SafeMath.add(traderBalances[msg.sender][ticker], amt2fil); 
                      traderBalances[limitOrder.trader][limitOrder.ticker] = SafeMath.sub(traderBalances[limitOrder.trader][limitOrder.ticker], amt2fil); 
                      traderBalances[limitOrder.trader][bytes32("PIN")] = SafeMath.sub(traderBalances[limitOrder.trader][bytes32("PIN")], pineval);
                      traderBalances[msg.sender][bytes32("PIN")] = SafeMath.add(traderBalances[msg.sender][bytes32("PIN")], pineval); 
                  }
                  //Possible source of error:
                  limitOrder.filled = SafeMath.add(limitOrder.filled, amount);
                  emit NewTrade(curTradeId, curid, ticker, msg.sender, limitOrder.trader, limitOrder.amount, limitOrder.price, now);
                  curTradeId = curTradeId.add(1);
                  if(SafeMath.sub(limitOrder.amount, limitOrder.filled) <= 0){
                      amtcompleted = amtcompleted - amt2fil;
                      deleteNShift(i);
                      deleted = SafeMath.add(deleted, 1);
                      i = SafeMath.sub(i, 1);
                  }
                  if(breaknext){
                    break;
                  }
              }
          }
    }
    
    //todo: add modifiers for methods as detailed in handout
    modifier tokenExists(bytes32 ticker) {
        require(tokens[ticker].tokenAddress != address(0));
        _;
    }
    
    modifier tokenIsNotPine(bytes32 ticker) {
        require(ticker != bytes32('PIN'));
        _;
    }
    modifier hasEnoughInAccount(bytes32 ticker, uint amount){
        require(traderBalances[msg.sender][ticker] >= amount);
        _;
    }
}