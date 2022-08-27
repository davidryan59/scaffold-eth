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

// const targetNetwork = NETWORKS.localhost;
// const networkName = 'TESTNET';

const targetNetwork = NETWORKS.goerli;
const networkName = 'Goerli (test 4)';

// const targetNetwork = NETWORKS.mainnet;
// const networkName = 'Ethereum';


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
    const updateYourMergeFractals = async () => {
      const mergeFractalUpdate = [];
      for (let tokenIndex = 0; tokenIndex < balance; tokenIndex++) {
        try {
          console.log("Getting token index", tokenIndex);
          const contractAddress = await readContracts.MergeFractal.address;
          const tokenId = await readContracts.MergeFractal.tokenOfOwnerByIndex(address, tokenIndex);
          console.log("tokenId", tokenId);
          const tokenURI = await getTokenURI(contractAddress, tokenId);
          const jsonManifestString = atob(tokenURI.substring(29));
          try {
            const jsonManifest = JSON.parse(jsonManifestString);
            console.log("jsonManifest", jsonManifest);
            mergeFractalUpdate.push({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
          } catch (e) {
            console.log(e);
          }

        } catch (e) {
          console.log(e);
        }
      }
      setYourMergeFractals(mergeFractalUpdate.reverse());
    };
    updateYourMergeFractals();
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
  const faucetAvailable = localProvider && localProvider.connection && targetNetwork.name === "localhost";

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

  return (
    <div className="App">
      {/* ✏️ Edit the header and change the title to your project name */}
      <Header networkName={networkName} />
      {networkDisplay}

      <BrowserRouter>
        <Menu style={{ textAlign: "center" }} selectedKeys={[route]} mode="horizontal">
          <Menu.Item key="/">
            <Link
              onClick={() => {
                setRoute("/");
              }}
              to="/"
            >
              Your {networkName} Merge Fractals
            </Link>
          </Menu.Item>
          <Menu.Item key="/debug">
            <Link
              onClick={() => {
                setRoute("/debug");
              }}
              to="/debug"
            >
              Smart Contract
            </Link>
          </Menu.Item>
        </Menu>

        <Switch>
          <Route exact path="/">
            {/*
                🎛 this scaffolding is full of commonly used components
                this <Contract/> component will automatically parse your ABI
                and give you a form to interact with it locally
            */}

            <div style={{ maxWidth: 820, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
              {isSigner ? (
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
              ) : (
                <div>
                  <Button type={"primary"} onClick={loadWeb3Modal}>CONNECT WALLET</Button>
                </div>
              )}

            </div>

            <div style={{ width: 820, margin: "auto", paddingBottom: 256 }}>
              <List
                bordered
                dataSource={yourMergeFractals}
                renderItem={item => {
                  const id = item.id.toNumber();
                  // console.log("IMAGE", item.image);
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
                        <img src={item.image} style={{background: '#292929'}}/>
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
                }}
              />
            </div>
            {(targetNetwork !== NETWORKS.localhost) ? '' : (
              <div style={{ maxWidth: 820, margin: "auto", marginTop: 32, paddingBottom: 256 }}>
                🛠 built with <a href="https://github.com/austintgriffith/scaffold-eth" target="_blank">🏗 scaffold-eth</a>
                🍴 <a href="https://github.com/austintgriffith/scaffold-eth" target="_blank">Fork this repo</a> and build a cool SVG NFT!
              </div>
            )}
          </Route>
          <Route path="/debug">

            <div style={{padding:32}}>
              <Address value={readContracts && readContracts.MergeFractal && readContracts.MergeFractal.address} />
            </div>

            <Contract
              name="MergeFractal"
              signer={userProvider.getSigner()}
              provider={localProvider}
              address={address}
              blockExplorer={blockExplorer}
            />
            <Contract
              name="FractalStrings"
              signer={userProvider.getSigner()}
              provider={localProvider}
              address={address}
              blockExplorer={blockExplorer}
            />
            <Contract
              name="SharedFnsAndData"
              signer={userProvider.getSigner()}
              provider={localProvider}
              address={address}
              blockExplorer={blockExplorer}
            />
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

      {(targetNetwork !== NETWORKS.localhost) ? '' : (
        <div style={{ position: "fixed", textAlign: "left", left: 0, bottom: 20, padding: 10 }}>
          {/* 🗺 Extra UI like gas price, eth price, faucet, and support: */}
          <Row align="middle" gutter={[4, 4]}>
            <Col span={8}>
              <Ramp price={price} address={address} networks={NETWORKS} />
            </Col>
  
            <Col span={8} style={{ textAlign: "center", opacity: 0.8 }}>
              <GasGauge gasPrice={gasPrice} />
            </Col>
            <Col span={8} style={{ textAlign: "center", opacity: 1 }}>
              <Button
                onClick={() => {
                  window.open("https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA");
                }}
                size="large"
                shape="round"
              >
                <span style={{ marginRight: 8 }} role="img" aria-label="support">
                  💬
                </span>
                Support
              </Button>
            </Col>
          </Row>
  
          <Row align="middle" gutter={[4, 4]}>
            <Col span={24}>
              {
                /*  if the local provider has a signer, let's show the faucet:  */
                faucetAvailable ? (
                  <Faucet localProvider={localProvider} price={price} ensProvider={mainnetProvider} />
                ) : (
                  ""
                )
              }
            </Col>
          </Row>
        </div>
      )}
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
