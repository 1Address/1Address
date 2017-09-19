// //import expectThrow from 'zeppelin-solidity/test/helpers/expectThrow';
// import expectThrow from './Helpers/expectThrow';

// var Registrator = artifacts.require("./Registrator.sol");
// var Business = artifacts.require("./Business.sol");
// var Search = artifacts.require("./Search.sol");
// var CoinSale = artifacts.require("./CoinSale.sol");
// var Offer = artifacts.require("./Offer.sol");

// contract('Search', function([_, registratorAccount, businessAccount, searchAccount]) {

//     it("should create Search", async function() {

//         var registrator = await Registrator.new({from: registratorAccount});
//         await registrator.createBusiness({from: businessAccount});
//         const businessesCount = await registrator.businessesCount.call();
//         const business = Business.at(await registrator.businesses.call(businessesCount - 1));

//         await registrator.createCoinSale({from: registratorAccount});
//         const coinSalesCount = await registrator.businessesCount.call();
//         const coinSale = CoinSale.at(await registrator.coinSales.call(coinSalesCount - 1));
//         await business.addCoinSale(coinSale, {from: registratorAccount});
//         await coinSale.setBusiness(business, {from: registratorAccount});

//         await registrator.createSearch({from: searchAccount});
//         const searchesCount = await registrator.searchesCount.call();
//         const search = Search.at(await registrator.searches.call(searchesCount - 1));

//         //await business.createOffer(coinSale.address, {from: businessAccount});
//         //const offersCount = await business.offersCount.call();
//         //const offer = Offer.at(await business.offers.call(offersCount - 1));


//     })

// })