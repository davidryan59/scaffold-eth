import { StaticJsonRpcProvider, Web3Provider } from "@ethersproject/providers";
import { formatEther, parseEther } from "@ethersproject/units";
import WalletConnectProvider from "@walletconnect/web3-provider";
import { Alert, Button, Card, Col, List, Menu, Row } from "antd";
import "antd/dist/antd.css";
import { useUserAddress } from "eth-hooks";
import React, { useCallback, useEffect, useState } from "react";
import { BrowserRouter, Link, Route, Switch } from "react-router-dom";
import Web3Modal from "web3modal";
import "./App.css";
import { Account, Address, AddressInput, Contract, Faucet, GasGauge, Header, Ramp, ThemeSwitch } from "./components";
import { INFURA_ID, NETWORK, NETWORKS } from "./constants";
import { Transactor } from "./helpers";
import {
  useBalance,
  useContractLoader,
  useContractReader,
  useEventListener,
  useExchangePrice,
  useGasPrice,
  useOnBlock,
  useUserProvider,
} from "./hooks";


// 📡 What chain are your contracts deployed to?

const targetNetwork = NETWORKS.localhost;
const networkName = 'TESTNET';

// const targetNetwork = NETWORKS.goerli;
// const networkName = 'Goerli (test 4)';

// const targetNetwork = NETWORKS.mainnet;
// const networkName = 'Ethereum';


const RECENT_DISPLAY_COUNT = 12;

// 😬 Sorry for all the console logging
const DEBUG = true;
// const DEBUG = false;


// 🛰 providers
// attempt to connect to our own scaffold eth rpc and if that fails fall back to infura...
// Using StaticJsonRpcProvider as the chainId won't change see https://github.com/ethers-io/ethers.js/issues/901
const scaffoldEthProvider = new StaticJsonRpcProvider("https://rpc.scaffoldeth.io:48544");
const mainnetInfura = new StaticJsonRpcProvider("https://mainnet.infura.io/v3/" + INFURA_ID);
// ( ⚠️ Getting "failed to meet quorum" errors? Check your INFURA_I

// 🏠 Your local provider is usually pointed at your local blockchain
const localProviderUrl = targetNetwork.rpcUrl;
// as you deploy to other networks you can set REACT_APP_PROVIDER=https://dai.poa.network in packages/react-app/.env
const localProviderUrlFromEnv = process.env.REACT_APP_PROVIDER ? process.env.REACT_APP_PROVIDER : localProviderUrl;
if (DEBUG) console.log("🏠 Connecting to provider:", localProviderUrlFromEnv);
const localProvider = new StaticJsonRpcProvider(localProviderUrlFromEnv);

// 🔭 block explorer URL
const blockExplorer = targetNetwork.blockExplorer;

/*
  Web3 modal helps us "connect" external wallets:
*/
const web3Modal = new Web3Modal({
  // network: "mainnet", // optional
  cacheProvider: true, // optional
  providerOptions: {
    walletconnect: {
      package: WalletConnectProvider, // required
      options: {
        infuraId: INFURA_ID,
      },
    },
  },
});

