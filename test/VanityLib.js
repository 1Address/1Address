//import expectThrow from 'zeppelin-solidity/test/helpers/expectThrow';
import expectThrow from './Helpers/expectThrow';

var VanityLib = artifacts.require("./VanityLib.sol");

contract('VanityLib', function([_, registratorAccount, customerAccount, customerWallet1, customerWallet2, customerWallet3]) {

    it("should test lengthOfCommonPrefix", async function() {

        const vanityLib = await VanityLib.new();

        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("456")), 0);
        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("4567")), 0);
        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("1234"), web3.fromAscii("456")), 0);

        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("156")), 1);
        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("1567")), 1);
        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("1234"), web3.fromAscii("156")), 1);

        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("126")), 2);
        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("1267")), 2);
        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("1234"), web3.fromAscii("126")), 2);

        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("123")), 3);
        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("1237")), 3);
        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("1234"), web3.fromAscii("123")), 3);

        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("")), 0);
        assert.equal(await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii(""), web3.fromAscii("1237")), 0);

    })

    it("should test toBase58Checked", async function() {

        const vanityLib = await VanityLib.new();

        assert.equal(web3.toAscii(await vanityLib.toBase58Checked.call("0x00010966776006953D5567439E5E39F86A0D273BEED61967F6", web3.fromAscii("1"))), "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv");

    })

    it("should test createBtcAddress", async function() {

        const vanityLib = await VanityLib.new();

        const xPoint = "0x50863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352";
        const yPoint = "0x2CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6";
        assert.equal(web3.toAscii(await vanityLib.createBtcAddress.call(xPoint, yPoint)), "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv", "");

    })

})