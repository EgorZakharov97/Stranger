const Stranger = artifacts.require("Stranger");
const Marketplace = artifacts.require("Marketplace");
const expectThrow = require('./helpers/expectThrow');
const defaultPrice = 100000000000;

contract("Marketplace", accounts => {

    let stranger;
    let marketplace;

    let commission;
    let finalPrice;

    before(async () => {
        stranger = await Stranger.deployed();
        marketplace = await Marketplace.deployed();
        
        const commissionPercentage = await marketplace.getComissionPercentage();
        commission = (commissionPercentage * defaultPrice) / 100;
        finalPrice = defaultPrice + commission;
    });

    describe("Creates Listing", () => {

        beforeEach(async () => {
            // Mint a token
            await stranger.mint(accounts[0], "UngaBunga", false);
            // Approve Marketplace
            await stranger.approve(marketplace.address, 0, {from: accounts[0]});
        });
    
        afterEach(async () => {
            stranger = await Stranger.new();
            marketplace = await Marketplace.new();
        });

        it("Creates a listing", async () => {
            //Create listing
            await marketplace.createListing(stranger.address, 0, defaultPrice);
        });
    
        it("Does not create listing if not approved", async () => {
            // Approve to another user instead
            await stranger.approve(accounts[2], 0, {from: accounts[0]});
            //Create listing
            expectThrow(marketplace.createListing(stranger.address, 0, defaultPrice));
        });

    });

    describe("Performs a sale", () => {

        beforeEach(async () => {
            // Mint a token
            await stranger.mint(accounts[0], "UngaBunga", false);

            // Approve Marketplace
            await stranger.approve(marketplace.address, 0, {from: accounts[0]});

            // Create listing
            await marketplace.createListing(stranger.address, 0, defaultPrice, {from: accounts[0]});
        });
    
        afterEach(async () => {
            stranger = await Stranger.new();
            marketplace = await Marketplace.new();
        });

        it("Performs a sale", async () => {
            // Perform sale
            await marketplace.executeSale(0, {from: accounts[1], value: finalPrice});
        });
    
        it("Does not perform sale if token is no longer approved", async () => {
            // Disapprove Marketplace
            await stranger.approve(accounts[9], 0, {from: accounts[0]});
    
            // Perform sale
            expectThrow(marketplace.executeSale(0, {from: accounts[1], value: finalPrice}));
        });
    
        it("Does not perform sale if listing is cancelled", async () => {
            // Cancell the listing
            await marketplace.cancelListing(0);

            // Perform sale
            expectThrow(marketplace.executeSale(0, {from: accounts[1], value: finalPrice}));
        });
    
        it("Does not perform sale if listing is not active", async () => {
            // Deactivate the listing
            await marketplace.pauseListing(0);

            // Perform sale
            expectThrow(marketplace.executeSale(0, {from: accounts[1], value: finalPrice}));
        });
    
        it("Can deactivate, reactivate and sell item", async () => {
            // Deactivate the listing
            await marketplace.pauseListing(0);

            // Reactivate the listing
            await marketplace.unpauseListing(0);

            // Perform sale
            await marketplace.executeSale(0, {from: accounts[1], value: finalPrice});
        });

        it("Does not perform sale if the value is less than the price", async () => {
            // Approve Marketplace
            await stranger.approve(marketplace.address, 0, {from: accounts[0]});
    
            // Create listing
            await marketplace.createListing(stranger.address, 0, defaultPrice, {from: accounts[0]});
    
            // Perform sale
            expectThrow(marketplace.executeSale(0, {from: accounts[1], value: finalPrice-10000}));
        });
    });

    describe("User can manipulate listings", () => {

        beforeEach(async () => {
            // Mint a token
            await stranger.mint(accounts[0], "UngaBunga", false);

            // Approve Marketplace
            await stranger.approve(marketplace.address, 0, {from: accounts[0]});

            // Create listing
            await marketplace.createListing(stranger.address, 0, defaultPrice, {from: accounts[0]});
        });
    
        afterEach(async () => {
            stranger = await Stranger.new();
            marketplace = await Marketplace.new();
        });

        it("User can deactivate listing", async () => {
            // Deactivate listing
            await marketplace.pauseListing(0);

            let listing = await marketplace.getListing(0);
            expect(listing.active).equal(false);

            // Reactivate listing
            await marketplace.unpauseListing(0);

            listing = await marketplace.getListing(0);
            expect(listing.active).equal(true);
        });

        it("User cannot deactivate listing which they does not own", async () => {
            // Fail to deactivate listing
            marketplace.pauseListing(0), {from: accounts[2]}

            // Deactivate listing
            await marketplace.pauseListing(0);

            // Fail to reactivate listing
            marketplace.unpauseListing(0), {from: accounts[2]}
        });

        it("User can cancel listing", async () => {
            // Cancel listing
            await marketplace.cancelListing(0);

            let listing = await marketplace.getListing(0);
            expect(listing.cancelled).equal(true);
            expect(listing.nftContract.toString()).equal('0x0000000000000000000000000000000000000000');
            expect(listing.tokenId).equal('0');
        });

        it("User cannot cancel listing which not own", async () => {
            // Cancel listing
            expectThrow(marketplace.cancelListing(0, {from: accounts[1]}))
        });
    });

    describe("Returns data", () => {

        before(async () => {
            // Mint a tokens
            await stranger.mint(accounts[1], "UngaBunga1", false);
            await stranger.mint(accounts[1], "UngaBunga2", false);
            await stranger.mint(accounts[1], "UngaBunga3", false);

            await stranger.mint(accounts[2], "UngaBunga4", false);
            await stranger.mint(accounts[2], "UngaBunga5", false);
            await stranger.mint(accounts[2], "UngaBunga6", false);

            await stranger.mint(accounts[3], "UngaBunga7", false);
            await stranger.mint(accounts[3], "UngaBunga8", false);
            await stranger.mint(accounts[3], "UngaBunga9", false);

            // Approve tokens
            await stranger.setApprovalForAll(marketplace.address, true, {from: accounts[1]});
            await stranger.setApprovalForAll(marketplace.address, true, {from: accounts[2]});
            await stranger.setApprovalForAll(marketplace.address, true, {from: accounts[3]});

            // Create listings
            await marketplace.createListing(stranger.address, 0, defaultPrice, {from: accounts[1]});
            await marketplace.createListing(stranger.address, 1, defaultPrice, {from: accounts[1]});
            await marketplace.createListing(stranger.address, 2, defaultPrice, {from: accounts[1]});

            await marketplace.createListing(stranger.address, 3, defaultPrice, {from: accounts[2]});
            await marketplace.createListing(stranger.address, 4, defaultPrice, {from: accounts[2]});
            await marketplace.createListing(stranger.address, 5, defaultPrice, {from: accounts[2]});

            await marketplace.createListing(stranger.address, 6, defaultPrice, {from: accounts[3]});
            await marketplace.createListing(stranger.address, 7, defaultPrice, {from: accounts[3]});
            await marketplace.createListing(stranger.address, 8, defaultPrice, {from: accounts[3]});

            // Make a few transactions
            // user 1 buys two listings of user 2
            await marketplace.executeSale(3, {from: accounts[1], value: finalPrice});
            await marketplace.executeSale(4, {from: accounts[1], value: finalPrice});

            // user 2 buys two listings of user 3
            await marketplace.executeSale(6, {from: accounts[2], value: finalPrice});
            await marketplace.executeSale(7, {from: accounts[2], value: finalPrice});

            // user 3 buys two listings of user 1
            await marketplace.executeSale(0, {from: accounts[3], value: finalPrice});
            await marketplace.executeSale(1, {from: accounts[3], value: finalPrice});

            // Listings 3, 5, 8 are unsold
        });

        it("Returns a list of unsold items", async () => {
            const listings = await marketplace.getUnsoldListings();

            expect(listings.length).equal(3);
        });
    
        it("Returns a list of listings owned by me", async () => {
            const listings = await marketplace.getMyListings({from: accounts[1]});

            expect(listings.length).equal(3);
            expect(listings[0].seller).equal(accounts[1]);
            expect(listings[1].seller).equal(accounts[1]);
            expect(listings[2].seller).equal(accounts[1]);
        });
    
        it("Returns a list of listings owned by other user", async () => {
            const listings = await marketplace.getUserListings(accounts[2], {from: accounts[1]});

            expect(listings.length).equal(3);
            expect(listings[0].seller).equal(accounts[2]);
            expect(listings[1].seller).equal(accounts[2]);
            expect(listings[2].seller).equal(accounts[2]);
        });
    
        it("Returns a list of sold items", async () => {
            const listings = await marketplace.getExecutedListings();

            expect(listings.length).equal(6);
        });
    
        it("Returns the number of sold items", async () => {
            const number = (await marketplace.countSold()).toNumber();

            expect(number).equal(6);
        });

        it("Returns the number of items", async () => {
            const number = (await marketplace.countListings()).toNumber();

            expect(number).equal(9);
        });
    });

});