function App() {
  const mainnetProvider = scaffoldEthProvider && scaffoldEthProvider._network ? scaffoldEthProvider : mainnetInfura;

  const logoutOfWeb3Modal = async () => {
     await web3Modal.clearCachedProvider();
     if (injectedProvider && injectedProvider.provider && typeof injectedProvider.provider.disconnect == "function") {
       await injectedProvider.provider.disconnect();
     }
     setTimeout(() => {
       window.location.reload();
     }, 1);
  };

  const [injectedProvider, setInjectedProvider] = useState();
  /* 💵 This hook will get the price of ETH from 🦄 Uniswap: */
  const price = useExchangePrice(targetNetwork, mainnetProvider);

  /* 🔥 This hook will get the price of Gas from ⛽️ EtherGasStation */
  const gasPrice = useGasPrice(targetNetwork, "fast");
  // Use your injected provider from 🦊 Metamask or if you don't have it then instantly generate a 🔥 burner wallet.
  const userProvider = useUserProvider(injectedProvider, localProvider);
  const address = useUserAddress(userProvider);

  // You can warn the user if you would like them to be on a specific network
  const localChainId = localProvider && localProvider._network && localProvider._network.chainId;
  const selectedChainId = userProvider && userProvider._network && userProvider._network.chainId;

  // For more hooks, check out 🔗eth-hooks at: https://www.npmjs.com/package/eth-hooks

  // The transactor wraps transactions and provides notificiations
  const tx = Transactor(userProvider, gasPrice);

  // Faucet Tx can be used to send funds from the faucet
  const faucetTx = Transactor(localProvider, gasPrice);

  // 🏗 scaffold-eth is full of handy hooks like this one to get your balance:
  const yourLocalBalance = useBalance(localProvider, address);

  // Load in your local 📝 contract and read a value from it:
  const readContracts = useContractLoader(localProvider);

  // If you want to make 🔐 write transactions to your contracts, use the userProvider:
  const writeContracts = useContractLoader(userProvider);

  // EXTERNAL CONTRACT EXAMPLE:
  //
  // If you want to bring in the mainnet DAI contract it would look like:
  const isSigner = injectedProvider && injectedProvider.getSigner && injectedProvider.getSigner()._isSigner;

  // If you want to call a function on a new block
  useOnBlock(mainnetProvider, () => {
    console.log(`⛓ A new mainnet block is here: ${mainnetProvider._lastBlockNumber}`);
  });

  // keep track of a variable from the contract in the local React state:
  const balance = useContractReader(readContracts, "MergeFractal", "balanceOf", [address]);
  console.log("🤗 balance:", balance);

  const isMintingAllowedCR = useContractReader(readContracts, "MergeFractal", "isMintingAllowed");
  const getPriceNextCR = useContractReader(readContracts, "MergeFractal", "getPriceNext");
  const mintCountCR = useContractReader(readContracts, "MergeFractal", "mintCount");
  const mintLimitCR = useContractReader(readContracts, "MergeFractal", "mintLimit");

  // 📟 Listen for broadcast events
  const transferEvents = useEventListener(readContracts, "MergeFractal", "Transfer", localProvider, 1);
  console.log("📟 Transfer events:", transferEvents);

  //
  // 🧠 This effect will update yourMergeFractals by polling when your balance changes
  //
  const yourBalance = balance && balance.toNumber && balance.toNumber();
  const [recentMergeFractals, setRecentMergeFractals] = useState();
  const [yourMergeFractals, setYourMergeFractals] = useState();

  // At the moment tokens do not update over time. If they did, would want to refresh this cache after say 1 day.
  const getTokenURI = async (contractAddress, tokenId) => {
    let result = "";
    const localStorageKey = `MRGFRC_${contractAddress.slice(2, 8)}_id${tokenId}_tokenURI`;
    const existingData = window.localStorage.getItem(localStorageKey);
    if (!existingData) {
      console.log(`Get Token URI: getting new data for ${localStorageKey}`);
      result = await readContracts.MergeFractal.tokenURI(tokenId);
      window.localStorage.setItem(localStorageKey, result);
    } else {
      console.log(`Get Token URI: found existing data for ${localStorageKey}`);
      result = existingData;
    }
    return result;
  }

  useEffect(() => {

    const updateRecentFractals = async () => {
      try {
        const contractAddress = await readContracts.MergeFractal.address;
        const mintCount = await readContracts.MergeFractal.mintCount();
        const endIdx = mintCount - 1; // the indices are 0, 1 ... mintCount-1
        const startIdx = Math.max(0, mintCount - RECENT_DISPLAY_COUNT);
        const recentFractals = [];
        for (let allTokensIdx = startIdx; allTokensIdx <= endIdx; allTokensIdx++) {
          try {
            console.log("Recent fractals: getting token index", allTokensIdx);
            const tokenId = await readContracts.MergeFractal.tokenByIndex(allTokensIdx);
            console.log("tokenId", tokenId);
            const tokenURI = await getTokenURI(contractAddress, tokenId);
            const jsonManifestString = atob(tokenURI.substring(29));
            try {
              const jsonManifest = JSON.parse(jsonManifestString);
              console.log("jsonManifest", jsonManifest);
              recentFractals.push({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
            } catch (e) {
              console.log(e);
            }
          } catch (e) {
            console.log(e);
          }
        }
        setRecentMergeFractals(recentFractals.reverse());
      } catch (e) {
        console.log(e);
      }
    };
    updateRecentFractals();

    const updateYourFractals = async () => {
      try {
        const contractAddress = await readContracts.MergeFractal.address;
        const yourFractals = [];
        for (let myTokenIdx = 0; myTokenIdx < balance; myTokenIdx++) {
          try {
            console.log("Your fractals: getting token index", myTokenIdx);
            const tokenId = await readContracts.MergeFractal.tokenOfOwnerByIndex(address, myTokenIdx);
            console.log("tokenId", tokenId);
            const tokenURI = await getTokenURI(contractAddress, tokenId);
            const jsonManifestString = atob(tokenURI.substring(29));
            try {
              const jsonManifest = JSON.parse(jsonManifestString);
              console.log("jsonManifest", jsonManifest);
              yourFractals.push({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
            } catch (e) {
              console.log(e);
            }
          } catch (e) {
            console.log(e);
          }
        }
        setYourMergeFractals(yourFractals.reverse());
      } catch (e) {
        console.log(e);
      }
    };
    updateYourFractals();

  }, [address, yourBalance]);

  let networkDisplay = "";
  if (localChainId && selectedChainId && localChainId !== selectedChainId) {
    const networkSelected = NETWORK(selectedChainId);
    const networkLocal = NETWORK(localChainId);
    if (selectedChainId === 1337 && localChainId === 31337) {
      networkDisplay = (
        <div style={{ zIndex: 2, position: "absolute", right: 0, top: 60, padding: 16 }}>
          <Alert
            message="⚠️ Wrong Network ID"
            description={
              <div>
                You have <b>chain id 1337</b> for localhost and you need to change it to <b>31337</b> to work with
                HardHat.
                <div>(MetaMask -&gt; Settings -&gt; Networks -&gt; Chain ID -&gt; 31337)</div>
              </div>
            }
            type="error"
            closable={false}
          />
        </div>
      );
    } else {
      networkDisplay = (
        <div style={{ zIndex: 2, position: "absolute", right: 0, top: 60, padding: 16 }}>
          <Alert
            message="⚠️ Wrong Network"
            description={
              <div>
                You have <b>{networkSelected && networkSelected.name}</b> selected and you need to be on{" "}
                <b>{networkLocal && networkLocal.name}</b>.
              </div>
            }
            type="error"
            closable={false}
          />
        </div>
      );
    }
  } else {
    networkDisplay = (
      <div style={{ zIndex: -1, position: "absolute", right: 154, top: 28, padding: 16, color: targetNetwork.color }}>
        {targetNetwork.name}
      </div>
    );
  }

  const loadWeb3Modal = useCallback(async () => {
    const provider = await web3Modal.connect();
    setInjectedProvider(new Web3Provider(provider));
  }, [setInjectedProvider]);

  useEffect(() => {
    if (web3Modal.cachedProvider) {
      loadWeb3Modal();
    }
  }, [loadWeb3Modal]);

  const [route, setRoute] = useState();
  useEffect(() => {
    setRoute(window.location.pathname);
  }, [setRoute]);

  let faucetHint = "";

  const [faucetClicked, setFaucetClicked] = useState(false);
  if (
    !faucetClicked &&
    localProvider &&
    localProvider._network &&
    localProvider._network.chainId === 31337 &&
    yourLocalBalance &&
    formatEther(yourLocalBalance) <= 0
  ) {
    faucetHint = (
      <div style={{ padding: 16 }}>
        <Button
          type="primary"
          onClick={() => {
            faucetTx({
              to: address,
              value: parseEther("10"),
            });
            setFaucetClicked(true);
          }}
        >
          💰 Grab funds from the faucet ⛽️
        </Button>
      </div>
    );
  }

  const [transferToAddresses, setTransferToAddresses] = useState({});

  const mintButton = () => (
    <Button type={"primary"} onClick={async ()=>{
      const isMintingAllowed = await readContracts.MergeFractal.isMintingAllowed();
      const priceRightNow = await readContracts.MergeFractal.getPriceNext();
      if (isMintingAllowed) {
        tx( writeContracts.MergeFractal.mintItem({ value: priceRightNow }) )
      }
    }}>
      {
        mintLimitCR === undefined
        ? 'Loading...'
        : isMintingAllowedCR
        ? (
            getPriceNextCR
            ? `${networkName} Merge Fractal #${1 + mintCountCR} of ${mintLimitCR} – MINT for ${formatEther(getPriceNextCR)} Ξ`
            : 'Awaiting price...'
          )
        : `All ${mintLimitCR} ${networkName} Merge Fractals have been minted already!`
      }
    </Button>
  );

  function MintButtonRow() {
    return (
      <div style={{ maxWidth: 820, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
        {isSigner ? mintButton() : (<div><Button type={"primary"} onClick={loadWeb3Modal}>CONNECT WALLET</Button></div>)}
      </div>
    );
  }

  const renderFractalListItem = item => {
    const id = item.id.toNumber();
    return (
      <List.Item key={"F" + id}>
        <Card
          title={
            <div>
              <span style={{ fontSize: 18, marginRight: 8 }}>{item.name}</span>
            </div>
          }
        >
          <a href={"https://opensea.io/assets/"+(readContracts && readContracts.MergeFractal && readContracts.MergeFractal.address)+"/"+item.id} target="_blank">
          <img src={item.image} style={{background: 'rgba(128,128,128,0.1)'}}/>
          </a>
          <div>{item.description}</div>
          <div>{item.attributes.reduce((acc, obj, idx) =>
            acc + obj.trait_type + ': ' + obj.value + ((idx === item.attributes.length - 1) ? '' : ', '),
            ''
          )}</div>
        </Card>

        <div>
          owner:{" "}
          <Address
            address={item.owner}
            ensProvider={mainnetProvider}
            blockExplorer={blockExplorer}
            fontSize={16}
          />
          <AddressInput
            ensProvider={mainnetProvider}
            placeholder="transfer to address"
            value={transferToAddresses[id]}
            onChange={newValue => {
              const update = {};
              update[id] = newValue;
              setTransferToAddresses({ ...transferToAddresses, ...update });
            }}
          />
          <Button
            onClick={() => {
              console.log("writeContracts", writeContracts);
              tx(writeContracts.MergeFractal.transferFrom(address, transferToAddresses[id], id));
            }}
          >
            Transfer
          </Button>
        </div>
      </List.Item>
    );
  };

  function FractalList({maxCount, dataSource}) {
    const filteredDataSource = dataSource ? dataSource.slice(0, maxCount || dataSource.length) : [];
    return (
      <div style={{ width: 820, margin: "auto", paddingBottom: 256 }}>
        <List
          bordered
          dataSource={filteredDataSource}
          renderItem={renderFractalListItem}
        />
      </div>
    );
  }

  return (
    <div className="App">
      {/* ✏️ Edit the header and change the title to your project name */}
      <Header networkName={networkName} />
      {networkDisplay}
      <MintButtonRow />
      <BrowserRouter>
        <Menu style={{ textAlign: "center" }} selectedKeys={[route]} mode="horizontal">
          <Menu.Item key="/">
            <Link
              onClick={() => {
                setRoute("/");
              }}
              to="/"
            >
              Home
            </Link>
          </Menu.Item>
          <Menu.Item key="/recent">
            <Link
              onClick={() => {
                setRoute("/recent");
              }}
              to="/recent"
            >
              Recent mints
            </Link>
          </Menu.Item>
          <Menu.Item key="/yourfractals">
            <Link
              onClick={() => {
                setRoute("/yourfractals");
              }}
              to="/yourfractals"
            >
              Your mints
            </Link>
          </Menu.Item>
          <Menu.Item key="/rarity">
            <Link
              onClick={() => {
                setRoute("/rarity");
              }}
              to="/rarity"
            >
              Rarity
            </Link>
          </Menu.Item>
          <Menu.Item key="/about">
            <Link
              onClick={() => {
                setRoute("/about");
              }}
              to="/about"
            >
              About
            </Link>
          </Menu.Item>
        </Menu>

        <Switch>
          <Route exact path="/">
            <p></p>
            <div>
              <p><b>Welcome to {networkName} Merge Fractal NFTs!</b></p>
              <p>To celebrate the Ethereum Merge in September 2022, these Merge Fractals are 5875 unique pieces of fully on-chain digital generative art.<br />The animated SVG images are generated entirely within the smart contract, without using external data sources such as IPFS.</p>
              <p>All proceeds of NFT sales go to the Protocol Guild to support Ethereum core development.<br />NFT attributes are randomly generated, some are a lot <a href="/rarity">rarer</a> than others.</p>
              <p>Latest mint:</p>
            </div>
            <FractalList maxCount={1} dataSource={recentMergeFractals} />
          </Route>
          <Route exact path="/recent">
            <p></p>
            <FractalList dataSource={recentMergeFractals} />
          </Route>
          <Route exact path="/yourfractals">
            <p></p>
            <FractalList dataSource={yourMergeFractals} />
          </Route>
          <Route exact path="/rarity">
            <p></p>
            <div>
              <p><b>Rarities for {networkName} Merge Fractal NFTs</b></p>
              <ul>
                <li>Developer Name: there are 120 names, each is approximately equally likely.</li>
                <li>Team depends on the dev. Teams are rarer if they have fewer devs.</li>
                <li>Developers and Teams were obtained from <a href="https://protocol-guild.readthedocs.io/en/latest/9-membership.html">this list</a> in Aug 2022.</li>
                <li>Subtitles: some are common, and a few are unusual.</li>
                <li>Style: Solid and Freestyle are common. Spinner is 8.3%, Reflective is 4.1%.</li>
                <li>Dropouts: probability of 0, 1, 2, 3, 4 dropouts is 31%, 42%, 21%, 4.6%, 0.3%.</li>
                <li>Twists: between 0 and 6 twists, 0 is the rarest.</li>
                <li>Duration: between 3 and 48 seconds – middle values (24s, 27s) common, extreme values rare</li>
                <li>Monochrome: there is 6.2% chance of monochrome, so it is quite rare.</li>  
                <li>Colours: all colours are equally likely.</li>  
              </ul>
              <p>Happy minting!</p>
            </div>
          </Route>
          <Route exact path="/about">
            <p></p>
            <div>
              <p><b>About {networkName} Merge Fractal NFTs</b></p>
              <p>Where does the money go? 100% to Protocol Guild to fund core devs!<br />Here is their <a href={"https://etherscan.io/address/0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9"} target="_blank">Ethereum address</a> on Etherscan, mint and see number go up.</p>
              <p>Ethereum mainnet contract for NFT: Awaiting Deployment</p>
              <p>Source code for NFT: <a href={"https://github.com/davidryan59/scaffold-eth/tree/merge-fractal"} target="_blank">GitHub repository for Merge Fractal</a></p>
              <p style={{color: 'rgba(128,128,128,0.3)'}}>-----------------------------------------------------------------</p>
              <p>NFT author: David Ryan</p>
              <p>Twitter: <a href={"https://twitter.com/davidryan59"} target="_blank">@davidryan59</a></p>
              <p>Artist page on Nifty Ink: <a href={"https://nifty.ink/artist/0xbfac61d1e22efa9d37fc3ff36b9dff9655131f52"} target="_blank">niftymaestro.eth</a></p>
              <p style={{color: 'rgba(128,128,128,0.3)'}}>-----------------------------------------------------------------</p>
              <p>Shout out to Stateful Works who continually support the Protocol Guild and Ethereum core development,<br/>and to Austin Griffith and the Buidl Guidl for the excellent Scaffold Eth framework that this project is built on.</p>
            </div>
          </Route>
        </Switch>
      </BrowserRouter>

      <ThemeSwitch />

      {/* 👨‍💼 Your account is in the top right with a wallet at connect options */}
      <div style={{ position: "fixed", textAlign: "right", right: 0, top: 0, padding: 10 }}>
        <Account
          address={address}
          localProvider={localProvider}
          userProvider={userProvider}
          mainnetProvider={mainnetProvider}
          price={price}
          web3Modal={web3Modal}
          loadWeb3Modal={loadWeb3Modal}
          logoutOfWeb3Modal={logoutOfWeb3Modal}
          blockExplorer={blockExplorer}
          isSigner={isSigner}
        />
        {faucetHint}
      </div>
    </div>
  );
}

/* eslint-disable */
window.ethereum &&
  window.ethereum.on("chainChanged", chainId => {
    web3Modal.cachedProvider &&
      setTimeout(() => {
        window.location.reload();
      }, 1);
  });

window.ethereum &&
  window.ethereum.on("accountsChanged", accounts => {
    web3Modal.cachedProvider &&
      setTimeout(() => {
        window.location.reload();
      }, 1);
  });
/* eslint-enable */

export default App;
