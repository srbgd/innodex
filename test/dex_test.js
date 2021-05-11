const DEXContract = artifacts.require("DEX");

contract("DEX", (accounts) => {

    let DEX;
    let token1adr = accounts[1];
    let token2adr = accounts[2];
    const init_supply = "1000000000000000000000000";

    beforeEach(async () => {
        DEX = await DEXContract.new();
        assert(DEX, "contract failed to deploy");
    });

    describe("initialization", () => {
        it("check tokens names", async () => {
            let token1 = await DEX.getToken1();
            assert.equal(token1[0], "TK1", "Token1 name is incorrect");
            let token2 = await DEX.getToken2();
            assert.equal(token2[0], "TK2", "Token2 name is incorrect");
        });
        it("check tokens initial supply", async () => {
            let token1 = await DEX.getToken1();
            assert.equal(token1[1].toString(), init_supply, "Token1 initial supply is incorrect");
            let token2 = await DEX.getToken2();
            assert.equal(token2[1].toString(), init_supply, "Token2 initial supply is incorrect");
        });
        it("check accounts balance", async () => {
            let token1 = await DEX.getToken1();
            let token2 = await DEX.getToken2();
            let balance1 = await DEX.getBalanceToken1(token1[2]);
            assert.equal(balance1.toString(), init_supply, "Token1 balance is incorrect");
            let balance2 = await DEX.getBalanceToken2(token2[2]);
            assert.equal(balance2.toString(), init_supply, "Token2 balance is incorrect");
            let balance3 = await DEX.getBalanceToken1(token1adr);
            assert.equal(balance3.toString(), "0", "Token1 address 2 balance is incorrect");
            let balance4 = await DEX.getBalanceToken1(token2adr);
            assert.equal(balance4.toString(), "0", "Token2 address 2 balance is incorrect");
        });
    });

    describe("transfer", () => {
        it("check correct swap", async () => {
            let token1 = await DEX.getToken1();
            let token2 = await DEX.getToken2();
            let success;
            try{
                await DEX.swap(token1[2], token2adr, 1000, token2[2], token1adr, 1000);
                success = true;
            }catch(err){
                success = false;
            }
            assert.equal(success, true, "Tokens haven't been swapped");
        });
        it("check incorrect swap", async () => {
            let token1 = await DEX.getToken1();
            let token2 = await DEX.getToken2();
            let success;
            try{
                await DEX.swap(token1[2], token2adr, 0, token2[2], token1adr, 0);
                success = true;
            }catch(err){
                success = false;
            }
            assert.equal(success, false, "Tokens shouldn't have been swapped");
        });
        it("check transfer counts", async () => {
            let counts1 = await DEX.getTransferCounts();
            assert.equal(counts1[0].toString() + counts1[1].toString(), "00", "initialy there should be no transfers");
            let token1 = await DEX.getToken1();
            let token2 = await DEX.getToken2();
            await DEX.swap(token1[2], token2adr, 1000, token2[2], token1adr, 1000);
            let counts2 = await DEX.getTransferCounts();
            assert.equal(counts2[0].toString() + counts2[1].toString(), "11", "there should be 1 transfer after a swap");
        });
    });

    describe("orders", () => {
        it("check ask orders count", async () => {
            let counts1 = await DEX.askOrdersCount();
            assert.equal(counts1.toString(), "0", "initialy there should be no ask orders");
            await DEX.makeAskOrder(token2adr, 10, 100);
            let counts2 = await DEX.askOrdersCount();
            assert.equal(counts2.toString(), "1", "there should be 1 ask order after order creation");
        });
        it("check bid orders count", async () => {
            let counts1 = await DEX.bidOrdersCount();
            assert.equal(counts1.toString(), "0", "initialy there should be no bid orders");
            await DEX.makeBidOrder(token2adr, 10, 100);
            let counts2 = await DEX.bidOrdersCount();
            assert.equal(counts2.toString(), "1", "there should be 1 bid order after order creation");
        });
        it("check cancel ask order", async () => {
            let counts1 = await DEX.askOrdersCount();
            assert.equal(counts1.toString(), "0", "initialy there should be no ask orders");
            await DEX.makeAskOrder(token2adr, 10, 100);
            await DEX.cancelAskOrder();
            let counts2 = await DEX.askOrdersCount();
            assert.equal(counts2.toString(), "0", "there should be no ask orders after order canceling");

        });
        it("check cancel bid order", async () => {
            let counts1 = await DEX.bidOrdersCount();
            assert.equal(counts1.toString(), "0", "initialy there should be no bid orders");
            await DEX.makeBidOrder(token2adr, 10, 100);
            await DEX.cancelBidOrder();
            let counts2 = await DEX.bidOrdersCount();
            assert.equal(counts2.toString(), "0", "there should be no bid orders after order canceling");
        });
    });

    describe("matching", () => {
        it("check match orders correct", async () => {
            let counts1 = await DEX.OrderCounts();
            assert.equal(counts1[0].toString() + counts1[1].toString(), "00", "initially there should be no orders");
            await DEX.makeAskOrder(token2adr, 1, 100);
            await DEX.makeBidOrder(token1adr, 1, 100);
            let counts2 = await DEX.OrderCounts();
            assert.equal(counts2[0].toString() + counts2[1].toString(), "00", "there should be no orders after a match");
        });
        it("check match orders incorrect", async () => {
            let counts1 = await DEX.OrderCounts();
            assert.equal(counts1[0].toString() + counts1[1].toString(), "00", "initially there should be no orders");
            await DEX.makeAskOrder(token2adr, 1, 100);
            await DEX.makeBidOrder(token1adr, 2, 100);
            let counts2 = await DEX.OrderCounts();
            assert.equal(counts2[0].toString() + counts2[1].toString(), "11", "there should be no matching");
        });
    });

});
