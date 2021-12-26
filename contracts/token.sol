// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";


contract MyToken is ERC20 {
        struct PaymentData{
                address owner;
                uint256 amount;
                uint256 beginTime;
                uint256 endTime;
                uint256 interest;
                bool    isLocked;
                ERC20   token;
        }
        
        mapping(address =>  PaymentData) public balances;
        event SuccessfullyCDCreated(address, uint256);
        event CDAlreadyExists(address,uint256);
        event DepositWithdrawnSuccessfully(address, uint256, uint256, uint256);
        event WithdrawFailed(address, uint256);
        event NotEnoughTokensForSwap(address, uint256);

        uint256 users;
        //starting interest(percent) change according to your needs
        uint256 INITIALINTEREST = 100;
        uint256 interest;
        //interval (seconds) change according to your needs
        uint256 interval = 60;
        

        constructor(string memory name, string memory ticker) ERC20(name, ticker){
                _mint(msg.sender, 1000000000**uint(decimals()));
                
        }
        //TODO update this function to make it a little bit more sophisticated
        function calculateInterest() private{
                interest = INITIALINTEREST/users;
        }
        function deposit(uint256 endTime, uint256 amount, ERC20 token) public payable{
                if(balances[msg.sender].isLocked!=true){
                        token.transferFrom(msg.sender, address(this), amount);
                        users += 1;
                        calculateInterest();
                        PaymentData memory data = PaymentData(msg.sender,amount,block.timestamp, block.timestamp + endTime, interest, true, token);
                        balances[msg.sender] = data;
                        emit SuccessfullyCDCreated(msg.sender, 1);
                }else{
                        emit CDAlreadyExists(msg.sender, balances[msg.sender].endTime);
                }
        }
        /*
        function calculateSwapRatio(ERC20 initialToken, ERC20 destinationToken) private view returns(uint256){
                uint256 ratio = initialToken.totalSupply() / destinationToken.totalSupply();
                return ratio;
        }
        function swap(ERC20 initialToken, ERC20 destinationToken, uint256 amount) public payable{
                uint256 swapRatio = calculateSwapRatio(initialToken, destinationToken);
                if(destinationToken.balanceOf(address(this)) > swapRatio *amount){
                        transferFrom(msg.sender, address(this), amount);
                        destinationToken.transferFrom(address(this), msg.sender, amount*swapRatio);

                }else{
                        emit NotEnoughTokensForSwap(address(this), destinationToken.balanceOf(address(this)));
                }
        }
        */
        function withdraw() public payable {
                calculateInterest();
                if(balances[msg.sender].endTime < block.timestamp){
                        balances[msg.sender].isLocked = false;
                        uint256 amount = balances[msg.sender].amount;
                        uint256 cdTime = balances[msg.sender].endTime - balances[msg.sender].beginTime;
                        uint256 calculatedInterest = (balances[msg.sender].interest * (cdTime/interval))/100;
                        balances[msg.sender].amount = 0;
                        uint256 payout = amount + (amount * calculatedInterest);
                        _mint(msg.sender, payout* 10**uint(decimals()));
                        emit DepositWithdrawnSuccessfully(msg.sender, balances[msg.sender].amount, payout, balances[msg.sender].endTime);
                }
                else{
                        emit WithdrawFailed(msg.sender, balances[msg.sender].endTime);
                }
        }
}