// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.1 <0.9.0;

import "../contracts/Token.sol";

contract DEX {

    Token private token1 = new Token("TK1");
    Token private token2 = new Token("TK2");

    struct Order {
        uint256 value;
        uint256 price;
        address from;
        address to;
    }
    
    Order[] internal askOrders;
    Order[] internal bidOrders;

    function getToken(Token token) private view returns(string memory, uint256, address) {
        return (token.name(), token.balanceOf(token.getOrigin()), token.getOrigin());
    }

    function getToken1() public view returns(string memory, uint256, address) {
        return getToken(token1);
    }

    function getToken2() public view returns(string memory, uint256, address) {
        return getToken(token2);
    }

    function swap(address from1, address to2, uint256 amount1, address from2, address to1, uint256 amount2) public {
        require(amount1 > 0 && amount2 > 0, "only possitive number of tokens can be swapped");
        require(token1.balanceOf(from1) >= amount1 && token2.balanceOf(from2) >= amount2, "address should have enough tokens to swap");
        token1.increaseAllowance(from1, amount1);
        token1.recordTransfer(to1, amount1);
        token2.increaseAllowance(from2, amount2);
        token2.recordTransfer(to2, amount2);
    }

    function getTransferCounts() public view returns(uint256, uint256) {
        return (token1.getTransfersCount(), token2.getTransfersCount());
    }

    function getBalanceToken1(address adr) public view returns(uint256) {
        return token1.balanceOf(adr);
    }

    function getBalanceToken2(address adr) public view returns(uint256) {
        return token2.balanceOf(adr);
    }

    function makeAskOrder(address recipient, uint256 price, uint256 amount) external {
        require(amount > 0, "only possitive number of tokens can be put in order");
        insertOrder(askOrders, Order(amount, price, msg.sender, recipient));
        matchOrders();
    }

    function makeBidOrder(address recipient, uint256 price, uint256 amount) external {
        require(amount > 0, "only possitive number of tokens can be put in order");
        insertOrder(bidOrders, Order(amount, price, msg.sender, recipient));
        matchOrders();
    }

    function cancelAskOrder() external {
        if(askOrders.length > 0) {
            removeAskOrder();
        }
    }

    function cancelBidOrder() external {
        if(bidOrders.length > 0) {
            removeBidOrder();
        }
    }

    function insertOrder(Order[] storage orders, Order memory order) internal {
        bool isInserted = false;
        Order[] memory tmpOrders = new Order[](orders.length + 1);
        for(uint256 i = 0; i < orders.length; i++) {
            if(order.price <= orders[i].price && !isInserted) {
                tmpOrders[i] = order;
                i += 1;
                isInserted = true;
            } else {
                tmpOrders[i] = orders[i];
            }
        }
        if(!isInserted) {
            tmpOrders[orders.length] = order;
        }
        for(uint256 i = 0; i < orders.length; i++) {
            orders.pop();
        }
        for(uint256 i = 0; i < tmpOrders.length; i++) {
            orders.push(tmpOrders[i]);
        }
    }

    function askOrdersCount() external view returns(uint256) {
        return askOrders.length;
    }

    function bidOrdersCount() external view returns(uint256) {
        return bidOrders.length;
    }

    function OrderCounts() public view returns(uint256, uint256) {
        return (askOrders.length, bidOrders.length);
    }

    function removeBidOrder() internal {
        Order[] memory tmpOrders = new Order[](bidOrders.length - 1);
        for(uint256 i = 0; i < tmpOrders.length; i++) {
            tmpOrders[i] = bidOrders[i + 1];
        }
        for(uint256 i = 0; i < bidOrders.length; i++) {
            bidOrders.pop();
        }
        for(uint256 i = 0; i < tmpOrders.length; i++) {
            bidOrders.push(tmpOrders[i]);
        }
    }

    function removeAskOrder() internal {
        askOrders.pop();
    }

    event OrderInfo(uint256 value, uint256 price, address from, address to);
    event EmitBool(bool b, string description);
    event EmitUint(uint256 i, string description);

    function matchOrders() internal {
        bool flag = true;
        while(askOrders.length != 0 && bidOrders.length != 0 && askOrders[askOrders.length - 1].price >= bidOrders[0].price && flag) {
            Order storage askOrder = askOrders[askOrders.length - 1];
            emit OrderInfo(askOrder.value, askOrder.price, askOrder.from, askOrder.to);
            Order storage bidOrder = bidOrders[0];
            emit OrderInfo(bidOrder.value, bidOrder.price, bidOrder.from, bidOrder.to);
            emit EmitBool(askOrder.value > token1.balanceOf(askOrder.from), "askOrder.value > token1.balanceOf(askOrder.from)");
            emit EmitBool(bidOrder.value > token2.balanceOf(bidOrder.from), "bidOrder.value > token2.balanceOf(bidOrder.from)");
            emit EmitUint(token1.balanceOf(askOrder.from), "token1.balanceOf(askOrder.from)");
            emit EmitUint(token2.balanceOf(bidOrder.from), "token2.balanceOf(bidOrder.from)");
            if(askOrder.value > token1.balanceOf(askOrder.from)) {
                flag = false;
                removeAskOrder();
            }
            if(bidOrder.value > token2.balanceOf(bidOrder.from)) {
                flag = false;
                removeBidOrder();
            }
            if(flag) {
                if(askOrder.value * askOrder.price > bidOrder.value * bidOrder.price) {
                    uint256 tmpPrice = askOrder.price;
                    askOrder.price = bidOrder.price;
                    swap(askOrder.from, askOrder.to, bidOrder.value * bidOrder.price, bidOrder.from, bidOrder.to, bidOrder.value);
                    askOrder.value -= bidOrder.value * bidOrder.price;
                    removeBidOrder();
                    askOrder.price = tmpPrice;
                } else if(askOrder.value * askOrder.price < bidOrder.value * bidOrder.price) {
                    swap(askOrder.from, askOrder.to, askOrder.value, bidOrder.from, bidOrder.to, askOrder.value * askOrder.price);
                    bidOrder.value -= askOrder.value * askOrder.price;
                    removeAskOrder();
                } else {
                    swap(askOrder.from, askOrder.to, askOrder.value, bidOrder.from, bidOrder.to, bidOrder.value);
                    removeAskOrder();
                    removeBidOrder();
                }
            }
        }
    }

}