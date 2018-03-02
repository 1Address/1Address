// @flow
'use strict'

const BigNumber = web3.BigNumber;
const expect = require('chai').expect;
const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(web3.BigNumber))
    .should();

import ether from './helpers/ether';
import {advanceBlock} from './helpers/advanceToBlock';
import {increaseTimeTo, duration} from './helpers/increaseTime';
import latestTime from './helpers/latestTime';
import EVMRevert from './helpers/EVMRevert';

var Upgradable = artifacts.require("./impl/UpgradableImpl.sol");

contract('Upgradable', async function([_, registratorAccount, customerAccount, customerWallet1, customerWallet2, customerWallet3]) {

    it('should work fine', async function() {
        let oldContract = await Upgradable.new(0);
        {
            let state = await oldContract.upgradableState.call();
            state[0].should.be.false;
            state[1].should.be.bignumber.equal(0);
            state[2].should.be.bignumber.equal(0);
        }

        await oldContract.foo().should.be.fulfilled;

        let newContract = await Upgradable.new(oldContract.address);
        {
            let oldState = await oldContract.upgradableState.call();
            oldState[0].should.be.true;
            oldState[1].should.be.bignumber.equal(0);
            oldState[2].should.be.bignumber.equal(newContract.address);

            let newState = await newContract.upgradableState.call();
            newState[0].should.be.true;
            newState[1].should.be.bignumber.equal(oldContract.address);
            newState[2].should.be.bignumber.equal(0);
        }

        await oldContract.foo().should.be.rejectedWith(EVMRevert);
        await newContract.foo().should.be.rejectedWith(EVMRevert);

        await newContract.endUpgrade();
        {
            let oldState = await oldContract.upgradableState.call();
            oldState[0].should.be.false;
            oldState[1].should.be.bignumber.equal(0);
            oldState[2].should.be.bignumber.equal(newContract.address);

            let newState = await newContract.upgradableState.call();
            newState[0].should.be.false;
            newState[1].should.be.bignumber.equal(oldContract.address);
            newState[2].should.be.bignumber.equal(0);
        }

        await oldContract.foo().should.be.rejectedWith(EVMRevert);
        await newContract.foo().should.be.fulfilled;

        let lastContract = await Upgradable.new(newContract.address);
        {
            let oldState = await oldContract.upgradableState.call();
            oldState[0].should.be.false;
            oldState[1].should.be.bignumber.equal(0);
            oldState[2].should.be.bignumber.equal(newContract.address);

            let newState = await newContract.upgradableState.call();
            newState[0].should.be.true;
            newState[1].should.be.bignumber.equal(oldContract.address);
            newState[2].should.be.bignumber.equal(lastContract.address);

            let lastState = await lastContract.upgradableState.call();
            lastState[0].should.be.true;
            lastState[1].should.be.bignumber.equal(newContract.address);
            lastState[2].should.be.bignumber.equal(0);
        }

        await oldContract.foo().should.be.rejectedWith(EVMRevert);
        await newContract.foo().should.be.rejectedWith(EVMRevert);
        await lastContract.foo().should.be.rejectedWith(EVMRevert);

        await lastContract.endUpgrade();
        {
            let oldState = await oldContract.upgradableState.call();
            oldState[0].should.be.false;
            oldState[1].should.be.bignumber.equal(0);
            oldState[2].should.be.bignumber.equal(newContract.address);

            let newState = await newContract.upgradableState.call();
            newState[0].should.be.false;
            newState[1].should.be.bignumber.equal(oldContract.address);
            newState[2].should.be.bignumber.equal(lastContract.address);

            let lastState = await lastContract.upgradableState.call();
            lastState[0].should.be.false;
            lastState[1].should.be.bignumber.equal(newContract.address);
            lastState[2].should.be.bignumber.equal(0);
        }

        await oldContract.foo().should.be.rejectedWith(EVMRevert);
        await newContract.foo().should.be.rejectedWith(EVMRevert);
        await lastContract.foo().should.be.fulfilled;
    })

})